# Lot Review — Lot 32 — feat/lot-32-autopilot-integration

**Harness ref:** 2.7.0
**Model:** claude-opus-5-5 (Opus 5.5), autopilot
**Target:** local diff origin/develop...HEAD
**Reviewed at:** 7361d35
**Verdict:** Fixed

No pull request open yet.

## Findings
| # | Severity | Location | Finding | Outcome |
|---|----------|----------|---------|---------|
| 1 | High | `plugins/claude-harness/autopilot/autopilot.py:543` | `step_audit` recorded `ship` as the resume step of a blocked audit, so on a frontend with an `Integration command` a `--resume` skipped `integration` and then stopped at `ship` | fixed in 7361d35: the next step comes from `steps(params)`; test `integrationaudit` |
| 2 | High | `plugins/claude-harness/autopilot/autopilot.py:589` | The stale-report stop at `ship` resumed at `ship`, so `--resume` could never get past it without a hand-written report | fixed in 7361d35: resumes at `integration`; test `integrationstale` updated |
| 3 | Medium | `plugins/claude-harness/autopilot/autopilot.py:571` | Ctrl-C during the command left its process group (backend, Playwright) running and wrote no state | fixed in 7361d35: the group is killed, `Stop` resumes at `integration`, as for a session |
| 4 | Medium | `plugins/claude-harness/autopilot/autopilot.py:561` | The command inherited the terminal's stdin outside the foreground group: a read hangs on SIGTTIN until the timeout | fixed in 7361d35: `stdin=DEVNULL` |
| 5 | Low | `plugins/claude-harness/autopilot/autopilot.py:351` | The log path in the session prompt was recomputed from today's date and could miss the file written before midnight | fixed in 7361d35: the path is recorded once in the run state |
| 6 | Low | `plugins/claude-harness/autopilot/autopilot.py:736` | `--resume` crashed with `ValueError` when the recorded step left the repo's sequence (command set back to `n/a`) | fixed in 7361d35: clean refusal |
| 7 | Low | `plugins/claude-harness/autopilot/autopilot.py:584` | `step_ship` repeated the condition held by `steps()` | fixed in 7361d35: `"integration" in steps(params)` |
| 8 | Low | `plugins/claude-harness/hooks/lotfile.py` | A command holding `\|` is cut at the pipe by the Markdown table parser | rejected: minor (autopilot); outside the lot's diff, a script in the row is the workaround |

Also checked, nothing to fix: `docs/memory.md` against the code (5985 characters, the 15225-byte and timeout-override notes match); the `test(32)` commit touches test files only and removes no assertion; `rules/deepseek.json` carries neither DOC-5 nor GATE-7.

## Candidate lots
none
