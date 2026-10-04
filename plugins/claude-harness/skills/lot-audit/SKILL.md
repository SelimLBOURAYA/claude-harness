---
name: lot-audit
description: >-
  Audits a lot branch for security, performance and architecture before the PR
  is opened, fixes its findings, and writes the consolidated report
  docs/audits/lot-N.md. Use after lot-review, at the end of a lot, or when the
  user asks for an audit, a security review or an architecture review of lot
  work.
metadata:
  version: "3.0"
---

# Lot Audit — Security, Performance, Architecture

Audits the current lot branch before the PR, fixes what it finds, and writes one
consolidated report. A Critical finding left unfixed blocks the PR:
`lot-deliverables.yml` fails while the report carries an unresolved Critical row.

```
lot-test  →  lot-review  →  [lot-audit]  →  lot-ship
```

## Step 0 — The review happened first

`docs/audits/lot-N-review.md` must exist for the current lot. Missing → **stop**
and tell the user to run `lot-review` first.

## Step 0b — The audited repository is the session's repository

```bash
AUDIT_REPO=$(git rev-parse --show-toplevel)
git -C "$AUDIT_REPO" branch --show-current | grep -qE '^(feat|fix|chore)/lot-'
grep -qiE "(^|[^a-z])lot[ -]$N([^0-9]|$)" "$AUDIT_REPO/<Lots file>"
```

Both checks must pass (the match is case-insensitive: `## LOT 18`, `## Lot 18`
and `## lot 18` all occur). Otherwise **stop** and tell the user to reopen the
session in the audited repository: `Skill(security-review)` reviews the current
working directory and takes no repository argument. Every `git` command below
carries `-C "$AUDIT_REPO"`, and every path resolves inside it.

## Workflow

```
Task Progress:
- [ ] Step 0 — lot-review deliverable present
- [ ] Step 0b — the session runs in the audited repository
- [ ] Step 1 — Context (lot, diff, touched files)
- [ ] Step 2 — Security audit
- [ ] Step 3 — Performance audit
- [ ] Step 4 — Architecture audit
- [ ] Step 5 — Coverage exclusions review
- [ ] Step 6 — Migration hygiene
- [ ] Step 7 — Fix the findings
- [ ] Step 8 — Consolidated report
- [ ] Step 9 — Commit the deliverable
```

The skill ends at the last box. Steps 2 to 6 produce findings, never a
deliverable: whatever a step returns, the `security-review` report included, is
an input of step 7, never the audit's result, and never the end of the turn.

### Step 1 — Context

```bash
git -C "$AUDIT_REPO" fetch -q origin develop
rtk proxy git -C "$AUDIT_REPO" log --first-parent origin/develop..HEAD --oneline
git -C "$AUDIT_REPO" diff origin/develop...HEAD --stat
```

The diff is against the fetched `origin/develop`, never the local `develop`.
Read the lot's section in the `Lots file` for its specific risks (credentials,
authorisation, export, file paths, payment, migrations), then only the files the
lot touched and their direct dependencies.

### Step 2 — Security audit

```
Skill(security-review)
```

Give it the diff scope (branch changes vs `origin/develop`) and instructions
built from the repository's `CLAUDE.md`: stack, secrets handled, routes exposed,
the lot's specific risks. When the diff fits in this session's context, run its
discovery and false-positive phases **inline**, without sub-agents, and say so in
the report. Keep its findings for the Security table, then go on to step 3 in
the same turn.

If the skill is unavailable, use the manual checklist in
[checklists.md](checklists.md) and say so in the report.

### Step 3 — Performance audit

Review the diff against the **Performance** checklist in
[checklists.md](checklists.md).

### Step 4 — Architecture audit

Review the diff against the **Architecture** checklist in
[checklists.md](checklists.md), `CONVENTIONS.md` and the repository's `CLAUDE.md`.

### Step 5 — Coverage exclusions review

Read `Coverage exclusions` from the `Gate parameters`. An exclusion covering a
business package or class is a **Warning**, with its removal proposed and the
resulting real coverage stated.

### Step 6 — Migration hygiene

Only when `Migrations directory` is not `n/a`:

- Every migration file the lot touched is in status `A` (added) against
  `origin/develop` (`git -C "$AUDIT_REPO" diff --name-status origin/develop...HEAD`).
  A modified merged migration is **Critical**.
- Expand then contract (CODE-3).
- At least one integration test executes the new changesets on a real database.

### Step 7 — Fix the findings

Fix the findings in this step, without re-running `lot-review`:

1. Apply the fixes, inside the lot's diff and its direct dependencies.
2. `<Validation command>` green.
3. Commit them:

   ```
   fix(N): apply the lot audit findings
   ```

A finding that needs a decision (an authorization model, a deviation from the
lot's specification, a schema change) is not fixed by default: ask the owner, all
such findings in one batch, then apply the answers and commit as above. A
finding left unfixed stays in the report with its reason; an unfixed Critical
blocks the PR.

### Step 8 — Consolidated report

Write **`$AUDIT_REPO/docs/audits/lot-N.md`**, in English:

```markdown
# Lot Audit — Lot N — [branch name]

**Harness ref:** [version of the installed harness that ran this audit, see below]
**Scope:** N modified files | **Fix commit:** [short SHA, or "none needed"] | **Verdict:** Ready for PR / Blocked

## Summary
| Dimension    | Critical | Warning | Info |
|--------------|----------|---------|------|
| Security     |          |         |      |
| Performance  |          |         |      |
| Architecture |          |         |      |

## Security
| Severity | Location | Finding | Action |
|----------|----------|---------|--------|
| …        | `path:line` | …    | fixed in <sha> / owner decision: … / open: <reason> |

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

The **Harness ref** is the installed copy of the plugin that ran:

```bash
python3 <this skill's base directory>/../../hooks/plugin-currency.py --installed-version
```

Empty output (an agent that loads no plugin) → the version `main` declares:

```bash
git -C ~/ENV/projets/claude-harness fetch -q origin main
git -C ~/ENV/projets/claude-harness show origin/main:plugins/claude-harness/.claude-plugin/plugin.json | jq -r .version
```

| Severity | Meaning |
|---|---|
| **Critical** | Blocks the PR (security flaw, conventions violation, data-loss risk) |
| **Warning** | Fixed in this lot, or tracked explicitly |
| **Info** | Optional improvement |

A fixed row stays in its table, its Action saying how and where it was fixed:
the CI guard looks for the resolution, not for the row's absence.

**Recommended lot**: when a Critical cannot be fixed within the lot's scope, the
same Warning dimension recurs on consecutive lots, or a cross-cutting theme
appears (secrets, validation, entity exposure, CORS, authentication, export
injection, coverage fiction), add a **Recommended lot** section (reason, proposed
row, affected files). The `Lots file` changes only on the user's approval, in a
commit of its own.

### Step 9 — Commit the deliverable

1. `<Validation command>` green.
2. A new report enters the `## Project documents` census of `CLAUDE.md`, copied
   to `AGENTS.md` (DOC-1).
3. Commit the report and the census, nothing else (GATE-8):

   ```
   docs(N): add the lot audit report
   ```

4. Do not push: the push belongs to `lot-ship`.

## Rules

- Stay within the lot's diff and its direct dependencies.
- Empty diff → one sentence: nothing to audit.
- The `Lots file` changes only on the user's approval.
- History reads through `rtk proxy git log`; every repository read is scoped to
  `$AUDIT_REPO`.
