---
name: reqd-plan
description: Generate a technical spec from ingested requirements — design, capabilities, and tasks
license: MIT
compatibility: Works with Claude Code. No external CLI required.
metadata:
  author: reqd
  version: "1.0"
---

# reqd-plan

Generate a technical spec from the change's requirements. Produces design.md, per-capability specs, and a task checklist. Engineer reviews and edits before translating for PM.

## Input

The argument is the change name. If missing, list available changes from `reqd/changes/` and ask the user to pick one.

## Steps

### 1. Validate change exists and is in the right state

Check `reqd/changes/<name>/.reqd.yaml` exists. If not, tell the user to run `/reqd:new <name>` first.

Read `.reqd.yaml`. If status is `in-progress` or later, warn:
- "This change already has a spec. Re-running will overwrite spec files. Continue? [y/N]"
- Use AskUserQuestion to confirm. If no, stop.

### 2. Load context

Read in order:
1. `reqd/changes/<name>/requirements.md` — source of truth
2. `reqd/changes/<name>/proposal.md` — north star
3. `reqd/config.yaml` — project context and rules (if exists)

Extract any `context` and `rules.tasks` / `rules.design` from config to guide generation.

### 3. Generate spec/design.md

Based on requirements and proposal, write a technical design covering:
- **Approach**: How we'll implement this (architecture, patterns, key decisions)
- **Data model changes** (if any)
- **API / interface changes** (if any)
- **Dependencies** (new libraries, services, infrastructure)
- **Risks**: What could go wrong, what's uncertain
- **Out of scope**: What we are explicitly not doing

Write to `reqd/changes/<name>/spec/design.md`:

```markdown
# Design — <name>

## Approach
<technical approach>

## Data Model
<changes, or "No data model changes">

## API / Interface
<changes, or "No interface changes">

## Dependencies
<new deps, or "No new dependencies">

## Risks
- <risk 1>
- <risk 2>

## Out of Scope
- <item>
```

Apply any `rules.design` from config.yaml.

### 4. Generate spec/capabilities/*.md

Identify the discrete capabilities implied by the requirements (e.g. "totp-verification", "recovery-codes", "admin-enforcement"). Create one file per capability.

For each capability, write to `reqd/changes/<name>/spec/capabilities/<capability-name>.md`:

```markdown
# Capability: <capability name>

## What it does
<1-2 sentence description>

## Behaviour
- <specific behaviour 1>
- <specific behaviour 2>
- <edge cases>

## Acceptance criteria
- [ ] <testable criterion 1>
- [ ] <testable criterion 2>
```

Name files in kebab-case matching the capability (e.g. `totp-verification.md`).

### 5. Generate spec/tasks.md

Break implementation into concrete tasks. Each task should be:
- Actionable (starts with a verb)
- Scoped to one concern
- Completable independently

Apply any `rules.tasks` from config.yaml (e.g. "under 2 hours each").

Write to `reqd/changes/<name>/spec/tasks.md`:

```markdown
# Tasks — <name>

- [ ] <task 1>
- [ ] <task 2>
- [ ] <task 3>
```

Typical task count: 5–12. If requirements are small, fewer is fine.

### 6. Update .reqd.yaml status

Update `reqd/changes/<name>/.reqd.yaml`:
```yaml
status: planning
```
(Stays planning until PM sign-off.)

### 7. Write jira_snapshot (if ref is set)

Read `.reqd.yaml`. If `ref` field is set and non-empty:

- Use the Jira MCP server to fetch the ticket identified by `ref`
- Retrieve: `summary`, `description`, `priority`, `labels`
- Compute `description_hash` as a short hash of the description text

If the Jira MCP is unavailable or the fetch fails, skip this step silently and print a
warning — do not block the plan from completing:

```
⚠ Could not fetch Jira snapshot for <ref> — Jira MCP unavailable. Run /reqd:sync <name> later to take the initial snapshot.
```

If fetch succeeds, append to `.reqd.yaml` (preserve all existing fields):

```yaml
jira_snapshot:
  taken_at: <today's date YYYY-MM-DD>
  summary: <ticket summary>
  description_hash: <hash>
  priority: <priority>
  labels: <labels array>
```

### 8. Confirm and guide

Print:

```
✓ Spec generated: reqd/changes/<name>/spec/
  design.md                    — technical approach
  capabilities/<n> files       — per-capability specs
  tasks.md                     — <N> tasks

Review and edit the spec files before sharing with PM.

Next: /reqd:translate <name>
```

## Guardrails

- Stay faithful to requirements — do not invent scope
- Out of scope items must be explicit, not implicit
- Tasks must map to capabilities — no orphaned tasks
- Do not generate translation.md — that is /reqd:translate's job
