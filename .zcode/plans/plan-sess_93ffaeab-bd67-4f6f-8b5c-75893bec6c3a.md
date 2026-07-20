## Plan: Derive project completion from tasks + sort by updatedAt + bump on task create

### Goal
1. Remove `isCompleted` AND `completedAt` from the Project model/adaptor/DB calls (completion is derived from tasks).
2. Order projects in `project.dart` by `updatedAt` (newest first), with **incomplete projects always above completed ones** (within each group, newest `updatedAt` on top).
3. Bump a project's `updatedAt` when a task is created in it.

### Derived completion rule
A project is "completed" iff `total > 0 && completed == total` (already used by `_ProjectProgressIndicator`). Projects with 0 tasks are **incomplete**.

---

### Step 1 — `lib/models.dart`: drop `isCompleted` + `completedAt` from `Project`
Remove the `isCompleted` and `completedAt` field declarations and the matching constructor params. The `Project` class keeps `id, name, userId, createdAt, updatedAt`.

### Step 2 — `lib/adaptor.dart`: drop the two fields from `ProjectAdaptor`
- `fromJson`: remove `completedAtStr` parsing and `isCompleted: json['isCompleted']`.
- `toJson`: remove the `isCompleted` and `completedAt` entries.

### Step 3 — `lib/api.dart`
- **`createProject`**: remove `isCompleted` and `completedAt` from the create body (keep `name`, `userId`).
- **`updateProject`**: change body to `{'name': project.name}` (drop `isCompleted`). Document that PocketBase autodate refreshes `updatedAt`.
- **`createTask`**: after a successful task create, do a best-effort `projects.update` on `projectId` to bump its `updatedAt`. Use an empty-ish body `{'name': <current name>}` (or a no-op field) so the record is written and autodate fires. Fetch the project name first via `getOne` so we don't clobber it; if the fetch/update fails, log and continue (the task was still created). Don't let this side-effect turn a successful task create into a failure — return the task-create result.
- **`duplicateTask`'s `_createTaskRecord`**: leave as-is. Duplication is a secondary path; bumping on each duplicated task would be noisy and the spec says "task creation only" (the dialog path). The duplicated root counts as the user-initiated one, so I'll bump the project `updatedAt` once after `duplicateTask`'s root is created, to keep the duplicate visible at the top. *(Light touch — a single bump for the whole duplicate operation.)*

### Step 4 — `lib/components/editProjectDialog.dart`: remove the "Completed" toggle
- Remove `_isCompleted` state and the `SwitchListTile`.
- Update `_save()` to build the `Project` without `isCompleted`/`completedAt`.
- Keep the name field as the only editable field. (If only name remains, the dialog stays as a simple rename dialog — no structural change to the widget itself.)

### Step 5 — `lib/pages/project.dart`: ordering + derived completion
- **Ordering**: introduce a sort in `_loadProjects` (or just before building the list). Sort key:
  1. Incomplete projects first; completed (derived) projects last.
  2. Within each group, by `updatedAt` descending (newest on top).
  - Derive completion using the already-fetched `_taskCounts` map: `counts != null && counts.total > 0 && counts.completed == counts.total`.
- **`_ProjectProgressIndicator`**: change its signature from `(isCompleted, completed, total)` to `(completed, total)` and collapse the completion branch to just `total > 0 && completed == total` (drop the now-removed `isCompleted` input). The progress-ring branch and folder branch stay the same.
- **Row leading call site**: pass only `completed`/`total`.
- The row title (`project.name`) gets no strikethrough/grey styling for completion (matches current behavior — no change needed there).
- Optional but consistent: show the **`updatedAt`** in the subtitle instead of `createdAt` (since ordering now keys off it, showing it makes the order explainable). I'll add it as "Updated <date>".

### Step 6 — Verify
- `flutter analyze lib/` to ensure no references to the removed `Project.isCompleted`/`completedAt` remain.

---

### Files changed
1. `lib/models.dart` — Project: drop `isCompleted`, `completedAt`
2. `lib/adaptor.dart` — ProjectAdaptor: drop both fields in fromJson/toJson
3. `lib/api.dart` — createProject/updateProject drop the fields; createTask bumps project updatedAt; duplicateTask bumps once
4. `lib/components/editProjectDialog.dart` — remove Completed switch
5. `lib/pages/project.dart` — sort logic + _ProjectProgressIndicator signature change + subtitle shows updatedAt

### Non-goals / untouched
- Task/Step `isCompleted` (those models keep their fields).
- `getTaskCountsByProject` (already exists, reused as-is).
- `createProject` ordering — new projects auto-bump `updatedAt` on create via autodate, so they naturally sort to the top.

### Risk notes
- The `createTask` project-bump adds one extra network call (a `getOne` + an `update`) per task creation. If either fails it's logged and swallowed — task creation still reports success.
- `duplicateTask` will do a single project-bump after the root copy is made (not per descendant), to avoid N bumps and because that's the user-initiated action.