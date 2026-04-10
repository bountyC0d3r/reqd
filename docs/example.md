# Example: MFA Rollout

A full end-to-end walkthrough of `reqd` using a real-world feature: adding two-factor authentication.

**Scenario:** PM has finalized requirements in Jira (`JPD-412`). Engineer picks it up.

---

## Phase 1 — Plan

### `/reqd:new mfa-rollout`

```
? Paste your requirements (from Jira, JPD, or describe the feature):
> Users should be able to enable two-factor authentication via an
  authenticator app. Must support TOTP. Recovery codes required.
  Admin accounts must enforce 2FA.

? Optional: Jira/JPD reference (e.g. JPD-412) — press enter to skip:
> JPD-412

✓ Change created: reqd/changes/mfa-rollout/
  requirements.md   — PM requirements (immutable source of truth)
  proposal.md       — shared north star
  .reqd.yaml        — status: planning

Next: /reqd:plan mfa-rollout
```

---

### `/reqd:plan mfa-rollout`

```
◆ Reading requirements...
◆ Generating spec...

✓ reqd/changes/mfa-rollout/spec/design.md
✓ reqd/changes/mfa-rollout/spec/capabilities/totp-verification.md
✓ reqd/changes/mfa-rollout/spec/capabilities/recovery-codes.md
✓ reqd/changes/mfa-rollout/spec/capabilities/admin-enforcement.md
✓ reqd/changes/mfa-rollout/spec/tasks.md    (8 tasks)

Review and edit the spec files before sharing with PM.

Next: /reqd:translate mfa-rollout
```

Engineer opens the spec, refines the design — adds a note about HMAC window tolerance, removes one out-of-scope task.

---

### `/reqd:translate mfa-rollout`

```
◆ Translating spec → PM language...

✓ reqd/changes/mfa-rollout/translation.md  (Revision 1)

────────────────────────────────────────────────────
## What we're building
Users can enable 2FA from account settings using any standard
authenticator app (Google Authenticator, Authy, 1Password).
Admin accounts will have 2FA enforced.

## What we're NOT building
- SMS-based 2FA
- Forced enrollment for regular users (opt-in only)

## Assumptions the engineer made
- Recovery codes are one-time use, 8 codes per user
- Existing sessions are not invalidated when 2FA is enabled
- Lost device flow: recovery codes only (no SMS fallback)

## Open questions for PM
- Should 2FA enforcement for admins apply immediately
  or on next login?
────────────────────────────────────────────────────

Share reqd/changes/mfa-rollout/translation.md with PM.

Next: /reqd:signoff mfa-rollout
```

---

### `/reqd:signoff mfa-rollout` — First pass

PM reads only `translation.md`. No spec. No jargon.

```
? PM decision for mfa-rollout? (approved / needs-revision)
> needs-revision

? Reviewer name:
> @sarah

? Describe the concerns:
> Enforcement for admins should apply on next login, not immediately.
  Recovery codes should expire after 90 days.

⚠ Revision 1 recorded — status: BLOCKED

Concerns:
  - Admin enforcement: apply on next login, not immediately
  - Recovery codes: expire after 90 days

Next steps:
  1. Update spec to address concerns
  2. /reqd:translate mfa-rollout   — regenerate translation
  3. /reqd:signoff mfa-rollout     — re-submit for approval
```

Engineer updates `spec/capabilities/admin-enforcement.md` and `spec/capabilities/recovery-codes.md`, re-runs translate.

---

### `/reqd:signoff mfa-rollout` — Second pass

```
? PM decision for mfa-rollout? (approved / needs-revision)
> approved

? Reviewer name:
> @sarah

✓ Revision 2 — approved by @sarah on 2026-04-10

Revision history:
  Revision 1 — 2026-04-10   needs-revision
  Revision 2 — 2026-04-10   approved ✅

Status: UNBLOCKED — ready to develop

Next: /reqd:task mfa-rollout
```

---

## Phase 2 — Develop

### `/reqd:status mfa-rollout`

```
change:    mfa-rollout
ref:       JPD-412
status:    in-progress
created:   2026-04-10

sign-off:  approved ✅  (2 revisions, @sarah)
tasks:     0/8 complete
done gate: ⚠ 8 tasks remaining
```

---

### `/reqd:task mfa-rollout`

```
Task 1: Add TOTP secret generation to user model
─────────────────────────────────────────────────
Spec context:
  totp-verification.md — "TOTP secret stored per user,
  generated on 2FA enrollment, HMAC-SHA1 with 30s window"

PM sign-off notes:
  None relevant to this task.
─────────────────────────────────────────────────

[AI assists with scaffolding...]

✓ Task 1 complete  (7 remaining)

Next: /reqd:task mfa-rollout
```

---

### `/reqd:task mfa-rollout 4`

```
Task 4: Add recovery code generation (90-day expiry)
─────────────────────────────────────────────────────
Spec context:
  recovery-codes.md — "8 one-time-use codes per user,
  hashed at rest"

PM sign-off notes:
  Revision 1 concern: "Recovery codes should expire after 90 days"
  ← This task was updated to address this concern.
─────────────────────────────────────────────────────

[AI assists — explicitly references the 90-day expiry from PM revision...]

Unspecced decision detected:
  "Recovery code redemption should invalidate all other codes."
  This wasn't in the spec.

? Log as deviation? [Y/n]
> Y

✓ Logged to deviations.md
✓ Task 4 complete  (3 remaining)
```

---

## Phase 3 — Review

### `/reqd:review mfa-rollout`

```
reqd review: mfa-rollout
─────────────────────────────────────────────

Spec capabilities:

  ✅  totp-verification    — implementation found
  ✅  recovery-codes       — implementation found
  ⚠️  admin-enforcement    — not found in middleware or auth paths

─────────────────────────────────────────────
Gaps detected: 1

  admin-enforcement
  Spec says: "2FA enforcement applies on next login for admins"
  Code scan: no enforcement found in admin middleware

─────────────────────────────────────────────
Deviations logged: 1
  Review deviations.md before archiving.

? Add a task for admin-enforcement gap? [Y/n]
> Y

✓ Task 9 added: [review gap] Enforce 2FA for admin role on next login

─────────────────────────────────────────────
Review complete.
  1 gap found  (1 task added)
  1 deviation logged
```

Drift caught before opening a PR. The revision history made it detectable — the spec had the specific constraint logged.

---

## Phase 4 — Ship

### `/reqd:archive mfa-rollout`

```
◆ Checking done gate...

  sign-off:  ✅ approved (@sarah, 2 revisions)
  tasks:     ✅ 9/9 complete

⚠ Deviations logged during development:
─────────────────────────────────────────────
Task 4 — 2026-04-10
Recovery code redemption invalidates all other codes.
Not in spec — implemented as standard security practice.
─────────────────────────────────────────────
Recommend PM acknowledgement before archiving.

? Continue with archive? (PM has been notified of deviations) [y/N]
> y

✓ PR description copied to clipboard

✓ mfa-rollout archived → reqd/changes/archive/2026-04-10-mfa-rollout/

  Sign-offs:   ✅ @sarah (2 revisions)
  Tasks:       9/9 complete
  Deviations:  1 logged

PR description copied to clipboard — ready to open your pull request.
```

---

## The PR Description (auto-generated)

```markdown
## Add TOTP-based 2FA with recovery codes

Ref: JPD-412

### What was built
Users can enable 2FA from account settings using any standard
authenticator app. Admin accounts have 2FA enforced on next login.
Recovery codes (8 per user, 90-day expiry) provide a fallback.

### What was NOT built
- SMS-based 2FA
- Forced enrollment for regular users

### PM sign-off
@sarah, 2026-04-10 (2 revisions)

### Deviations from spec
- Recovery code redemption invalidates all other codes (not in spec —
  implemented as standard security practice)
```

---

## What the Archive Contains

```
reqd/changes/archive/2026-04-10-mfa-rollout/
  .reqd.yaml          status: archived
  requirements.md     original PM ask (immutable)
  proposal.md         north star
  translation.md      what PM approved (revision 2)
  spec/
    design.md
    tasks.md          all 9 tasks checked
    capabilities/
      totp-verification.md
      recovery-codes.md
      admin-enforcement.md
  sign-offs/
    pm.md             revision 1 (rejected) + revision 2 (approved)
  deviations.md       1 deviation, acknowledged at archive
```

Six months later, anyone can open this directory and answer:
- What did PM ask for? → `requirements.md`
- What did we agree to build? → `translation.md` + `sign-offs/pm.md`
- Why did the spec change twice? → `sign-offs/pm.md` revision history
- What decisions weren't in the spec? → `deviations.md`
