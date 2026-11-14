# Lot Audit — Lot 39 — feat/lot-39-gate-friction

**Harness ref:** 2.13.0
**Scope:** 14 modified files | **Fix commit:** none needed | **Verdict:** Ready for PR

Under the autopilot (`HARNESS_AUTOPILOT=1`).

## Summary
| Dimension    | Critical | Warning | Info |
|--------------|----------|---------|------|
| Security     | 0        | 0       | 0    |
| Performance  | 0        | 0       | 0    |
| Architecture | 0        | 0       | 1    |

## Security
| Severity | Location | Finding | Action |
|----------|----------|---------|--------|

`security-review` ran on `origin/develop...HEAD`, its discovery and
false-positive phases inline, without sub-agents (the diff fits in context).
No finding. Checked: the `commands_hint` sentence on `python3` is prompt text and
adds no permission (`allowed_tools()` untouched); the out-of-diff stop of
`gate_step` (`autopilot.py:627-638`) still stops the run and names the paths,
whatever the resume step, so no commit outside the lot's diff passes without the
owner seeing it; the step's questions now travel with the stop instead of being
dropped.

## Performance
| Severity | Location | Finding | Action |
|----------|----------|---------|--------|

No finding: `gate_step` adds one `committed()` call on the stop path only.

## Architecture
| Severity | Location | Finding | Action |
|----------|----------|---------|--------|
| Info | `plugins/claude-harness/autopilot/autopilot.py:631` | An out-of-diff commit stays on the branch after `--resume` and joins the next step's recomputed lot diff (already the review's candidate lot) | rejected: minor (autopilot); outside lot 39's specification, tracked as the review's candidate lot |

Each deliverable stays within the files the lot section names (deliverables 1
to 7); the version is 3.0.0 in `plugin.json` and both `marketplace.json`
fields; `CLAUDE.md` and `AGENTS.md` are identical.

## Coverage exclusions
| Exclusion | Business code? | Proposed action |
|-----------|----------------|-----------------|
| (none) | n/a | none |

## Migrations
n/a (`Migrations directory` is `n/a`).

## Lot-specific notes
- `docs/memory.md` was 4 493 characters at the development's close (`0078c37`),
  within the 4 500 criterion; the review's fix `8e056df` brought it to 4 512,
  within the 5 000 close limit and the 6 000 cap of MEM-1.
- The memory's autopilot note matches `gate_step` after the review's fix 1.
- The manual measurement criterion is recorded in the `feat(39)` commit body as
  not run: it needs the first autopilot run of a new lot after the promotion,
  which is the owner's.
- No fix, so no `Validation command` run in this step: the tree is the one
  `lot-review` left green, plus its report.

## Recommended next steps
1. `lot-ship`.
2. After the `develop` → `main` promotion, measure the first autopilot run of a
   new lot: calls spent on `docs/memory.md`, `python3` denials, no second
   `review` session.
