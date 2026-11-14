# Lot Review — Lot 39 — feat/lot-39-gate-friction

**Harness ref:** 2.13.0
**Model:** claude-opus-5-5
**Target:** local diff origin/develop...HEAD
**Reviewed at:** 8e056df
**Verdict:** Fixed

No pull request is open for the branch. Under the autopilot (`HARNESS_AUTOPILOT=1`).

## Findings
| # | Severity | Location | Finding | Outcome |
|---|----------|----------|---------|---------|
| 1 | High | `plugins/claude-harness/autopilot/autopilot.py:631` | The out-of-diff stop resumed at the following step whenever the report was committed, even when the step ended `failed`: a failed review was skipped | fixed in 4d8d4d5 |
| 2 | High | `plugins/claude-harness/autopilot/autopilot.py:632` | The out-of-diff `Stop` dropped the step's questions, so a blocked review's Exception (the new missing-deliverable rule) was skipped on resume without the owner ever seeing it | fixed in 4d8d4d5 |
| 3 | Medium | `plugins/claude-harness/autopilot/autopilot.py:630` | The comment claimed the replayed step "checks the commit"; on resume the out-of-diff file is already in the recomputed lot diff | fixed in 4d8d4d5 (comment states the stop is the one check, the owner reverts) |
| 4 | Medium | `plugins/claude-harness/skills/lot-review/SKILL.md:93` | "A file the lot's section names" also caught files only cited for context (lot 39's own section cites `CLAUDE.md`), blocking the autopilot for nothing | fixed in 4d8d4d5 |
| 5 | Medium | `plugins/claude-harness/skills/lot-ship/SKILL.md:79` | Section 3 dropped "when the heading carries a status" and had no fallback when the hook prints no `Current lot section` range | fixed in 4d8d4d5 |
| 6 | Medium | `plugins/claude-harness/skills/lot-ship/SKILL.md:121` | "the body of the `feat(N)` commit" could resolve to lot-ship's own section-2 commit, which has no body | fixed in 4d8d4d5 |
| 7 | Medium | `tests/autopilot-gates.test.sh:38` | No case covered a failed step with its report committed plus an out-of-diff commit | fixed in 4d8d4d5 (`outsidefailed` case) |
| 8 | Low | `tests/skills.test.sh:162` | The `manual verification` loop overlaps the b2 and ship4 assertions | rejected: minor (autopilot); the loop is the spec's test (deliverable 6), kept |
| 9 | Low | `plugins/claude-harness/skills/lot-review/SKILL.md:204` | The missing-deliverable rule was stated three times, one copy already drifting | fixed in 4d8d4d5 (third copy removed, a maintainability fix) |
| 10 | Low | `docs/memory.md:18` | The autopilot note no longer matched `gate_step` after fix 1, and its line overran the wrap | fixed in 8e056df |
| 11 | Low | `docs/memory.md` | The trim dropped the 10 000-character hook context cap, the reason `ponytail` has its own hook | rejected: minor (autopilot); the trim is the lot's deliverable 1, and the reason is in the header of `hooks/ponytail-context.sh` |

`lot-test` boundary: `2c0edd4` touches `tests/autopilot.test.sh` and `tests/skills.test.sh` only, additions only. `docs/memory.md`: 4 512 characters, under the 5 000 close limit and the 6 000 cap.

## Candidate lots
- An out-of-diff commit stays on the branch after a plain `--resume` and joins the next step's recomputed `lot_diff`, so it is never checked again: the autopilot could pin the lot diff at the step's start, or refuse to resume until the commit is reverted. Out of lot 39's specification.
