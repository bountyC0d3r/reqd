---
name: reqd-new
description: Create a new reqd change by ingesting requirements from PM (Jira/JPD or free-form text)
license: MIT
compatibility: Works with Claude Code. No external CLI required.
metadata:
  author: reqd
  version: "1.0"
---

# reqd-new

Create a new requirements-driven change. Ingest PM requirements, scaffold the change directory, and generate the initial proposal.

## Input

The argument passed to this skill is the change name (kebab-case). Example: `mfa-rollout`, `user-onboarding-v2`.

If no argument is provided, use AskUserQuestion to ask for a name.

## Steps

### 1. Determine change name

Use the argument as the change name. If missing, use AskUserQuestion:
- "What is the name for this change? (use kebab-case, e.g. mfa-rollout)"

Validate: kebab-case only (lowercase letters, numbers, hyphens). If invalid, correct it silently by converting to kebab-case.

### 2. Check for existing change

Check if `reqd/changes/<name>/` already exists using the Glob tool. If it does:
- Inform the user: "A change named `<name>` already exists. Run `/reqd:status <name>` to see its state."
- Stop.

### 3. Gather requirements

Use AskUserQuestion:
- "Paste your requirements (from Jira, JPD, or describe the feature):"

Then use AskUserQuestion:
- "Optional: Jira/JPD reference (e.g. JPD-412) — press enter to skip:"

### 4. Create directory structure

Use Bash to create all needed directories:
```bash
mkdir -p reqd/changes/<name>/spec/capabilities reqd/changes/<name>/sign-offs
```

### 5. Bootstrap reqd/config.yaml if missing

Check if `reqd/config.yaml` exists. If not, find the reqd installer's `templates/config.yaml`.
If the template is not found, write a minimal config:
```yaml
# reqd — requirements-driven development lifecycle
# context: |
#   Add your tech stack and domain knowledge here
```
Write to `reqd/config.yaml`.

### 6. Write requirements.md

Write to `reqd/changes/<name>/requirements.md`:

```markdown
# Requirements — <name>

<!-- Source: <ref if provided, else "provided by PM"> -->
<!-- Created: <YYYY-MM-DD> -->
<!-- IMMUTABLE: Do not edit. This is the source of truth for PM intent. -->

<raw requirements text exactly as provided — no paraphrasing>
```

### 7. Write .reqd.yaml

Write to `reqd/changes/<name>/.reqd.yaml`:

```yaml
change: <name>
ref: "<jira/jpd ref, or empty string if none>"
status: planning
created: <YYYY-MM-DD>
```

### 8. Generate proposal.md

Read the requirements. Generate a concise proposal (3-5 sentences) covering:
- What is being built and why
- Who it is for
- The key outcome expected

Write to `reqd/changes/<name>/proposal.md`:

```markdown
# Proposal — <name>

<3-5 sentence paragraph: what, why, who, expected outcome>
```

Keep faithful to the input — don't add scope or assumptions not in the requirements.

### 9. Confirm and guide

Print:

```
✓ Change created: reqd/changes/<name>/
  requirements.md   — PM requirements (immutable source of truth)
  proposal.md       — shared north star
  .reqd.yaml        — status: planning

Next: /reqd:plan <name>
```

## Guardrails

- Never paraphrase or edit requirements.md — copy verbatim
- Do not generate spec files — that is /reqd:plan's job
- Proposal must be faithful to requirements, not aspirational
