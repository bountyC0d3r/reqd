---
name: reqd-status
description: Show the current health of a change — sign-offs, task progress, and done gate
license: MIT
compatibility: Works with Claude Code. No external CLI required.
metadata:
  author: reqd
  version: "1.0"
---

# reqd-status

Show a clear health summary of a change. Reads .reqd.yaml, sign-offs/pm.md, and spec/tasks.md to report sign-off state, task progress, and whether the done gate is met.

## Input

The argument is an optional change name.
- If provided: show status for that change only.
- If omitted: show a summary of all active changes in `reqd/changes/` (excluding archive/).

## Steps — Single Change

### 1. Validate

Check `reqd/changes/<name>/.reqd.yaml` exists. If not, tell the user no change named `<name>` exists.

### 2. Read state

Read:
1. `reqd/changes/<name>/.reqd.yaml` — name, ref, status, created
2. `reqd/changes/<name>/sign-offs/pm.md` — if exists, parse revision history for latest status
3. `reqd/changes/<name>/spec/tasks.md` — if exists, count `- [x]` vs `- [ ]`
4. `reqd/changes/<name>/deviations.md` — if exists, count entries

### 3. Determine sign-off state

Parse `sign-offs/pm.md`:
- No file → `pending (not submitted)`
- Last revision status is `needs-revision` → `blocked (revision <N> rejected)`
- Last revision status is `approved` → `approved ✅ (revision <N>, <date>, <reviewer>)`

Count total revisions.

### 4. Determine done gate

Done = all of:
- PM sign-off is `approved`
- All tasks are `- [x]` (zero unchecked)

### 5. Print status

```
change:    <name>
ref:       <ref or "—">
status:    <planning | blocked | in-progress | done>
created:   <date>

sign-off:  <approved ✅ / blocked ⚠ / pending ⏳>  (<N> revision(s))
tasks:     <X>/<Y> complete
done gate: <✅ ready to archive | ⚠ N tasks remaining | ⚠ awaiting sign-off>

<if deviations.md exists>
deviations: <N> logged — review before archiving
```

## Steps — All Changes (no argument)

### 1. Find all changes

Use Glob to find all `reqd/changes/*/.reqd.yaml` excluding `archive/`.

### 2. For each change, read .reqd.yaml and tasks.md

Print a compact table:

```
Active changes:

  NAME                STATUS        TASKS    SIGN-OFF
  mfa-rollout         in-progress   4/8      ✅ approved
  user-onboarding     blocked       0/6      ⚠ needs revision
  api-rate-limiting   planning      0/4      ⏳ pending

Run /reqd:status <name> for details.
```

### 3. If no active changes

```
No active changes. Start one with /reqd:new <change-name>
```

## Guardrails

- Read-only — this command never writes files
- Do not infer done status from status field in .reqd.yaml alone — always recompute from tasks + sign-offs
