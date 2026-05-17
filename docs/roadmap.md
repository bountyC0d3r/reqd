# Roadmap

Features planned for future iterations of `reqd`, documented from exploration sessions.

---

## Coming Next

### `/reqd:test` — Acceptance Criteria → Test Stubs

Every capability spec already contains acceptance criteria:

```markdown
## Acceptance criteria
- [ ] User can scan QR code to enroll
- [ ] Invalid TOTP codes are rejected
- [ ] Recovery codes work when TOTP is unavailable
```

`/reqd:test` reads these and scaffolds language-aware test stubs, creating a traceable chain:

```
PM requirement → spec capability → acceptance criteria → test stub → implementation
```

The stubs are derived from PM requirements, not invented by the engineer. Test coverage becomes a byproduct of spec quality.

---

### `/reqd:why <file>` — Codebase Archaeology

Query the archive to answer "why does this code exist?"

```
/reqd:why src/auth/totp.ts

Found in: reqd/changes/archive/2026-04-10-mfa-rollout/
  Requirement:  "Users should be able to enable TOTP-based 2FA"
  Ref:          JPD-412
  PM sign-off:  @sarah, 2026-04-10
  Deviation:    "Window extended to ±1 step for clock drift tolerance"
```

Combines with `git blame` to give complete traceability: who changed it (git) + why it exists (reqd).

---

## Implemented

### `/reqd:recap` — Daily Standup Summary

Generates a narrative standup summary for one or all active changes. Uses git commit history to determine progress since the last update. Output covers: completed tasks (yesterday), current task (today), any blockers, and PM sign-off state. Copy-pasteable into Slack or a standup doc. Turns reqd from a milestone tool into a daily ritual.

See [`docs/example.md`](example.md) for a full walkthrough.

### `/reqd:sync` — Jira Staleness Detection

Detects if the Jira ticket has changed since the spec was locked. Surfaces a diff, asks the
engineer whether to include the change in scope, and posts a comment to Jira recording the
decision. When scope is expanded, gates snapshot advancement on PM re-approval.

### `/reqd:update` — Jira Progress Comment

Posts an auto-generated progress comment to the Jira ticket. Comment covers tasks completed
since the last update, the current task, PM sign-off state, and new deviations. Engineer
confirms before posting.

Both commands require a Jira MCP server to be configured and a `ref` field in `.reqd.yaml`.

---

## Backlog

### Requirements Staleness Detection

When a change has a Jira/JPD `ref` in `.reqd.yaml`, detect if the source ticket has been updated since the spec was created. Surface a warning in `/reqd:status`. Leads to a `/reqd:sync` command that diffs the updated requirements against the current spec and prompts for re-translation if scope changed.

### Change Name Inference

Make `<name>` optional across all reqd commands. If exactly one change is `in-progress`,
use it automatically. If multiple, list them and ask the engineer to pick. Removes the need
to type the change name on every command during normal single-change workflows.

### Multi-Stakeholder Sign-off

Extend the sign-off mechanism beyond PM to support security, design, legal, and other roles. The `required_sign_offs` field in `config.yaml` is already scaffolded for this. Each role gets its own slice of the translation and its own sign-off entry. Done gate expands to require all configured roles.

---

## Design Principles to Preserve

When building any of the above:

- **Read-only commands stay read-only** — status, recap, why should never write files
- **Deviations stay logged, not re-opened** — unspecced decisions go to deviations.md; sign-off loop re-opening is v3+
- **PM never reads the spec** — new features should maintain the translation layer as the only PM touchpoint
- **Git is the source of truth** — all state lives in files, no hidden database
