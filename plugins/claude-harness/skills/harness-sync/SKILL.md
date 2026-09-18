---
name: harness-sync
description: >-
  Detects and fixes drift between a repository's harness documentation and the
  reality of its code, settings and lots. Use after editing CLAUDE.md or a
  skill, when the stack, conventions or lot scope evolved, after a lot, or when
  the user asks to refresh, check or improve the harness.
metadata:
  version: "2.0"
---

# Harness Sync — Keep the harness honest

Detects **drift** between the harness documentation and the reality of the
repository, fixes it, and proposes improvements. Never touches application code.

## Managed files

| File | Rule |
|---|---|
| `CLAUDE.md` | Source of truth for project conventions, gate parameters and the census |
| `AGENTS.md` | **Byte-identical** mirror of `CLAUDE.md` |
| `CONVENTIONS.md` | **Byte-identical** to the harness master `claude-harness/CONVENTIONS.md` — never hand-edited, only re-copied |
| `Lots file` | Modified only with user approval (status column excepted) |
| `README.md` | Aligned with the real stack |
| `.claude/settings.json` | Marketplace and plugin declaration |
| `.claude/skills/*/SKILL.md` | **Project-specific** skills only; the generic ones come from the plugin |

## Workflow

```
Task Progress:
- [ ] Step 1 — Fact collection
- [ ] Step 2 — Invariant checks
- [ ] Step 3 — Drift report (before any write)
- [ ] Step 4 — Application after approval
- [ ] Step 5 — Verification
```

### Step 1 — Fact collection

Read the repository's reality, assuming nothing: the build file (versions,
dependencies), the real package or directory layout, the configuration and its
env vars, the CI workflows, the branch and `rtk proxy git log --first-parent`,
and the reports in `docs/audits/`.

### Step 2 — Invariant checks

Run each of these. Each failure is a drift row in the Step 3 report.

| # | Invariant | How |
|---|---|---|
| 1 | Mirror | `cmp CLAUDE.md AGENTS.md` silent |
| 2 | Conventions copy | `cmp CONVENTIONS.md ~/ENV/projets/claude-harness/CONVENTIONS.md` silent |
| 3 | Plugin declared **with the ref** | `.claude/settings.json` declares the `claude-harness` marketplace with `"ref": "main"`. **No ref is a drift**: the harness default branch is `develop`, so a refless declaration makes every unpromoted merge active here |
| 4 | Gate parameters complete | `## Gate parameters` present, every parameter of the harness `README.md` contract has a row, `n/a` where it does not apply — a missing row is a drift, `n/a` is not |
| 5 | Census ⇔ skills | Every `.claude/skills/*/SKILL.md`, every `docs/audits/*.md` and every managed file appears in `## Project documents` |
| 6 | No legacy `skill/` | The directory `skill/` does not exist (finding #1) |
| 7 | No sprint chaining | No "Sprint chaining", no "chain the next lot", no `sprint` skill anywhere. One lot, one PR, then stop (§2.9) |
| 8 | Gate order documented | The Skills table states `lot-test → lot-review → lot-audit → lot-ship`. An audit step documented without a review step before it is a drift |
| 9 | Review before audit | For each `docs/audits/lot-N.md`, a `docs/audits/lot-N-review.md` exists. A report without its review means `lot-review` was skipped |
| 10 | Lots file status table | The `Lots file` **starts** with a `\| Lot \| Branche \| Statut \|` table whose every status is one of ⬜ 🔄 ✅ ⏸️ ❄️ |
| 11 | Statuses match history | Cross-check each ✅ row against `rtk proxy git log --first-parent`. A lot marked ✅ whose section still says "PR to open", or whose branch was never merged, is a drift. Always `rtk proxy`: the rtk filter hides merge commits (P5-#14) |
| 12 | No dates in the lots file | No date and no "window" in the `Lots file` — the order of lots is committed, calendar dates are not |
| 13 | Memory freshness | Every `project_*` memory carries a `Verified: YYYY-MM-DD` line. Report any missing line, and any date older than **60 days** |
| 14 | Branch naming | Branches follow `feat/lot-N-slug`, `fix/…`, `chore/…`, `docs/…`; no `lot-XX-slug`, no branch from `main` |

### Step 3 — Drift report

Present this **before** any write:

```markdown
## Harness Sync — Report

**Drifts detected:** N

| # | Invariant | File(s) | Drift | Proposed fix |
|---|-----------|---------|-------|--------------|

**Improvements (optional):** [list or none]
```

Distinguish clearly:

- **Fixes** — factual drift, applied after approval.
- **Improvements** — make the harness work better, suggested, never imposed.

### Step 4 — Application

- Targeted edits, no wholesale rewrite.
- Every edit to `CLAUDE.md` replicated byte for byte in `AGENTS.md`.
- `CONVENTIONS.md` is **re-copied** from the harness master, never hand-edited.
- The `Lots file` is never modified without explicit approval (status excepted).
- No application code, migration or secret is touched.

### Step 5 — Verification

- Re-run every Step 2 check — all silent.
- `grep` the fixed occurrences: a version can appear in `CLAUDE.md`, `AGENTS.md`,
  `README.md` **and** a `SKILL.md`. Fix all of them.
- Every path referenced in any doc exists; every documented command runs.
- Recap the touched files and invite a `docs:` or `chore:` commit. Do not commit
  or push unrequested — that is `lot-ship`'s job.

## Improvements worth proposing

- **Clarity**: an ambiguous rule, a redundancy between files, a contradiction.
- **Concision**: a long section diluting the constraints that matter.
- **Coverage**: a convention actually followed in the code but undocumented.
- **Triggering**: a `SKILL.md` `description` too vague to fire at the right time.

## Rules

- Report drifts **before** fixing — no surprise writes.
- Never desynchronise `CLAUDE.md` and `AGENTS.md`.
- Never modify the `Lots file` without explicit approval.
- Do not touch application code, migrations or secrets.
- Nothing to fix → one sentence: harness up to date.
