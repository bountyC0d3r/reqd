---
name: reqd-archive
description: Close a completed change — verify done gate, generate PR description, move to archive
license: MIT
compatibility: Works with Claude Code. No external CLI required.
metadata:
  author: reqd
  version: "1.0"
---

# reqd-archive

Close out a completed change. Verify the done gate (all tasks complete + PM sign-off present), surface any deviations for acknowledgement, generate a PR description, copy it to clipboard, and move the change to the archive.

## Input

The argument is the change name.

## Steps

### 1. Validate

Check `reqd/changes/<name>/.reqd.yaml` exists.

### 2. Check done gate

Read `reqd/changes/<name>/spec/tasks.md` — count unchecked `- [ ]` tasks.
Read `reqd/changes/<name>/sign-offs/pm.md` — check for an `approved ✅` entry.

If either condition fails, print what's blocking and stop:

```
⚠ Cannot archive — done gate not met:

  <if tasks incomplete>
  ☐ Tasks: <N> tasks still incomplete
    Run /reqd:task <name> to continue.

  <if no sign-off>
  ☐ Sign-off: no PM approval on record
    Run /reqd:signoff <name> after sharing translation.md with PM.
```

### 3. Surface deviations

If `reqd/changes/<name>/deviations.md` exists and has content:

```
⚠ Deviations logged during development:
─────────────────────────────────────────────
<contents of deviations.md>
─────────────────────────────────────────────
These were not in the original spec. Recommend PM acknowledgement.
```

Use AskUserQuestion: "Continue with archive? (PM has been notified of deviations) [y/N]"
If no, stop.

### 4. Generate PR description

Read:
1. `reqd/changes/<name>/proposal.md`
2. `reqd/changes/<name>/translation.md`
3. `reqd/changes/<name>/sign-offs/pm.md` (for reviewer + revision count)
4. `reqd/changes/<name>/deviations.md` (if exists)
5. `reqd/changes/<name>/.reqd.yaml` (for ref)

Generate a PR description:

```markdown
## <proposal title — first line of proposal.md>

<Ref: JPD-xxx>

### What was built
<2-4 sentences from translation.md "What we're building" section>

### What was NOT built
<bullet list from translation.md "What we're NOT building" section>

### PM sign-off
<reviewer>, <date> (<N> revision(s))

<if deviations exist>
### Deviations from spec
<contents of deviations.md, reformatted as bullet list>
```

### 5. Copy to clipboard

Use Bash to copy the PR description to clipboard:
```bash
echo "<pr description>" | pbcopy
```

On non-Mac systems (no pbcopy), print the description for manual copy.

Print: `✓ PR description copied to clipboard`

### 6. Archive the change

Get today's date in `YYYY-MM-DD` format.

Use Bash to move the change directory:
```bash
mkdir -p reqd/changes/archive
mv reqd/changes/<name> reqd/changes/archive/YYYY-MM-DD-<name>
```

Update the `.reqd.yaml` inside the archived directory:
```yaml
status: archived
archived: <YYYY-MM-DD>
```

### 7. Confirm

```
✓ <name> archived → reqd/changes/archive/<date>-<name>/

  Sign-offs:  ✅ <reviewer> (<N> revisions)
  Tasks:      <N>/<N> complete
  Deviations: <N logged, or "none">

PR description copied to clipboard — ready to open your pull request.
```

## Guardrails

- Never archive if done gate is not met — be strict
- Never delete the change directory — always move to archive
- Deviations must be surfaced before archiving — never silently skip them
- PR description must include non-goals to prevent scope creep assumptions
