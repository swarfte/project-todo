/// <reference path="../pb_data/types.d.ts" />
//
// Custom REST API for the "projects" resource.
//
// These routes port the project operations from the Flutter client
// (lib/api.dart -> APIService) to the server so callers can hit them
// directly. Every handler is scoped to the authenticated user: the
// collection's API rules (e.g. `@request.auth.id = userId.id`) only guard
// the built-in /api/collections endpoints, NOT the server-side $app calls
// used here, so each handler re-applies the same owner filter by hand to
// preserve the per-user isolation the client relies on.
//
// Auth is enforced via the $apis.requireAuth() middleware — a missing or
// invalid token yields a 401 before the handler runs.

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

// PocketBase serializes a user id as the auth record's id. All project
// records carry a `userId` relation to the `users` collection, so an
// authenticated request owns a project iff project.userId == e.auth.id.
function authId(e) {
    return e.auth.id;
}

// Returns the authenticated user's projects, newest first (matches the
// project page's "by updatedAt" ordering).
function findOwnedProjects(app, uid) {
    return app.findRecordsByFilter(
        "projects",
        "userId = {:uid}",
        "-updatedAt",
        0, // limit <= 0 → return all
        0,
        { uid: uid }
    );
}

// Fetch a single project by id and verify the caller owns it. Throws a 404
// (not 403) on a mismatch so the endpoint doesn't leak which ids exist.
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

// Expose a bare record as JSON. publicExport() mirrors what the built-in
// collection API returns (id + all non-hidden fields + created/updated).
function exportRecord(record) {
    return record.publicExport();
}

// ---------------------------------------------------------------------------
// Routes
// ---------------------------------------------------------------------------

// GET /api/projects — list the caller's projects (newest first).
routerAdd("GET", "/api/projects", (e) => {
    const uid = authId(e);
    const records = findOwnedProjects($app, uid);
    return e.json(200, records.map(exportRecord));
}, $apis.requireAuth());

// POST /api/projects — create a project owned by the caller.
//   body: { "name": string }
routerAdd("POST", "/api/projects", (e) => {
    const uid = authId(e);
    const body = e.requestInfo().body || {};
    const name = (body["name"] || "").toString().trim();

    if (!name) {
        throw e.badRequestError("name is required");
    }

    const collection = $app.findCollectionByNameOrId("projects");
    const record = new Record(collection, {
        name: name,
        userId: uid,
    });
    $app.save(record);

    return e.json(200, exportRecord(record));
}, $apis.requireAuth());

// PUT /api/projects/{id} — rename a project. PocketBase's autodate refreshes
// `updatedAt` on every write, so a rename also re-surfaces the project at the
// top of the "by updatedAt" ordering.
//   body: { "name": string }
routerAdd("PUT", "/api/projects/{id}", (e) => {
    const uid = authId(e);
    const projectId = e.request.pathValue("id");
    const record = getOwnedProjectOr404($app, uid, projectId);

    const body = e.requestInfo().body || {};
    const name = (body["name"] || "").toString().trim();
    if (!name) {
        throw e.badRequestError("name is required");
    }

    record.set("name", name);
    $app.save(record);

    return e.json(200, exportRecord(record));
}, $apis.requireAuth());

// DELETE /api/projects/{id} — delete a project. Cascading delete rules on the
// relations already remove its tasks (and their steps) in the schema, so this
// only needs to drop the project itself.
routerAdd("DELETE", "/api/projects/{id}", (e) => {
    const uid = authId(e);
    const projectId = e.request.pathValue("id");
    const record = getOwnedProjectOr404($app, uid, projectId);

    $app.delete(record);

    return e.json(200, { id: projectId, deleted: true });
}, $apis.requireAuth());

// GET /api/projects/task-counts — how many tasks each of the caller's
// projects has, split into total / completed.
//
// Mirrors the client's getTaskCountsByProject(): PocketBase has no COUNT
// aggregate in the JS hooks, so we fetch the caller's tasks in one query and
// aggregate in JS. Returns { "<projectId>": { total, completed } }; projects
// with no tasks are omitted (the UI treats absence as zero).
routerAdd("GET", "/api/projects/task-counts", (e) => {
    const uid = authId(e);

    // Only tasks belonging to the caller's projects are counted. We resolve
    // the caller's project ids first, then keep only tasks under them.
    const ownedProjects = findOwnedProjects($app, uid);
    const ownedProjectIds = new Set(ownedProjects.map((p) => p.id));
    if (ownedProjectIds.size === 0) {
        return e.json(200, {});
    }

    const allTasks = $app.findRecordsByFilter("tasks", "1 = 1", "", 0, 0);

    const counts = {};
    for (const task of allTasks) {
        const pid = task.getString("projectId");
        if (!ownedProjectIds.has(pid)) continue;

        if (!counts[pid]) counts[pid] = { total: 0, completed: 0 };
        counts[pid].total += 1;
        if (task.getBool("isCompleted")) counts[pid].completed += 1;
    }

    return e.json(200, counts);
}, $apis.requireAuth());
