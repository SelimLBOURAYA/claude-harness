# Lot Audit — Lot 36 — feat/lot-36-census-guard-unfreeze

**Harness ref:** 2.9.0
**Scope:** 13 modified files | **Fix commit:** none needed | **Verdict:** Ready for PR

## Summary
| Dimension    | Critical | Warning | Info |
|--------------|----------|---------|------|
| Security     | 0        | 0       | 1    |
| Performance  | 0        | 0       | 0    |
| Architecture | 0        | 0       | 0    |

## Security
`security-review` run inline, without sub-agents: the only code change is `census_only` in `autopilot.py` and its two call sites.

| Severity | Location | Finding | Action |
|----------|----------|---------|--------|
| Info | `plugins/claude-harness/autopilot/autopilot.py:153` | `CENSUS_ROW` matches the first cell only: the rest of an accepted row is free text added to `CLAUDE.md` and `AGENTS.md`. The guard limits a trusted session's scope and is no trust boundary; `git diff` runs from an argument list, `path` comes from a fixed tuple, `base` is a SHA, and an empty or failed diff returns false (the run stops) | rejected: minor (autopilot) |

## Performance
| Severity | Location | Finding | Action |
|----------|----------|---------|--------|
| — | — | `census_only` runs at most two `git diff -U0` per gate step, and only for `CLAUDE.md` and `AGENTS.md` outside the lot's diff; negligible | — |

## Architecture
| Severity | Location | Finding | Action |
|----------|----------|---------|--------|
| — | — | Change confined to the two existing guards (`check_test_files`, `gate_step`), one shared helper, no new dependency, plugin version bumped to 2.10.0, `CLAUDE.md` = `AGENTS.md` | — |

## Coverage exclusions
| Exclusion | Business code? | Proposed action |
|-----------|----------------|-----------------|
| (none) | n/a | none |

## Migrations
n/a (`Migrations directory` is `n/a`).

## Lot-specific notes
- The `lot-review` findings 1 and 2 (diff header parsing, `--no-color --no-ext-diff`) are fixed in 8940791. Both fixes are checked here: header lines are skipped before the first `@@` only.
- `dev-plan.md` drops from about 3,100 lines to under 600. The status table is kept; `tests/lot-start-sync.test.sh` parses the real plan.

## Recommended next steps
1. `lot-ship`.
