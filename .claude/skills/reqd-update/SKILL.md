---
name: reqd-update
description: Post an auto-generated progress comment to the Jira ticket — tasks completed since last update, current task, sign-off state, new deviations
license: MIT
compatibility: Works with Claude Code. Requires a Jira MCP server to be configured.
metadata:
  author: reqd
  version: "1.0"
---

# reqd-update

Post an auto-generated progress comment to the Jira ticket. Comment covers tasks completed
since the last update, the current task, PM sign-off state, and any new deviations.
Engineer always confirms before the comment is posted.

## Input

The argument is the change name (required). Example: `mfa-rollout`

## Steps

### 1. Validate

- Check `reqd/changes/<name>/.reqd.yaml` exists. If not → "No change named `<name>` found. Run `/reqd:new <name>` first."
- Read `.reqd.yaml`. Check `ref` field is set. If not → "No Jira ref found for `<name>`. Set `ref: JPD-412` in `reqd/changes/<name>/.reqd.yaml` to enable updates."
- Attempt to call the Jira MCP tool. If MCP is unavailable → "Jira MCP not available. Ensure your Jira MCP server is configured and authenticated."

### 2. Read change state

Read:
1. `reqd/changes/<name>/spec/tasks.md` — parse all `- [x]` (done) and `- [ ]` (remaining) lines; extract task description text for each
2. `reqd/changes/<name>/sign-offs/pm.md` — find latest revision entry; extract status, reviewer, date
3. `reqd/changes/<name>/deviations.md` — if exists, read all entries with their dates
4. `reqd/changes/<name>/.reqd.yaml` — read `last_update.tasks_complete` and `last_update.posted_at`

If `spec/tasks.md` does not exist:
```
⚠ No task list found for <name>. Run /reqd:plan <name> first.
```
Stop.

### 3. Compute delta

**Baseline:** `last_update.tasks_complete` from `.reqd.yaml`. If no `last_update` field exists, baseline is 0.

**Completed since last update:** Count the `- [x]` tasks. Tasks at index > baseline (0-indexed from top of file) are "new since last update". Collect their description text.

Example: if baseline is 2 and there are now 5 checked tasks, tasks at index 2, 3, 4 are new.

**Current task:** First `- [ ]` unchecked task. If none exist, mark as "all tasks complete ✅".

**New deviations:** If `deviations.md` exists and `last_update.posted_at` is set, include only deviation entries dated after `last_update.posted_at`. If no `last_update.posted_at`, include all deviation entries.

### 4. Warn if nothing new

If completed-since-last-update count is 0 AND new-deviations count is 0:

```
⚠ Nothing new since last update (<last_update.posted_at or "never">) — 0 tasks completed, 0 new deviations.
? Post anyway? [y/N]
```

If the engineer answers N, stop. If Y, continue to compose.

### 5. Compose comment

Build the comment text:

```
reqd update — <name> (<today's date YYYY-MM-DD>)

Progress: <total_checked>/<total_tasks> tasks complete

Completed since last update:
  ✓ <task description>
  ✓ <task description>
  <if none: "(none — first update or no new completions)">

Current task: <first unchecked task description, or "all tasks complete ✅ — ready for /reqd:review">

Sign-off: <approved ✅ (<reviewer>, revision <N>, <date>) | blocked ⚠ (revision <N> needs revision) | pending ⏳ (not submitted)>

<only if new_deviations > 0>
New deviations: <count>
  - <deviation description> (<date>)
```

### 6. Confirm with engineer

Display the composed comment and ask:

```
? Post this comment to <ref>? [Y/n]
```

If engineer answers N, stop. Do not write anything.

### 7. Post and record

Post the comment to `<ref>` via Jira MCP.

On success, update `.reqd.yaml` (preserve all existing fields):
```yaml
last_update:
  posted_at: <today's date YYYY-MM-DD>
  tasks_complete: <total_checked count>
```

Print:
```
✓ Comment posted to <ref>.
✓ last_update snapshot saved (tasks_complete: <N>, posted_at: <today>).
```

On MCP failure, print the error and do NOT write `last_update`. The engineer can retry.

## Guardrails

- Comment is always shown to the engineer before posting — never posted silently
- Only deviations newer than `last_update.posted_at` are included — no repetition of previously posted deviations
- `last_update` is only written after a confirmed successful MCP post — never on failure or cancellation
- If all tasks are complete, current task line reads: "all tasks complete ✅ — ready for /reqd:review"
- If `sign-offs/pm.md` does not exist, sign-off shows as "pending ⏳ (not submitted)"
