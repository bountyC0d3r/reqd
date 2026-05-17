---
name: reqd-sync
description: Check if the Jira ticket has changed since the spec was locked — surface a diff, record the engineer's scope decision, and post a comment to Jira
license: MIT
compatibility: Works with Claude Code. Requires a Jira MCP server to be configured.
metadata:
  author: reqd
  version: "1.0"
---

# reqd-sync

Detect if the Jira ticket has changed since the spec was locked. Ask the engineer whether
to include the change in scope or not. Post a Jira comment recording the decision. Gate
snapshot advancement on PM sign-off when scope is expanded.

## Input

The argument is the change name (required). Example: `mfa-rollout`

## Steps

### 1. Validate

- Check `reqd/changes/<name>/.reqd.yaml` exists. If not → "No change named `<name>` found. Run `/reqd:new <name>` first."
- Read `.reqd.yaml`. Check `ref` field is set. If not → "No Jira ref found for `<name>`. Set `ref: JPD-412` in `reqd/changes/<name>/.reqd.yaml` to enable sync."
- Attempt to call the Jira MCP tool. If MCP is unavailable → "Jira MCP not available. Ensure your Jira MCP server is configured and authenticated."

### 2. Fetch live ticket

Use the Jira MCP server to fetch the ticket identified by `ref`. Retrieve:
- `summary`
- `description` (full text)
- `priority`
- `labels`

Compute `description_hash` as a short hash of the description text (used for change detection only — not cryptographic).

### 3. Check for existing snapshot

Read `jira_snapshot` from `.reqd.yaml`.

**If no `jira_snapshot` exists** (change predates this feature or plan was run before this
feature was added): take a snapshot now, write it to `.reqd.yaml`, and exit. No diff is
possible yet.

Write to `.reqd.yaml` (append these fields, preserve all existing fields):
```yaml
jira_snapshot:
  taken_at: <today's date YYYY-MM-DD>
  summary: <ticket summary>
  description_hash: <hash>
  priority: <priority>
  labels: <labels array>
```

Print:
```
⚠ No snapshot found — taking initial snapshot of <ref>.
✓ Snapshot recorded. Re-run /reqd:sync <name> to detect future changes.
```

Stop here. Do not proceed to diff.

### 4. Diff snapshot vs live ticket

Compare `jira_snapshot` fields against the live ticket values:
- `summary`: compare string
- `description`: compare `description_hash`
- `priority`: compare string
- `labels`: compare sorted arrays

#### 4a. No changes detected

If all fields match:

```
reqd sync: <name>
◆ Fetching <ref> via Jira MCP...

✅ No changes detected — ticket matches spec snapshot (<jira_snapshot.taken_at>)
```

Stop here. Write nothing.

#### 4b. Changes detected

Print the diff:

```
reqd sync: <name>
◆ Fetching <ref> via Jira MCP...

⚠ Ticket updated since spec was locked (<jira_snapshot.taken_at> → <today>)

  summary:     <"unchanged" or old → new>
  description: <"unchanged" or "changed">
  priority:    <"unchanged" or old → new>
  labels:      <"unchanged" or [old] → [new]>

<if description changed>
Description diff:
  <show lines added with + prefix, lines removed with - prefix>
```

Then ask:

```
? Include this change in the current spec? [y/N]
```

### 5. Path 1 — Out of scope (answer: N)

Prompt for a reason (required — do not allow blank):

```
? Reason for excluding:
>
```

Compose a Jira comment using the reason, the diff, and the decision:

```
reqd sync — <name> (<today's date>)

Change reviewed: "<summary of what changed in the ticket>"

Decision: Out of scope for this change.
Reason: <engineer's reason verbatim>

Spec remains valid. Development continuing on <name>.
```

Post this comment to `<ref>` via Jira MCP.

Update `jira_snapshot` in `.reqd.yaml`: advance `taken_at` to today and update all snapshot fields to current live ticket values.

Print:
```
✓ Comment posted to <ref>.
✓ Snapshot updated to <today>.

Next: /reqd:task <name>
```

### 6. Path 2 — In scope (answer: Y)

#### First run (scope expanded, sign-off not yet re-done)

Check `.reqd.yaml` for a `sync_pending_signoff: true` field.

If NOT present: this is the first time the engineer is marking this change as in-scope.

Compose a Jira comment:

```
reqd sync — <name> (<today's date>)

Change reviewed: "<summary of what changed in the ticket>"

Decision: In scope — spec will be updated to reflect the new requirements.
Status: Spec revision in progress. PM re-approval required before development continues.
```

Post this comment to `<ref>` via Jira MCP.

Write `sync_pending_signoff: true` to `.reqd.yaml` (preserve all existing fields).

Do NOT update `jira_snapshot` yet.

Print:
```
✓ Comment posted to <ref>.

⚠ Snapshot NOT updated — will advance once spec is re-approved.

Next steps:
  1. Update spec files to reflect the new requirement
  2. /reqd:translate <name>   — regenerate PM translation
  3. /reqd:signoff <name>     — get PM re-approval
  4. /reqd:sync <name>        — re-run to confirm and advance snapshot
```

#### Re-run while `sync_pending_signoff: true`

If `.reqd.yaml` contains `sync_pending_signoff: true`, check sign-off state:

Read `reqd/changes/<name>/sign-offs/pm.md`. Find the last revision entry.

**If sign-off is not yet approved** (status is `needs-revision` or file has no approved entry):

```
reqd sync: <name>
◆ Fetching <ref> via Jira MCP...
◆ Checking change state...

⚠ Cannot advance snapshot — sign-off not yet approved.

  Sign-off status: <current status from pm.md>

  Complete the sign-off loop first:
    /reqd:signoff <name>
```

Stop. Do not update snapshot.

**If sign-off is approved:**

Read the approved revision: reviewer name and date.

Compose a Jira comment:

```
reqd sync — <name> (<today's date>)

Spec updated and re-approved.
PM sign-off: <reviewer>, revision <N>, <date>.
Development resuming.
```

Post this comment to `<ref>` via Jira MCP.

Remove `sync_pending_signoff` from `.reqd.yaml`.
Update `jira_snapshot` in `.reqd.yaml`: advance `taken_at` to the live ticket's last-changed date and update all snapshot fields to current live ticket values.

Print:
```
✓ Sign-off confirmed — <reviewer> approved revision <N> on <date>
✓ Comment posted to <ref>.
✓ Snapshot updated.

Next: /reqd:task <name>
```

## Behaviour Matrix

| Situation | Snapshot advances? | Comment posted? |
|---|---|---|
| No changes detected | No | No |
| Changes → out of scope | Yes, immediately | Yes — decision + engineer's reason |
| Changes → in scope (first run) | No | Yes — signals revision in progress |
| Changes → in scope, sign-off pending/blocked (re-run) | No | No |
| Changes → in scope, sign-off approved (re-run) | Yes | Yes — confirms re-approval |
| No snapshot yet (bootstrap run) | Yes (baseline) | No |

## Guardrails

- Snapshot never advances while `sync_pending_signoff: true` and sign-off is not approved
- Reason is always required when marking out of scope — reject blank input
- Read-only when no changes detected — write nothing
- Never modify spec files — that is always the engineer's responsibility
- All `.reqd.yaml` writes must preserve existing fields — append/update only
