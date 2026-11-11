# Lot Review — Lot 29 — feat/lot-29-autopilot-confirm-handoff

**Harness ref:** 2.3.0
**Model:** Claude Opus 5.5 (`claude-opus-5-5`), interactive session
**Target:** local diff origin/develop...HEAD
**Reviewed at:** cf022b2
**Verdict:** Fixed

Second review of the lot. The first one (autopilot run, at `a1bacd0`) predated
the amendment of 2026-10-22 (deliverables 4 to 6: `answer_hint`, the questions
of the "report not committed" stop, `tests/run.sh`); this one covers the whole
diff and replaces it. Its findings are kept below (rows 1 to 5). The owner
then asked for findings 1 to 3 and 9 to be fixed in this lot as well.

No PR open for the branch. The `lot-test` commits `a1bacd0` and `4f5f926` touch
`tests/autopilot.test.sh` and `tests/run-gate.test.sh` only and remove no
assertion. `docs/memory.md` matches the code (5986 characters).

## Findings
| # | Severity | Location | Finding | Outcome |
|---|----------|----------|---------|---------|
| 1 | Minor | `plugins/claude-harness/autopilot/autopilot.py:374` | `CONFIRMATION.search` drops any question that contains the hand-off text, e.g. a lot choice whose options are two confirmations | fixed in 7ab6b63 (a question is dropped only when all its confirmations name the answered lot; tests `confirmationchoice`, `confirmationotherlot`), owner decision recorded in cf022b2 |
| 2 | Minor | `plugins/claude-harness/autopilot/autopilot.py:374` | A dropped hand-off naming another lot than `answer["lot"]` is not reported | fixed in 7ab6b63 (same change: a hand-off for another lot stays a question and stops the run) |
| 3 | Minor | `README.md:292` | The autopilot Stop bullet says the last line lists the questions and that any question list is a `blocked` stop; since this lot they sit on numbered lines, and the hand-off list does not stop the run | fixed in 7ab6b63, owner approval to touch `README.md` |
| 4 | Minor | `plugins/claude-harness/autopilot/autopilot.py:379` | A hand-off given only in `reason`, with empty `questions`, still stops at `start` | rejected: the lot spec keeps a `blocked` without questions as a stop, locked by its test |
| 5 | Minor | `plugins/claude-harness/autopilot/autopilot.py:365` | Altitude: the answer is rewritten after the fact instead of changing `lot-start` Step A6 | rejected: the decisions table keeps the hand-off of `lot-start` `SKILL.md` unchanged |
| 6 | Major | `plugins/claude-harness/autopilot/autopilot.py:478` | The "report not committed" stop kept the model's raw status: an `ok` with questions was recorded `ok`, against the rule that questions are a block whatever the status | fixed in e9fb8e1 (status `blocked` when questions are present, test `auditokquestion`) |
| 7 | Minor | `plugins/claude-harness/autopilot/autopilot.py:549` | `answer_hint` indents continuation lines by a fixed 5 spaces, aligned only for questions 1 to 9 | fixed in e9fb8e1 (indent from the prefix width) |
| 8 | Minor | `plugins/claude-harness/autopilot/autopilot.py:547` | `answer_hint` builds the `Questions:` header twice, the second overwriting the first when there are no questions | fixed in e9fb8e1 |
| 9 | Minor | `tests/run.sh:13` | The unset of `HARNESS_AUTOPILOT` / `ANTHROPIC_BASE_URL` is in `run.sh` only: a suite run alone (GATE-1) still inherits them | fixed in 7ab6b63 (`tests/lib.sh` unsets them too, owner approval; test in `run-gate.test.sh`), memory in b761738 |
| 10 | Minor | `plugins/claude-harness/skills/lot-start/SKILL.md:128` | "Questions in French whatever the language of the session" vs OUT-1 "answer in the user's language" | rejected: the owner's choice in the amendment, and the owner writes French, so OUT-1 holds |
| 11 | Minor | `docs/audits/lot-29-review.md:4` | The committed review stopped at `a1bacd0`, before the amendment: deliverables 4 to 6 were never reviewed | fixed by this report |

## Candidate lots
none
