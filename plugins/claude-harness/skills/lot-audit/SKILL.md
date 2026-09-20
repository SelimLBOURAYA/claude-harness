---
name: lot-audit
description: >-
  Audits a lot branch for security, performance and architecture before the PR
  is opened, and writes the consolidated report docs/audits/lot-N.md. Use after
  lot-review, at the end of a lot, or when the user asks for an audit, a
  security review or an architecture review of lot work.
metadata:
  version: "2.1"
---

# Lot Audit — Security, Performance, Architecture

Audits the **current lot branch** before the PR. One consolidated report. Every
**Critical** finding is fixed before the PR is opened — `lot-deliverables.yml`
fails the build while an unresolved Critical row remains in the report.

Gate position:

```
lot-test  →  lot-review  →  [lot-audit]  →  lot-ship
```

## Step 0 — The review must have happened first

`lot-audit` does **not** replace the code review. Check that
`docs/audits/lot-N-review.md` exists for the current lot and covers the current
head of the branch:

- File missing → **stop**. Tell the user to run `lot-review` first.
- File present but its recorded commit is behind `HEAD` → **stop**. Code landed
  after the review; re-run `lot-review`.

Auditing unreviewed code produces a report about the wrong version of the lot.

## Step 0b — The audited repository is the session's repository

Every command below reads a repository. Resolve **which** one, first, and refuse
to guess:

```bash
AUDIT_REPO=$(git rev-parse --show-toplevel)
git -C "$AUDIT_REPO" branch --show-current
```

`$AUDIT_REPO` must be the repository that holds the lot branch — the one whose
`CLAUDE.md`, `Lots file` and `docs/audits/` this audit is about. If the session
is running somewhere else (typically in the harness clone while the lot lives in
an adopted repository), **stop**. Tell the user to reopen the session in the
audited repository and re-run `lot-audit`.

There is no workaround. `Skill(security-review)` in step 2 reviews the pending
changes of the **current working directory** and takes no repository argument: a
session whose directory is not the audited repository produces a security step
about the wrong code, and says nothing about it. That is exactly what happened
to lots 7 to 13, whose security step audited the harness clone instead of the
adopted repository — an audit that ran, reported nothing, and was wrong.

Consequences for the rest of the skill:

- Every `git` invocation carries `-C "$AUDIT_REPO"`, so a mistaken directory
  fails loudly instead of describing another repository's diff.
- Every path (`CLAUDE.md`, the `Lots file`, `docs/audits/lot-N.md`) resolves
  **inside** `$AUDIT_REPO`, including the report written in step 7.
- The one deliberate exception is the harness ref of step 7, read from the
  harness clone with its own explicit `-C`.

## Prerequisites

1. Read `$AUDIT_REPO`'s `CLAUDE.md` / `AGENTS.md`, its `## Gate parameters`, and
   the active lot section in the `Lots file`.
2. Identify the lot from the branch name (`feat/lot-N-slug`) or from the context.
3. Scope the diff to the **branch changes** vs `develop`.

## Workflow

```
Task Progress:
- [ ] Step 0 — lot-review deliverable present and current
- [ ] Step 0b — the session runs in the audited repository
- [ ] Step 1 — Context (lot, diff, touched files)
- [ ] Step 2 — Security audit
- [ ] Step 3 — Performance audit
- [ ] Step 4 — Architecture audit
- [ ] Step 5 — Coverage exclusions review
- [ ] Step 6 — Migration hygiene
- [ ] Step 7 — Consolidated report
```

### Step 1 — Context

- `rtk proxy git -C "$AUDIT_REPO" log --first-parent develop..HEAD --oneline` —
  the lot's commits. Always `rtk proxy` for history: the rtk filter hides merge
  commits (P5-#14).
- `git -C "$AUDIT_REPO" diff develop...HEAD --stat` — the modified files.
- Identify the lot's specific risks from its section in the `Lots file`
  (credentials, authorisation, export, file paths, payment, migrations).
- Read only the files touched by the lot and their direct dependencies.

### Step 2 — Security audit

Invoke the harness-provided review skill:

```
Skill(security-review)
```

This replaces the `security-review` **subagent**, which does not exist (finding
#6): earlier versions of this skill launched a subagent type that silently
failed, so the security step was never actually performed.

It reviews the working directory, which step 0b established is `$AUDIT_REPO`.
Give it the diff scope (`branch changes vs develop`) and custom instructions
built from that repository's `CLAUDE.md`: stack, the secrets it handles, the
routes it exposes, and the lot's specific risks.

If the skill is unavailable, fall back to the manual checklist in
[checklists.md](checklists.md) and say so in the report — a skipped step is
recorded, never silently dropped.

### Step 3 — Performance audit

Direct diff review against the **Performance** checklist in
[checklists.md](checklists.md). No subagent.

### Step 4 — Architecture audit

Direct diff review against the **Architecture** checklist in
[checklists.md](checklists.md). No subagent. Check the lot's changes against
`CONVENTIONS.md` and against the repo's own `CLAUDE.md`.

### Step 5 — Coverage exclusions review

Read `Coverage exclusions` from the `Gate parameters` (finding #7). Any exclusion
covering a **business** package or class is a **Warning** in the report, with the
removal proposed and the resulting real coverage stated. A coverage number
produced by excluding the code that matters is not a measurement.

### Step 6 — Migration hygiene

Only when `Migrations directory` is not `n/a`:

- Every file of the migrations directory touched by the lot must be in status
  `A` (added) versus `origin/develop`
  (`git -C "$AUDIT_REPO" diff --name-status origin/develop...HEAD`). A modified merged migration is a
  **Critical** finding — it has already run on other environments.
- **Expand/contract** (§7 of `CONVENTIONS.md`, P5-#8): a migration that drops a
  column or table, renames, or adds a `NOT NULL` constraint must never ship in
  the same version as the code that stops using it. The contract step comes a
  version later, explicitly marked `contract`.
- Confirm that at least one integration test actually executes the new
  changesets against a real database.

### Step 7 — Consolidated report

Write the report to **`$AUDIT_REPO/docs/audits/lot-N.md`**, in English:

```markdown
# Lot Audit — Lot N — [branch name]

**Harness ref:** [short SHA of the claude-harness clone that ran this audit]
**Scope:** N modified files | **Verdict:** Ready for PR / Fix warnings / Blocked

## Summary
| Dimension    | Critical | Warning | Info |
|--------------|----------|---------|------|
| Security     |          |         |      |
| Performance  |          |         |      |
| Architecture |          |         |      |

## Security
| Severity | Location | Finding | Action |
|----------|----------|---------|--------|
| …        | `path:line` | …    | …      |

## Performance
| Severity | Location | Finding | Action |
|----------|----------|---------|--------|

## Architecture
| Severity | Location | Finding | Action |
|----------|----------|---------|--------|

## Coverage exclusions
| Exclusion | Business code? | Proposed action |
|-----------|----------------|-----------------|

## Migrations
[status A check, expand/contract verdict, or "n/a"]

## Lot-specific notes
[whatever this lot alone required]

## Recommended next steps
1. …
```

The **harness ref** line is mandatory: a report must say which version of the
harness produced it, otherwise a finding cannot be traced to the checklist that
raised it.

Get the value with:

```bash
rtk proxy git -C ~/ENV/projets/claude-harness rev-parse --short HEAD
```

**Severity levels**

| Level | Meaning |
|---|---|
| **Critical** | Blocks the PR (security flaw, conventions violation, data-loss risk) |
| **Warning** | Fix in this lot or track explicitly |
| **Info** | Optional improvement |

A Critical row stays in the table after being fixed, with its Action rewritten to
say how and where it was resolved — the guard looks for the resolution, not for
the row's absence.

## Lots file enrichment

After writing the report, look for cross-cutting patterns that justify a
dedicated lot. Propose one if **at least one** of these holds:

- A **Critical** finding cannot be fixed within the current lot's scope.
- **Warning** findings of the same dimension appear on **2 or more consecutive**
  lots.
- A cross-cutting theme appears: secrets, validation, entity exposure, CORS,
  authentication, export injection, coverage fiction.

Procedure: add a **Recommended lot** section at the end of the report (reason,
proposed lot row, affected files) and **wait for user approval before touching
the `Lots file`**.

## Rules

- Do not fix findings unless the user asks — report first. The fixes belong to
  `lot-review`, which ran before this step.
- Stay within the lot's diff and its direct dependencies.
- Empty diff → one sentence: nothing to audit.
- Never modify the `Lots file` without explicit approval (status column excepted).
- All history reads go through `rtk proxy git log` (P5-#14).
- Every repository read is scoped by `-C "$AUDIT_REPO"`; a step that cannot be
  scoped, `Skill(security-review)` included, requires the session to run in that
  repository (step 0b).
- Remind at the end: the `Validation command` must be green before the PR.

## Resources

- Detailed checklists: [checklists.md](checklists.md)
- Repo conventions and parameters: `CLAUDE.md` / `AGENTS.md`, `Lots file`
- Cross-cutting rules: `CONVENTIONS.md`
