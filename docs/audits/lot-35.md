# Lot Audit — Lot 35 — feat/lot-35-headless-ship

**Harness ref:** 2.8.0
**Scope:** 14 modified files | **Fix commit:** none needed | **Verdict:** Ready for PR

Run under the autopilot (`HARNESS_AUTOPILOT=1`). The security review ran inline,
without sub-agents: the code diff (`autopilot.py`, the deepseek card, `CONVENTIONS.md`,
`lot-ship`, two test files) fits in the session's context.

## Summary
| Dimension    | Critical | Warning | Info |
|--------------|----------|---------|------|
| Security     | 0        | 0       | 1    |
| Performance  | 0        | 0       | 0    |
| Architecture | 0        | 1       | 1    |

## Security
| Severity | Location | Finding | Action |
|----------|----------|---------|--------|
| Info | `plugins/claude-harness/autopilot/autopilot.py:608` | `os.path.exists` is false on a dangling symlink, so a lock that is a broken symlink is left in place; the lock readers treat it as absent, and the removal runs only after `gh pr view` returned `MERGED`, so nothing is unlocked early | rejected: minor (autopilot) |

No secret, credential, network input or new command execution in the diff. The lock
removal is gated on the `MERGED` state of the branch's pull request and its failure is a
recorded `Stop`, not a traceback (`tests/autopilot.test.sh`, `unremovable` fixture).
CODE-7 narrows what a headless session runs; it widens no permission.

## Performance
| Severity | Location | Finding | Action |
|----------|----------|---------|--------|

No finding: one `os.remove` after the merge; the card stays under its 4500-byte budget
(`tests/deepseek-card.test.sh`).

## Architecture
| Severity | Location | Finding | Action |
|----------|----------|---------|--------|
| Warning | `plugins/claude-harness/autopilot/autopilot.py:520` | `gate_step` allows the lots file, `docs/memory.md` and `docs/audits/` but not `CLAUDE.md`/`AGENTS.md`, whose census line GATE-8 and DOC-1 require with every new gate report: every autopilot run whose lot does not already touch them stops after `lot-review` (`docs/audits/lot-35-friction.md`) | rejected: outside the lot 35 specification (LOT-5), not a Critical; Recommended lot below |
| Info | `plugins/claude-harness/skills/lot-ship/SKILL.md:127` | `lot-ship` still runs `$(...)` commands that CODE-7 now advises against | rejected: minor (autopilot); listed "Hors périmètre" in the lot 35 spec, already a candidate lot of the review |

`CONVENTIONS.md` and `rules/deepseek.json` agree (the generator test passes); the
shortened rules keep their meaning after the review fixes (4243315). Plugin and
marketplace versions bumped together to 2.9.0.

## Coverage exclusions
| Exclusion | Business code? | Proposed action |
|-----------|----------------|-----------------|
| (none) | n/a | none |

## Migrations
n/a (`Migrations directory` is `n/a`).

## Lot-specific notes
- `./tests/run.sh`: 16/16 suites green. shellcheck is not installed locally, so the shell
  lint did not run here; the CI runs it.
- The lot lock is removed by the autopilot only, after the merge; an interactive
  `lot-ship` still removes it itself.

## Recommended lot
- **Reason:** the autopilot's commit-scope guard stops every run after a successful
  `lot-review` when the lot did not otherwise touch `CLAUDE.md`/`AGENTS.md`, because the
  new report's census line lands there (GATE-8, DOC-1). It cost a manual resume on lot 35.
- **Proposed row:** `feat/lot-36-autopilot-census` | A – Harness | Autopilot : le garde
  de périmètre des étapes de gate accepte la ligne de recensement dans `CLAUDE.md` et
  `AGENTS.md` | claude-harness, les 8 repos (via `main`) | ⬜
- **Affected files:** `plugins/claude-harness/autopilot/autopilot.py` (`gate_step`),
  `tests/autopilot.test.sh`.

## Recommended next steps
1. `lot-ship`.
2. Owner decision on the recommended lot above (the lots file changes only on approval).
