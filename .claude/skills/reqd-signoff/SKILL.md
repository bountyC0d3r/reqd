---
name: reqd-signoff
description: Record PM sign-off or revision request, maintaining full revision history
license: MIT
compatibility: Works with Claude Code. No external CLI required.
metadata:
  author: reqd
  version: "1.0"
---

# reqd-signoff

Record a PM sign-off or revision request. Maintains a full revision history in sign-offs/pm.md. Blocks development until approved.

## Input

The argument is the change name.

## Steps

### 1. Validate

Check `reqd/changes/<name>/translation.md` exists. If not, tell the user to run `/reqd:translate <name>` first.

### 2. Load current state

Read `reqd/changes/<name>/sign-offs/pm.md` if it exists. Count existing revisions to determine the next revision number (start at 1).

Read `reqd/changes/<name>/.reqd.yaml` for current status.

### 3. Gather sign-off input

Use AskUserQuestion: "PM decision for `<name>`?"
Options: `approved` or `needs-revision`

Use AskUserQuestion: "Reviewer name (e.g. @sarah):"

If `needs-revision`, use AskUserQuestion:
"Describe the concerns (one per line, press enter twice when done):"

### 4a. If needs-revision

Append to `reqd/changes/<name>/sign-offs/pm.md`:

```markdown
## Revision <N> — <YYYY-MM-DD>

**Status:** needs-revision
**Reviewer:** <reviewer>

**Concerns:**
- <concern 1>
- <concern 2>
```

Update `reqd/changes/<name>/.reqd.yaml`:
```yaml
status: blocked
```

Print:

```
⚠ Revision <N> recorded — status: BLOCKED

Concerns:
  - <concern 1>
  - <concern 2>

Next steps:
  1. Update spec to address concerns
  2. /reqd:translate <name>   — regenerate translation
  3. /reqd:signoff <name>     — re-submit for approval
```

### 4b. If approved

Append to `reqd/changes/<name>/sign-offs/pm.md`:

```markdown
## Revision <N> — <YYYY-MM-DD>

**Status:** approved ✅
**Reviewer:** <reviewer>
```

Update `reqd/changes/<name>/.reqd.yaml`:
```yaml
status: in-progress
```

Print the full revision history summary, then:

```
✓ Revision <N> — approved by <reviewer> on <date>

Revision history:
<list all revisions with status>

Status: UNBLOCKED — ready to develop

Next: /reqd:task <name>
```

### 5. Initialize sign-offs/pm.md if new

If `sign-offs/pm.md` doesn't exist yet, write the header before appending:

```markdown
# PM Sign-offs — <name>

```

Then append the revision entry.

## Guardrails

- Never delete revision history — always append
- Status must be either `blocked` or `in-progress` after this runs — never leave it as `planning`
- Do not allow `/reqd:task` to run if status is `blocked` — remind the user to address concerns first
