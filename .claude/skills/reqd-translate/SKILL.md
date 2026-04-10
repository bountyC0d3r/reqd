---
name: reqd-translate
description: Translate the technical spec into PM-readable language for sign-off
license: MIT
compatibility: Works with Claude Code. No external CLI required.
metadata:
  author: reqd
  version: "1.0"
---

# reqd-translate

Generate a PM-readable translation of the technical spec. The PM reads only this file — not the spec. It answers: "Did the engineer understand what I asked for?"

## Input

The argument is the change name.

## Steps

### 1. Validate

Check `reqd/changes/<name>/spec/design.md` exists. If not, tell the user to run `/reqd:plan <name>` first.

### 2. Load all spec context

Read:
1. `reqd/changes/<name>/requirements.md` — what PM originally asked
2. `reqd/changes/<name>/proposal.md` — north star
3. `reqd/changes/<name>/spec/design.md` — technical design
4. All `reqd/changes/<name>/spec/capabilities/*.md` — capability details
5. `reqd/config.yaml` — apply any `rules.translation` if present
6. `reqd/changes/<name>/sign-offs/pm.md` — if exists, read previous revision concerns to ensure they were addressed

### 3. Generate translation.md

Write a plain-language summary that a non-technical PM can read and validate. No jargon. No code. No architecture diagrams.

Write to `reqd/changes/<name>/translation.md`:

```markdown
# What We're Building — <name>
<!-- Revision: <N> | Generated: <YYYY-MM-DD> -->
<!-- Share this file with PM for review. -->

## What we're building
<2-4 sentences. Plain language. What the user will experience.>

## What we're NOT building
<Explicit non-goals from design.md. Bullet list.>
- <item>
- <item>

## Assumptions the engineer made
<Decisions made that PM didn't explicitly specify but were required to proceed.>
- <assumption>
- <assumption>

## Open questions for PM
<Anything genuinely unclear that needs PM input before or during development.>
- <question>

_(No open questions — ready to proceed.)_
```

If `sign-offs/pm.md` has previous revision concerns, add a section:

```markdown
## Changes from last revision
- <concern from revision N> → <how it was addressed>
```

Apply any `rules.translation` from config.yaml.

### 4. Update revision number

Read current `translation.md` if it exists to determine the revision number (look for `Revision: N` in the comment). Increment by 1. Start at 1 if new.

### 5. Confirm and guide

Print:

```
✓ Translation generated: reqd/changes/<name>/translation.md
  Revision: <N>

Share this file with PM for review.
PM does not need to read the spec — only translation.md.

Next: /reqd:signoff <name>
```

## Guardrails

- No technical jargon — write for a product manager
- Do not invent requirements not in the spec
- Open questions must be genuine blockers, not rhetorical
- "What we're NOT building" must match design.md out-of-scope section
- If there were previous revision concerns, explicitly show how they were addressed
