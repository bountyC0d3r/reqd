---
name: reqd-recap
description: Generate a daily standup summary for in-flight changes — progress since last update, current task, blockers, and sign-off state
license: MIT
compatibility: Works with Claude Code. No external CLI required.
metadata:
  author: reqd
  version: "1.0"
---

# reqd-recap

Generate a narrative standup summary for one or all active changes. Uses git commit history to determine what changed since the last update. Output is copy-pasteable into Slack or a standup doc.

## Input

The argument is an optional change name.
- If provided: produce a full narrative recap for that change only.
- If omitted: produce a compact recap for all active changes in `reqd/changes/` (excluding `archive/`).

## Steps — Single Change

### 1. Validate

Check `reqd/changes/<name>/.reqd.yaml` exists. If not, tell the user no change named `<name>` exists and stop.

### 2. Load change state

Read:
1. `reqd/changes/<name>/.reqd.yaml` — name, ref, status, created
2. `reqd/changes/<name>/spec/tasks.md` — if exists, parse `- [x]` (done) and `- [ ]` (remaining)
3. `reqd/changes/<name>/sign-offs/pm.md` — if exists, parse latest revision status and concerns
4. `reqd/changes/<name>/deviations.md` — if exists, count entries

### 3. Compute git baseline

Use Bash to find the most recent commit that touched the change directory:

```bash
git log --oneline -1 -- reqd/changes/<name>/
```

If a commit is found, use that commit as the baseline. Record its hash, date, and message.

If no commit found (new change, never committed), mark baseline as `none` — this is the first recap.

### 4. Determine progress since baseline

**If baseline exists**, use Bash to get all commits since then touching the change path:

```bash
git log --oneline <hash>..HEAD -- reqd/changes/<name>/
```

Also check for uncommitted changes:

```bash
git diff HEAD -- reqd/changes/<name>/
```

From this data, identify:
- Tasks that flipped from `- [ ]` to `- [x]` (completed since baseline)
- New files added (e.g. new capabilities, deviations logged)
- Sign-off status changes

**If no baseline**, treat all currently checked tasks as "done this session" and all state as new.

**If no commits and no diff since baseline**, mark as "no updates since last checkpoint".

### 5. Determine current task

From `spec/tasks.md`, find the first `- [ ]` unchecked task. This is "Today's task".

If all tasks are checked, mark as "all tasks complete — ready for review/archive".

### 6. Determine blockers

Blockers exist if any of:
- `.reqd.yaml` status is `blocked` → surface PM concerns from latest `needs-revision` in `pm.md`
- `.reqd.yaml` status is `planning` → "spec not finalized, awaiting PM sign-off"
- Tasks remain but sign-off is not approved → "development blocked until PM approves"
- Missing `spec/tasks.md` → "no task checklist yet"

### 7. Lifecycle branch

Adjust narrative tone based on `.reqd.yaml` status:

- `planning` → planning phase, no dev progress expected yet
- `blocked` → surface PM revision concerns prominently
- `in-progress` → standard progress + current task narrative
- `done` (all tasks complete, not yet archived) → "ready for review and archive"

### 8. Sign-off branch

Parse `sign-offs/pm.md`:
- No file → `pending (not submitted)`
- Latest revision status is `needs-revision` → `blocked — revision <N> concerns: <list concerns>`
- Latest revision status is `approved` → `approved ✅ (revision <N>, <date>, <reviewer>)`

### 9. Print full recap

```
reqd recap: <name>
<date> | ref: <ref or "—"> | branch: feat/<name> (if derivable from git)
─────────────────────────────────────────────

Yesterday
  <if tasks completed since baseline>
  ✓ Completed: <task description>
  ✓ Completed: <task description>

  <if no task change but commits exist>
  Updated: <brief description of commits>

  <if no baseline>
  First recap — no prior baseline.

  <if no changes since baseline>
  No updates since last checkpoint (<baseline date>).

Today
  → <first unchecked task, or "All tasks complete ✅">

Blockers
  <if blocked>
  ⚠ <blocker description>
  <if none>
  None.

Sign-off
  <sign-off state>

Tasks: <X>/<Y> complete
<if deviations>
Deviations: <N> logged — review before archiving
─────────────────────────────────────────────
```

## Steps — All Changes (no argument)

### 1. Find all active changes

Use Glob to find all `reqd/changes/*/.reqd.yaml` excluding `archive/`.

If no active changes found:

```
No active changes. Start one with /reqd:new <change-name>
```

### 2. For each change, run Steps 2–8 above (condensed)

### 3. Print compact multi-change standup

```
reqd recap — <YYYY-MM-DD>
─────────────────────────────────────────────

<change-name> (<ref or "—">)
  Yesterday: <1-line summary of completed tasks or "no updates">
  Today:     <current task or "all tasks complete ✅">
  Sign-off:  <approved ✅ / blocked ⚠ / pending ⏳>
  Tasks:     <X>/<Y>

<change-name> (<ref or "—">)
  Yesterday: ...
  Today:     ...
  Sign-off:  ...
  Tasks:     <X>/<Y>

─────────────────────────────────────────────
Needs attention:
  ⚠ <blocked-change>: <PM concern summary>
  ⏳ <pending-change>: sign-off not submitted yet

─────────────────────────────────────────────
Copy the block above into Slack or your standup doc.
```

"Needs attention" section is omitted if no changes are blocked or pending.

### 4. Data quality fallback

If any required file is missing for a change (e.g. no `tasks.md`, no `sign-offs/pm.md`):
- Never fail the entire command.
- Print `"(no data)" ` for that field and continue.
- Do not error out in all-changes mode.

## Guardrails

- Read-only — this command never writes files
- Never infer task completion from anything other than `- [x]` checkboxes in `tasks.md`
- Git baseline is informational — missing git history is a graceful fallback, not a failure
- Narrative must be copy-pasteable with no extra formatting noise
- Archived changes (`reqd/changes/archive/`) are always excluded
