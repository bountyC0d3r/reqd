# reqd

**Requirements-driven development lifecycle for Claude Code.**

Engineers ingest finalized PM requirements, generate a technical spec with AI assistance, translate it back to PM language for sign-off, develop guided by spec context, detect drift, and ship with a done gate — all in git, no external tools required.

See **[docs/example.md](docs/example.md)** for a full end-to-end walkthrough.

---

## Install

```bash
# Clone and install globally (available in all projects)
git clone https://github.com/bountyC0d3r/reqd.git
cd reqd
./install.sh
```

```bash
# Or install locally (current project only)
./install.sh --local
```

```bash
# One-liner (global)
curl -fsSL https://raw.githubusercontent.com/bountyC0d3r/reqd/main/install.sh | bash
```

To uninstall:
```bash
./uninstall.sh          # global
./uninstall.sh --local  # local
```

---

## How It Works

```
PM finalizes requirements in Jira/JPD
         ↓
/reqd:new       Engineer ingests requirements
         ↓
/reqd:plan      AI generates technical spec
         ↓
/reqd:translate AI translates spec → PM language
         ↓
/reqd:signoff   PM approves or requests revision (loops until approved)
         ↓
/reqd:task      Engineer implements, guided by spec context
         ↓
/reqd:review    AI checks spec vs codebase for drift
         ↓
/reqd:archive   Done gate → PR description → archived
```

---

## Commands

### `/reqd:new <change-name>`
Create a new change. Paste your PM requirements (from Jira, JPD, or free-form). reqd scaffolds the change directory and generates a north-star proposal.

```
/reqd:new mfa-rollout
```

### `/reqd:plan <change-name>`
Generate a technical spec from requirements: design approach, per-capability specs, and an implementation task list. Review and edit before translating.

```
/reqd:plan mfa-rollout
```

### `/reqd:translate <change-name>`
Translate the technical spec into plain-language PM summary. The PM reads **only this file** — no spec, no jargon. Covers what's being built, what's not, assumptions made, and open questions.

```
/reqd:translate mfa-rollout
```

### `/reqd:signoff <change-name>`
Record PM approval or revision request. Maintains full revision history in `sign-offs/pm.md`. Development is blocked until approved.

```
/reqd:signoff mfa-rollout
```

Revision loop (Path C):
1. PM requests revision → concerns logged → status: **blocked**
2. Engineer updates spec → re-runs `/reqd:translate` → re-submits
3. PM approves → status: **in-progress** → revision history preserved

### `/reqd:status [change-name]`
Show health of a change. Without a name, shows all active changes.

```
/reqd:status mfa-rollout
/reqd:status
```

### `/reqd:task <change-name> [task-number]`
Work on the next task (or a specific task) with full spec context loaded. AI assistance is grounded in the spec and PM sign-off notes. Unspecced decisions are logged to `deviations.md`.

```
/reqd:task mfa-rollout
/reqd:task mfa-rollout 3
```

### `/reqd:review <change-name>`
Scan the codebase for implementation evidence per spec capability. Flags gaps as potential drift. Surfaces logged deviations. Offers to add tasks for unimplemented items.

```
/reqd:review mfa-rollout
```

### `/reqd:archive <change-name>`
Close the change. Checks the done gate (all tasks complete + PM approved), surfaces deviations for acknowledgement, generates a PR description, copies it to clipboard, and moves the change to the archive.

```
/reqd:archive mfa-rollout
```

---

## Project Structure

After your first `/reqd:new`, your project will have:

```
reqd/
  config.yaml               ← project context and rules for AI
  changes/
    mfa-rollout/
      .reqd.yaml            ← metadata: status, ref, created
      requirements.md       ← PM requirements (immutable)
      proposal.md           ← shared north star
      translation.md        ← PM-readable spec summary
      spec/
        design.md           ← technical design
        tasks.md            ← implementation checklist
        capabilities/       ← per-capability specs
      sign-offs/
        pm.md               ← approval + revision history
      deviations.md         ← unspecced implementation decisions
    archive/
      2026-04-10-mfa-rollout/
```

Commit `reqd/` to your repo — it's your team's living record of every decision made.

---

## Configuration

Edit `reqd/config.yaml` in your project:

```yaml
# Project context shown to AI when generating specs/translations
context: |
  Tech stack: TypeScript, Node.js, PostgreSQL
  We use conventional commits
  Domain: SaaS B2B platform

# Required sign-offs (default: pm)
required_sign_offs:
  - pm

# Per-artifact generation rules
rules:
  translation:
    - Keep under 300 words
    - Always include an "Open questions" section
  tasks:
    - Break into chunks under 2 hours each
```

---

## The Done Gate

A change is **done** when:
- All tasks in `spec/tasks.md` are checked `- [x]`
- `sign-offs/pm.md` contains an `approved ✅` entry

`/reqd:archive` enforces this — it will not proceed until both conditions are met.

---

## Requirements

- [Claude Code](https://claude.ai/code) CLI
- No other dependencies

---

## License

MIT
