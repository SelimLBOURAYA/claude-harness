# Lot Review — Lot 35 — feat/lot-35-headless-ship

**Harness ref:** 2.8.0
**Model:** claude-opus-5-5
**Target:** local diff origin/develop...HEAD
**Reviewed at:** b9c9520
**Verdict:** Fixed

No pull request open at review time. Run under the autopilot (`HARNESS_AUTOPILOT=1`).

## Findings
| # | Severity | Location | Finding | Outcome |
|---|----------|----------|---------|---------|
| 1 | Major | `CONVENTIONS.md:105` (LOT-7) | The shortened LOT-7 dropped "the user", so `claude-profile claude` read as a step the agent runs, against PROF-1 and ASK-2 | fixed in 4243315 |
| 2 | Major | `CONVENTIONS.md:31` (CODE-1) | "absolute path" shortened to "path", which forbids every hard-coded relative path: a change of meaning outside the lot's spec | fixed in 4243315 ("absolute" restored; GATE-1 and CODE-4 trimmed without changing their meaning to keep the card at 4491/4500) |
| 3 | Minor | `docs/memory.md:39` | The close deleted the still-valid lot 24 decision "cite a rule by ID, never restate it", which the lot did not touch (MEM-1); the margin and byte figures went stale after fixes 1-2 | fixed in b9c9520 |
| 4 | Minor | `plugins/claude-harness/skills/lot-ship/SKILL.md:127` | `lot-ship` still uses `$(...)` (`--match-head-commit`, lock `rm`), which CODE-7 now advises against | rejected: listed under "Hors périmètre" in the lot 35 spec; candidate lot below |
| 5 | Minor | `plugins/claude-harness/autopilot/autopilot.py:615` | A failed lock removal resumes at `ship`, which reruns the `lot-ship` session on a merged PR | rejected: the lock-present stop resumed at `ship` the same way before lot 35; the failure requires a lock that is not a regular file |
| 6 | Minor | `tests/autopilot.test.sh:137` | The default fixture's fake `ship.sh` still removes the lock itself | rejected: minor (autopilot); the `locked` fixture already fails if `step_ship` stops removing the lock |

The `lot-test` commit (8161bde) touches test files only and adds assertions without loosening any.

## Candidate lots
- Remove the remaining `$(...)` from the skills' commands (`lot-ship` `--match-head-commit`, the lock `rm`), so they follow CODE-7 in headless sessions.
