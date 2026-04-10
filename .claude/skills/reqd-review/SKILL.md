---
name: reqd-review
description: Check for spec drift — compare spec capabilities against the codebase and surface gaps
license: MIT
compatibility: Works with Claude Code. No external CLI required.
metadata:
  author: reqd
  version: "1.0"
---

# reqd-review

Scan the codebase for evidence that each spec capability has been implemented. Flag gaps as potential spec drift. Surface any logged deviations. Offer to add tasks for unimplemented items.

## Input

The argument is the change name.

## Steps

### 1. Validate

Check `reqd/changes/<name>/spec/capabilities/` exists with at least one file. If not, tell the user to run `/reqd:plan <name>` first.

### 2. Load spec capabilities

Read all `reqd/changes/<name>/spec/capabilities/*.md`. For each capability file:
- Extract the capability name (from filename and `# Capability:` heading)
- Extract acceptance criteria (`- [ ]` items under `## Acceptance criteria`)
- Extract key behaviours (bullet points under `## Behaviour`)

### 3. Scan codebase for each capability

For each capability, use Grep to search the codebase for implementation evidence:
- Search for key terms from the capability name and behaviour descriptions
- Search for function names, class names, route paths, or identifiers that would implement the capability
- Exclude the `reqd/` directory from searches

Example: for capability `totp-verification`, search for: `totp`, `TOTP`, `verifyTotp`, `verify_totp`, `authenticator`

Classify each capability as:
- **Likely implemented**: Found multiple matching identifiers
- **Possibly implemented**: Found some matches, but incomplete signal
- **Not found**: No relevant code found

### 4. Load deviations

Read `reqd/changes/<name>/deviations.md` if it exists. Note how many deviations are logged.

### 5. Load PM sign-off concerns

Read `reqd/changes/<name>/sign-offs/pm.md`. Extract concerns from any `needs-revision` entries. Check if the final revision addressed them.

### 6. Report findings

Print a structured review:

```
reqd review: <name>
─────────────────────────────────────────────

Spec capabilities:

  ✅  totp-verification     — implementation found
  ✅  recovery-codes        — implementation found
  ⚠️  admin-enforcement     — not found (check src/middleware/)

─────────────────────────────────────────────
Gaps detected: 1

  admin-enforcement
  Spec says: "2FA enforcement applies on next login for admins"
  Code scan: no enforcement found in middleware or auth paths

─────────────────────────────────────────────
<if deviations exist>
Deviations logged: <N>
  Review deviations.md before archiving — PM acknowledgement recommended.

─────────────────────────────────────────────
```

### 7. Offer to create tasks for gaps

For each gap, ask: "Add a task for `<capability>` gap? [Y/n]"

If yes, append to `reqd/changes/<name>/spec/tasks.md`:
```
- [ ] [review gap] Implement <capability>: <specific missing behaviour>
```

### 8. Final summary

```
Review complete.
  <N> gaps found  (<M> tasks added)
  <N> deviations logged

<if no gaps and no deviations>
✅ No gaps found. Ready to archive.
Next: /reqd:archive <name>

<if gaps exist>
Address gaps, then run /reqd:review <name> again.
```

## Guardrails

- Read-only except for appending tasks to tasks.md
- Do not delete or modify spec files
- Grep searches should be broad enough to catch reasonable naming variations
- A "not found" result is a signal, not a definitive failure — always show the search context
