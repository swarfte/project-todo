/// <reference path="../pb_data/types.d.ts" />
//
// Custom REST API for the "steps" resource.
//
// Ports the step operations from the Flutter client (lib/api.dart ->
// APIService) to the server. Steps are owned transitively: a step belongs to
// the caller iff step.taskId -> tasks.projectId -> projects.userId == caller.
// Every handler re-checks that chain by hand since collection API rules
// don't apply to server-side $app calls.
//
// Steps form a linked list via previousStepId. insert/delete therefore splice
// the chain rather than just add/remove a row, and both run in a transaction
// (see insertStep / deleteStep) so a half-finished splice can never orphan a
// successor — the main data-integrity win of moving this logic off the client.

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

function authId(e) {
    return e.auth.id;
}

function exportRecord(record) {
    return record.publicExport();
}

// Resolve the caller's task ids (tasks whose project the caller owns). A step
// is owned iff its taskId is in this set.
function ownedTaskIds(app, uid) {
    const ownedProjects = app
        .findRecordsByFilter("projects", "userId = {:uid}", "", 0, 0, { uid: uid })
        .map((p) => p.id);
    if (ownedProjects.length === 0) return new Set();

    // Filter tasks down to those under the caller's projects. There's no
    // cross-collection filter, so fetch all tasks and keep the owned ones.
    const tasks = app.findRecordsByFilter("tasks", "1 = 1", "", 0, 0);
    const projectSet = new Set(ownedProjects);
    return new Set(tasks.filter((t) => projectSet.has(t.getString("projectId"))).map((t) => t.id));
}

// Fetch a task by id and confirm the caller owns it via its project. 404 on a
// miss/mismatch.
function getOwnedTaskOr404(app, uid, taskId) {
    let task;
    try {
        task = app.findRecordById("tasks", taskId);
    } catch (_) {
        throw new NotFoundError("task not found");
    }
    let project;
    try {
        project = app.findRecordById("projects", task.getString("projectId"));
    } catch (_) {
        throw new NotFoundError("task not found");
    }
    if (project.getString("userId") !== uid) {
        throw new NotFoundError("task not found");
    }
    return task;
}

// Fetch a step by id and confirm the caller owns it via task -> project.
function getOwnedStepOr404(app, uid, stepId) {
    let step;
    try {
        step = app.findRecordById("steps", stepId);
    } catch (_) {
        throw new NotFoundError("step not found");
    }
    getOwnedTaskOr404(app, uid, step.getString("taskId"));
    return step;
}

// The step directly following `headId` in its chain, i.e. the step whose
// previousStepId == headId. null if headId is the tail. Chain order within a
// task is unique by previousStepId (one successor per node).
function findStepSuccessor(app, taskId, headId) {
    const candidates = app.findRecordsByFilter(
        "steps",
        "taskId = {:tid} && previousStepId = {:hid}",
        "",
        0,
        0,
        { tid: taskId, hid: headId }
    );
    return candidates.length > 0 ? candidates[0] : null;
}

// ---------------------------------------------------------------------------
// Routes
// ---------------------------------------------------------------------------

// GET /api/steps — list steps.
//   ?taskId=<id>  → all steps in one task (getStepListByTaskId)
//   (no param)    → every step belonging to the caller's tasks (getStepList)
routerAdd("GET", "/api/steps", (e) => {
    const uid = authId(e);
    const query = e.requestInfo().query || {};
    const taskId = query["taskId"] ? query["taskId"].toString() : "";

    if (taskId) {
        // Validate ownership up front so a foreign taskId → 404, not [].
        getOwnedTaskOr404($app, uid, taskId);
        const steps = $app.findRecordsByFilter(
            "steps",
            "taskId = {:tid}",
            "-created",
            0,
            0,
            { tid: taskId }
        );
        return e.json(200, steps.map(exportRecord));
    }

    const owned = ownedTaskIds($app, uid);
    if (owned.size === 0) return e.json(200, []);
    const steps = $app.findRecordsByFilter("steps", "1 = 1", "", 0, 0);
    return e.json(200, steps.filter((s) => owned.has(s.getString("taskId"))).map(exportRecord));
}, $apis.requireAuth());

// POST /api/steps — create a step (appended to the end of the chain by
// linking it after `previousStepId`, or as a new head if none given).
//   body: { "name": string, "taskId": string, "previousStepId"?: string }
routerAdd("POST", "/api/steps", (e) => {
    const uid = authId(e);
    const body = e.requestInfo().body || {};
    const name = (body["name"] || "").toString().trim();
    const taskId = (body["taskId"] || "").toString();
    const previousStepId = body["previousStepId"] ? body["previousStepId"].toString() : "";

    if (!name) throw e.badRequestError("name is required");
    if (!taskId) throw e.badRequestError("taskId is required");
    getOwnedTaskOr404($app, uid, taskId);

    const collection = $app.findCollectionByNameOrId("steps");
    const record = new Record(collection, {
        name: name,
        taskId: taskId,
        isCompleted: false,
        previousStepId: previousStepId || null,
    });
    $app.save(record);
    return e.json(200, exportRecord(record));
}, $apis.requireAuth());

// POST /api/steps/insert — insert a new step mid-chain, directly after an
// existing one, splicing between it and its current successor.
//   body: { "name": string, "afterStepId": string }
//
// Two writes, atomic:
//   1. create the new step with previousStepId = afterStepId
//   2. if afterStepId had a successor, re-point it to follow the new step
// A failure rolls both back, so the chain can never split into two heads —
// an improvement over the client's "leave the successor orphaned" path.
routerAdd("POST", "/api/steps/insert", (e) => {
    const uid = authId(e);
    const body = e.requestInfo().body || {};
    const name = (body["name"] || "").toString().trim();
    const afterStepId = (body["afterStepId"] || "").toString();

    if (!name) throw e.badRequestError("name is required");
    if (!afterStepId) throw e.badRequestError("afterStepId is required");
    const afterStep = getOwnedStepOr404($app, uid, afterStepId);
    const taskId = afterStep.getString("taskId");

    let createdExport;

    $app.runInTransaction((txApp) => {
        // The successor that currently follows afterStepId, if any.
        const successor = findStepSuccessor(txApp, taskId, afterStepId);

        const collection = txApp.findCollectionByNameOrId("steps");
        const newStep = new Record(collection, {
            name: name,
            taskId: taskId,
            isCompleted: false,
            previousStepId: afterStepId,
        });
        txApp.save(newStep);
        createdExport = newStep.publicExport();

        // Bridge the gap: the old successor now follows the new step.
        if (successor) {
            successor.set("previousStepId", newStep.id);
            txApp.save(successor);
        }
    });

    return e.json(200, createdExport);
}, $apis.requireAuth());

// PUT /api/steps/{id} — update a step's editable fields (name, isCompleted,
// previousStepId). Only fields present in the body are written.
//   body: { "name"?: string, "isCompleted"?: boolean, "previousStepId"?: string }
routerAdd("PUT", "/api/steps/{id}", (e) => {
    const uid = authId(e);
    const stepId = e.request.pathValue("id");
    const record = getOwnedStepOr404($app, uid, stepId);

    const body = e.requestInfo().body || {};
    const has = (k) => body[k] !== undefined && body[k] !== null;

    if (has("name")) record.set("name", body["name"].toString());
    if (has("isCompleted")) record.set("isCompleted", !!body["isCompleted"]);
    if (has("previousStepId")) {
        const v = body["previousStepId"].toString();
        record.set("previousStepId", v ? v : null);
    }

    $app.save(record);
    return e.json(200, exportRecord(record));
}, $apis.requireAuth());

// DELETE /api/steps/{id} — delete a step and bridge the gap so the chain
// stays connected.
//
// Atomic splice:
//   1. find the successor (the step whose previousStepId == this id)
//   2. re-point it at this step's predecessor (or null if this was the head)
//   3. delete this step
// All inside one transaction, so the chain is never left with a dangling
// reference — unlike the client's "log and continue" variant.
routerAdd("DELETE", "/api/steps/{id}", (e) => {
    const uid = authId(e);
    const stepId = e.request.pathValue("id");
    const step = getOwnedStepOr404($app, uid, stepId);
    const taskId = step.getString("taskId");
    const predecessorId = step.getString("previousStepId") || null;

    $app.runInTransaction((txApp) => {
        const successor = findStepSuccessor(txApp, taskId, stepId);
        if (successor) {
            successor.set("previousStepId", predecessorId);
            txApp.save(successor);
        }
        txApp.delete(step);
    });

    return e.json(200, { id: stepId, deleted: true });
}, $apis.requireAuth());

// POST /api/steps/task/{taskId}/unfinish — set isCompleted=false on every
// completed step in a task. Only the flag is touched; names and the
// previousStepId chain are left intact. All flips run in one transaction.
//
// Returns { "unfinished": <count> } — the number of steps actually flipped.
routerAdd("POST", "/api/steps/task/{taskId}/unfinish", (e) => {
    const uid = authId(e);
    const taskId = e.request.pathValue("taskId");
    getOwnedTaskOr404($app, uid, taskId);

    const steps = $app.findRecordsByFilter(
        "steps",
        "taskId = {:tid} && isCompleted = true",
        "",
        0,
        0,
        { tid: taskId }
    );

    let count = 0;
    $app.runInTransaction((txApp) => {
        for (const step of steps) {
            step.set("isCompleted", false);
            txApp.save(step);
            count += 1;
        }
    });

    return e.json(200, { unfinished: count });
}, $apis.requireAuth());
