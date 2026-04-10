---
name: reqd-task
description: Work on a specific task with full spec context — AI-guided, grounded in signed-off requirements
license: MIT
compatibility: Works with Claude Code. No external CLI required.
metadata:
  author: reqd
  version: "1.0"
---

# reqd-task

Work on the next task (or a specific task) from the change's task list. Loads full spec context and PM sign-off notes so AI assistance is grounded in what was agreed.

## Input

Argument format: `<change-name>` or `<change-name> <task-number>`

Examples:
- `mfa-rollout` — work on next unchecked task
- `mfa-rollout 3` — work on task 3 specifically

## Steps

### 1. Validate change and sign-off

Read `reqd/changes/<name>/.reqd.yaml`. Check status:
- If `planning` → "Run `/reqd:translate <name>` and get PM sign-off first."
- If `blocked` → "This change is blocked pending PM revision. Run `/reqd:signoff <name>` after updating the spec."
- If `in-progress` or `done` → proceed.

### 2. Load spec context

Read all of:
1. `reqd/changes/<name>/spec/tasks.md` — full task list
2. `reqd/changes/<name>/spec/design.md` — technical approach
3. All `reqd/changes/<name>/spec/capabilities/*.md` — capability specs
4. `reqd/changes/<name>/sign-offs/pm.md` — revision history and PM concerns
5. `reqd/changes/<name>/requirements.md` — original PM intent

### 3. Identify the task

If a task number was given, find that task (1-indexed from tasks.md).
If no number, find the first `- [ ]` unchecked task.

If all tasks are complete:
```
All tasks are complete ✅
Run /reqd:review <name> to check for spec drift before archiving.
```

### 4. Present task with context

Display:

```
Task <N>: <task description>
─────────────────────────────────────────────
Spec context:
  <relevant capability or design excerpt>

PM sign-off notes:
  <any revision concerns relevant to this task, or "None">
─────────────────────────────────────────────
```

Then assist the engineer with implementation. Provide:
- Code scaffolding if helpful
- Reference to spec constraints (e.g. "spec says recovery codes expire after 90 days")
- Flags if the task touches something that had a PM revision concern

### 5. Mark task complete

When the engineer confirms the task is done, edit `reqd/changes/<name>/spec/tasks.md`:
- Change `- [ ] <task>` to `- [x] <task>`

Print remaining task count.

### 6. Log deviations (if any)

If during implementation the engineer encounters something not covered by the spec:
- Ask: "This wasn't in the spec — should I log it as a deviation?"
- If yes, append to `reqd/changes/<name>/deviations.md`:

```markdown
# Deviations — <name>

## Task <N> — <YYYY-MM-DD>
<Description of what was implemented and why it wasn't in the spec.>
PM review recommended at archive.
```

If `deviations.md` doesn't exist, create it with the header first.

### 7. Guide next step

After marking complete:

```
✓ Task <N> complete  (<remaining> remaining)

<if more tasks>
Next: /reqd:task <name>   — continue with task <N+1>

<if all tasks done>
All tasks complete ✅
Next: /reqd:review <name>
```

## Guardrails

- Do not re-open sign-off for unspecced decisions — log to deviations.md only (v2 evolution)
- Always ground assistance in spec content — don't invent requirements
- If a PM revision concern is relevant to the current task, always surface it explicitly
- Never mark a task complete without engineer confirmation
