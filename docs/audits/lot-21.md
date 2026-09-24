# Lot Audit — Lot 21 — feat/lot-21-response-floor-friction

**Harness ref:** 0e2e98e
**Scope:** 24 modified files | **Verdict:** Fix warnings

## Summary
| Dimension    | Critical | Warning | Info |
|--------------|----------|---------|------|
| Security     | 0        | 0       | 0    |
| Performance  | 0        | 0       | 1    |
| Architecture | 0        | 3       | 2    |

Review prerequisite: `docs/audits/lot-21-review.md` records `Reviewed at: 9bad8e6`.
The only commits after it are the fix commit it lists (`798651e`) and the report
commit (`0e2e98e`), so no code went unreviewed.

Diff scope: `origin/develop...HEAD`. The local `develop` is behind and still lacks lot 20.

## Security

`Skill(security-review)` ran in this repository on `origin/develop...HEAD`. Its
instructions named the lot's risk areas: the friction step of `lot-deliverables.yml`
(input passed via `env` and checked against `^[0-9]+$`, lot numbers taken from the
branch name through `[0-9]+[a-z]?`), `ci.yml` now calling that workflow, and
`friction-digest.py` (read-only, git through an argv list with the path after `--`).
Nothing was held above the confidence threshold. The analysis ran inline, not in
the sub-tasks the procedure describes.

| Severity | Location | Finding | Action |
|----------|----------|---------|--------|
| — | — | No finding | — |

## Performance
| Severity | Location | Finding | Action |
|----------|----------|---------|--------|
| Info | `plugins/claude-harness/skills/harness-sync/friction-digest.py:79` | One `git log --diff-filter=A` per friction file. This is linear in the number of lots and runs on demand, not in a hook. | None |

## Architecture
| Severity | Location | Finding | Action |
|----------|----------|---------|--------|
| Warning | `.claude-plugin/marketplace.json:9`, `plugins/claude-harness/.claude-plugin/plugin.json` | `origin/develop` moved three commits past the branch point (`18a7850`, `9694511`, `51db877`) and bumped the plugin to `1.0.1`. The branch bumps it to `1.1.0`, so the two version fields conflict on merge. | Integrate `origin/develop` before the PR and keep `1.1.0`. This belongs to `lot-ship`. |
| Warning | `plugins/claude-harness/skills/harness-sync/SKILL.md:95` | The digest window is "lots holding an open or ineffective key, and at least the last 3". Arbitrage 2 of `dev-plan.md` says "every lot since the last run, and at least the last 3" (review finding 9). | User decision: amend arbitrage 2, or plan a lot that records the last `harness-sync` run. |
| Warning | `plugins/claude-harness/skills/harness-sync/friction-digest.py:151` | `ineffective` is measured from the merge on `develop`, not from the promotion to `main` that the consuming repos run (review finding 8). | Deferred to a candidate lot |
| Info | `plugins/claude-harness/skills/harness-sync/friction-digest.py:39` | The script imports `lotfile` from `../../hooks` through `sys.path`, the same coupling as `sync-status.py`. | None |
| Info | `docs/audits/lot-21-friction.md` | The `lot-start / A3` key (rebase merge not seen by `sync-status.py`) was fixed on `develop` by the chore commit `51db877`, not by a lot citing the key. The next digest will report it `open` although it is fixed. | Cite the key in the lot that records the fix, or in the lot 21 section, when the lots file is next updated. |

The completeness floor sits before the length rules in §15 and is declared to win over them.
`deepseek.json` carries it as `OUT-0`, ranked above `OUT-1`. `CONVENTIONS.md` is
still the master, the `CLAUDE.md` = `AGENTS.md` mirror holds, and every new
document is in the census.

## Coverage exclusions
| Exclusion | Business code? | Proposed action |
|-----------|----------------|-----------------|
| (none) | n/a | — |

## Migrations
n/a: there is no migrations directory.

## Lot-specific notes
- The friction guard is off by default (`friction_from_lot: ""`). The harness turns
  it on at `22`, so this lot's own friction file is written but not yet enforced by CI.
- The installed plugin (1.0.0) predates this lot. The friction sections were
  written from `CONVENTIONS.md` §13 rather than from the loaded skills.

## Recommended next steps
1. `lot-ship`: integrate `origin/develop` and resolve the version conflict to `1.1.0`, run `./tests/run.sh`, then push.
2. User: decide on the window of arbitrage 2 (review finding 9).
3. Candidate lot: measure a correction's effect from its promotion to `main`.
