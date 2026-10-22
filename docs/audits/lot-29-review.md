# Lot Review — Lot 29 — feat/lot-29-autopilot-confirm-handoff

**Harness ref:** 2.3.0
**Model:** Claude Opus 5.5 (`claude-opus-5-5`), autopilot run
**Target:** local diff origin/develop...HEAD
**Reviewed at:** a1bacd0
**Verdict:** Findings deferred

No PR open for the branch. The `lot-test` commit `a1bacd0` touches
`tests/autopilot.test.sh` only and removes no assertion (the fake `claude` now
reads `<step>.questions` for any step, which widens it). `docs/memory.md` matches
the code (5970 characters).

## Findings
| # | Severity | Location | Finding | Outcome |
|---|----------|----------|---------|---------|
| 1 | Minor | `plugins/claude-harness/autopilot/autopilot.py:375` | `CONFIRMATION.search` drops a real question that also carries the hand-off text | rejected: risk accepted by the lot 29 decisions table (ambiguities are asked in Step A5, before the hand-off) |
| 2 | Minor | `plugins/claude-harness/autopilot/autopilot.py:375` | A dropped hand-off naming another lot than `answer["lot"]` is not reported | rejected: minor (autopilot); the confirmation sent is built from the checked lot (branch, `--lot`), never from the question text |
| 3 | Minor | `README.md:294` | The Stop bullet still says a session listing questions is a `blocked` stop whatever its status, which the dropped hand-off now contradicts | deferred to a candidate lot: `README.md` is outside the lot's diff (LOT-5) |
| 4 | Minor | `plugins/claude-harness/autopilot/autopilot.py:379` | A hand-off given only in `reason`, with empty `questions`, still stops at `start` | rejected: the lot spec keeps a `blocked` without questions as a stop, locked by its test |
| 5 | Minor | `plugins/claude-harness/autopilot/autopilot.py:365` | Altitude: the answer is rewritten after the fact instead of changing `lot-start` Step A6 | rejected: the decisions table keeps `lot-start` `SKILL.md` unchanged |

## Candidate lots
- `README.md` autopilot **Stop** bullet: name the `lot-start confirm N`
  hand-off as the one question list that does not stop the run (finding 3).
  Documentation only; under the freeze it rides on the next harness lot.
