/// <reference path="../pb_data/types.d.ts" />
//
// Custom REST API for the "tasks" resource.
//
// Ports the task operations from the Flutter client (lib/api.dart ->
// APIService) to the server. Like project.pb.js, every handler is scoped to
// the authenticated user: the collection API rules don't apply to server-side
// $app calls, so ownership is re-checked by hand. A task is owned iff the
// caller owns the project it belongs to (task.projectId -> projects.userId).
//
// The two multi-write operations — createTask (which bumps the parent
// project) and duplicateTask (which copies a whole subtree) — run inside
// $app.runInTransaction so a failure rolls everything back, instead of the
// client's old best-effort "leave partial state behind" behavior.

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

function authId(e) {
    return e.auth.id;
}

function exportRecord(record) {
    return record.publicExport();
}

// Resolve the set of project ids owned by the caller. A task is owned iff its
// projectId is in this set.
function ownedProjectIds(app, uid) {
    const projects = app.findRecordsByFilter(
        "projects",
        "userId = {:uid}",
        "",
        0,
        0,
        { uid: uid }
    );
    return new Set(projects.map((p) => p.id));
}

// Fetch a project and confirm the caller owns it. 404 on a mismatch.
function getOwnedProjectOr404(app, uid, projectId) {
    let record;
    try {
        record = app.findRecordById("projects", projectId);
    } catch (_) {
        throw new NotFoundError("project not found");
    }
    if (record.getString("userId") !== uid) {
        throw new NotFoundError("project not found");
    }
    return record;
}

// Fetch a task by id and confirm the caller owns it via its project. 404 on
// any miss or mismatch.
function getOwnedTaskOr404(app, uid, taskId) {
    let record;
    try {
        record = app.findRecordById("tasks", taskId);
    } catch (_) {
        throw new NotFoundError("task not found");
    }
    const project = app.findRecordById("projects", record.getString("projectId"));
    if (project.getString("userId") !== uid) {
        throw new NotFoundError("task not found");
    }
    return record;
}

// Bump a project's `updatedAt` by re-saving its name unchanged, so the
// project page's "newest first" ordering surfaces a project that just got a
// new task. PocketBase autodate only fires on writes to the project record
// itself, hence the explicit re-save.
function bumpProjectUpdatedAt(app, projectId) {
    const project = app.findRecordById("projects", projectId);
    project.set("name", project.getString("name"));
    app.save(project);
}

// ---------------------------------------------------------------------------
// Routes
// ---------------------------------------------------------------------------

// GET /api/tasks — list every task belonging to the caller's projects.
// Optional ?projectId= scopes to one project (matches getTaskListByProjectId).
routerAdd("GET", "/api/tasks", (e) => {
    const uid = authId(e);
    const query = e.requestInfo().query || {};
    const projectId = query["projectId"] ? query["projectId"].toString() : "";

    const owned = ownedProjectIds($app, uid);
    if (owned.size === 0) return e.json(200, []);

    const filter = projectId
        ? "projectId = {:pid}"
        : "1 = 1";
    const params = projectId ? { pid: projectId } : {};

    const tasks = $app.findRecordsByFilter("tasks", filter, "-updatedAt", 0, 0, params);

    // Re-check ownership even when projectId is supplied: a caller could pass
    // another user's project id, which findRecordsByFilter would happily use.
    const result = tasks.filter((t) => owned.has(t.getString("projectId")));
    return e.json(200, result.map(exportRecord));
}, $apis.requireAuth());

// POST /api/tasks — create a task in an owned project.
//   body: {
//     "name": string,
//     "projectId": string,
//     "previousTaskId"?: string,   // parent in the task tree (nullable = root)
//     "dueDate"?: string           // ISO 8601, optional
//   }
//
// Runs in a transaction with the parent-project `updatedAt` bump: the task is
// created and the project's ordering timestamp is refreshed atomically, so a
// failure never leaves a project touched but a task missing (or vice versa).
routerAdd("POST", "/api/tasks", (e) => {
    const uid = authId(e);
    const body = e.requestInfo().body || {};
    const name = (body["name"] || "").toString().trim();
    const projectId = (body["projectId"] || "").toString();
    const previousTaskId = body["previousTaskId"]
        ? body["previousTaskId"].toString()
        : "";
    const dueDate = body["dueDate"] ? body["dueDate"].toString() : "";

    if (!name) throw e.badRequestError("name is required");
    if (!projectId) throw e.badRequestError("projectId is required");
    // Validate ownership up front (inside the tx would also work, but failing
    // before opening a transaction gives a cleaner 404).
    getOwnedProjectOr404($app, uid, projectId);

    const collection = $app.findCollectionByNameOrId("tasks");
    let created;

    $app.runInTransaction((txApp) => {
        const record = new Record(collection, {
            name: name,
            projectId: projectId,
            userId: uid,
            isCompleted: false,
            dueDate: dueDate || null,
            previousTaskId: previousTaskId || null,
            completedAt: null,
            isFolded: false,
        });
        txApp.save(record);
        created = record;

        bumpProjectUpdatedAt(txApp, projectId);
    });

    return e.json(200, exportRecord(created));
}, $apis.requireAuth());

// PUT /api/tasks/{id} — update a task's editable fields.
//   body: {
//     "name"?: string,
//     "isCompleted"?: boolean,
//     "dueDate"?: string,          // ISO 8601 or "" / null to clear
//     "previousTaskId"?: string,   // repoint in the tree
//     "completedAt"?: string,
//     "isFolded"?: boolean
//   }
//
// Only fields actually present in the body are written, so a partial update
// (e.g. toggling just isCompleted) won't clobber the others.
routerAdd("PUT", "/api/tasks/{id}", (e) => {
    const uid = authId(e);
    const taskId = e.request.pathValue("id");
    const record = getOwnedTaskOr404($app, uid, taskId);

    const body = e.requestInfo().body || {};
    const has = (k) => body[k] !== undefined && body[k] !== null;

    if (has("name")) record.set("name", body["name"].toString());
    if (has("isCompleted")) record.set("isCompleted", !!body["isCompleted"]);
    if (has("dueDate")) {
        const v = body["dueDate"].toString();
        record.set("dueDate", v ? v : null);
    }
    if (has("previousTaskId")) {
        const v = body["previousTaskId"].toString();
        record.set("previousTaskId", v ? v : null);
    }
    if (has("completedAt")) {
        const v = body["completedAt"].toString();
        record.set("completedAt", v ? v : null);
    }
    if (has("isFolded")) record.set("isFolded", !!body["isFolded"]);

    $app.save(record);
    return e.json(200, exportRecord(record));
}, $apis.requireAuth());

// DELETE /api/tasks/{id} — delete a task. The schema cascades deletes to its
// steps (steps.taskId -> tasks with cascadeDelete), so only the task itself
// needs to go. Subtasks are NOT cascaded (previousTaskId is a plain text
// field, not a relation), so a parent delete leaves children as new roots —
// matching the client's deleteTask behavior.
routerAdd("DELETE", "/api/tasks/{id}", (e) => {
    const uid = authId(e);
    const taskId = e.request.pathValue("id");
    const record = getOwnedTaskOr404($app, uid, taskId);

    $app.delete(record);
    return e.json(200, { id: taskId, deleted: true });
}, $apis.requireAuth());

// GET /api/tasks/step-counts — how many steps each of the caller's tasks has,
// split into total / completed. Mirrors getStepCountsByTask(). Returns
// { "<taskId>": { total, completed } }; tasks with no steps are omitted.
routerAdd("GET", "/api/tasks/step-counts", (e) => {
    const uid = authId(e);
    const owned = ownedProjectIds($app, uid);
    if (owned.size === 0) return e.json(200, {});

    // Resolve the caller's task ids up front, then count only their steps.
    const tasks = $app.findRecordsByFilter("tasks", "1 = 1", "", 0, 0);
    const ownedTaskIds = new Set(
        tasks
            .filter((t) => owned.has(t.getString("projectId")))
            .map((t) => t.id)
    );
    if (ownedTaskIds.size === 0) return e.json(200, {});

    const steps = $app.findRecordsByFilter("steps", "1 = 1", "", 0, 0);
    const counts = {};
    for (const step of steps) {
        const tid = step.getString("taskId");
        if (!ownedTaskIds.has(tid)) continue;
        if (!counts[tid]) counts[tid] = { total: 0, completed: 0 };
        counts[tid].total += 1;
        if (step.getBool("isCompleted")) counts[tid].completed += 1;
    }
    return e.json(200, counts);
}, $apis.requireAuth());

// POST /api/tasks/{id}/duplicate — deep-copy a task and its entire subtree
// (descendants + each task's step chain) into the same project.
//
// The copy's root is a sibling of the original (reuses its previousTaskId), is
// named "<name> copy", and carries over completion/due/fold state and the
// step chain. Every descendant is copied the same way, with fresh
// previousTaskId links pointing at the new parents so the copied tree mirrors
// the original. Everything runs in one transaction: a failure deep in the
// subtree rolls the whole copy back, so no half-duplicated tree is left.
//
// Returns { "id": <newRootId> }.
routerAdd("POST", "/api/tasks/{id}/duplicate", (e) => {
    const uid = authId(e);
    const originalId = e.request.pathValue("id");
    const original = getOwnedTaskOr404($app, uid, originalId);

    let newRootId = "";

    $app.runInTransaction((txApp) => {
        newRootId = duplicateTaskTree(txApp, original);
        // A duplicate is user-initiated creation, so bump the project once.
        bumpProjectUpdatedAt(txApp, original.getString("projectId"));
    });

    return e.json(200, { id: newRootId });
}, $apis.requireAuth());

// ---------------------------------------------------------------------------
// Duplication (transaction-scoped; uses the txApp passed in)
// ---------------------------------------------------------------------------

// Create a copy of `source` with a new id, writing it through `txApp`.
// `previousTaskId` lets the caller link the copy into the new tree (the root
// copy reuses the original's previousTaskId; children get their new parent).
function createTaskCopy(txApp, source, previousTaskId) {
    const collection = txApp.findCollectionByNameOrId("tasks");
    const copy = new Record(collection, {
        name: source.getString("name"),
        projectId: source.getString("projectId"),
        userId: source.getString("userId"),
        isCompleted: source.getBool("isCompleted"),
        dueDate: source.getString("dueDate") || null,
        previousTaskId: previousTaskId || null,
        completedAt: source.getString("completedAt") || null,
        isFolded: source.getBool("isFolded"),
    });
    txApp.save(copy);
    return copy;
}

// Recursively duplicate `source` and everything under it. Returns the id of
// the newly created root copy.
function duplicateTaskTree(txApp, source) {
    const sourcePrev =
        source.getString("previousTaskId") || null;
    const rootCopy = createTaskCopy(txApp, source, sourcePrev);

    // Copy this task's step chain (order + completion preserved, links rebuilt).
    copyStepChain(txApp, source.id, rootCopy.id);

    // Recurse into every direct child (tasks whose previousTaskId == source).
    const children = txApp.findRecordsByFilter(
        "tasks",
        "previousTaskId = {:pid}",
        "-created",
        0,
        0,
        { pid: source.id }
    );
    for (const child of children) {
        const childCopy = createTaskCopy(txApp, child, rootCopy.id);
        copyStepChain(txApp, child.id, childCopy.id);
        duplicateSubtree(txApp, child, childCopy);
    }

    return rootCopy.id;
}

// Continue the recursion for descendants that already have their parent copy.
// `parentCopy` is the newly created parent; its children are relinked to it.
function duplicateSubtree(txApp, source, sourceCopy) {
    const children = txApp.findRecordsByFilter(
        "tasks",
        "previousTaskId = {:pid}",
        "-created",
        0,
        0,
        { pid: source.id }
    );
    for (const child of children) {
        const childCopy = createTaskCopy(txApp, child, sourceCopy.id);
        copyStepChain(txApp, child.id, childCopy.id);
        duplicateSubtree(txApp, child, childCopy);
    }
}

// Rebuild a task's step chain under a new task id, preserving order and
// completion. Steps are a linked list via previousStepId; we walk them in
// order (heads first) and re-link each copy to the previous copy created.
function copyStepChain(txApp, sourceTaskId, newTaskId) {
    const steps = txApp.findRecordsByFilter(
        "steps",
        "taskId = {:tid}",
        "-created",
        0,
        0,
        { tid: sourceTaskId }
    );
    if (steps.length === 0) return;

    // Index by id, and map each previousStepId -> its successor, mirroring the
    // client's _orderSteps so the copy lands in the same order even if records
    // were inserted out of chain order.
    const byId = {};
    for (const s of steps) byId[s.id] = s;

    const successorOf = {};
    const heads = [];
    for (const s of steps) {
        const prev = s.getString("previousStepId");
        const hasValidPrev =
            prev && byId[prev] && prev !== s.id;
        if (!hasValidPrev) {
            heads.push(s);
        } else if (!successorOf[prev]) {
            successorOf[prev] = s;
        }
    }

    const ordered = [];
    const visited = {};
    function walk(current) {
        let node = current;
        while (true) {
            if (visited[node.id]) return; // cycle guard
            visited[node.id] = true;
            ordered.push(node);
            const next = successorOf[node.id];
            if (!next) return;
            node = next;
        }
    }
    for (const head of heads) walk(head);
    // Safety net: append anything unreached (degenerate data).
    for (const s of steps) {
        if (!visited[s.id]) ordered.push(s);
    }

    // Re-create in order, linking each new step to the previous new step.
    const collection = txApp.findCollectionByNameOrId("steps");
    let previousNewId = null;
    for (const step of ordered) {
        const copy = new Record(collection, {
            name: step.getString("name"),
            taskId: newTaskId,
            isCompleted: step.getBool("isCompleted"),
            previousStepId: previousNewId,
        });
        txApp.save(copy);
        previousNewId = copy.id;
    }
}
