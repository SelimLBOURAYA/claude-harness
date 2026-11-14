# Lot Review — Lot 37 — feat/lot-37-gate-cost

**Harness ref:** 2.10.0
**Model:** claude-opus-5-5
**Target:** local diff origin/develop...HEAD
**Reviewed at:** 83ab7d3
**Verdict:** Fixed

No PR is open yet; the review covers the local diff. Run under the autopilot
(`HARNESS_AUTOPILOT=1`).

## Findings
| # | Severity | Location | Finding | Outcome |
|---|----------|----------|---------|---------|
| 1 | Major | `tests/run.sh:42` | The suites now run as background jobs, which ignore SIGINT in a non-interactive shell, and no INT/TERM trap stops them: Ctrl-C or a killed gate leaves up to 24 suites writing into a deleted buffers directory | fixed in 6d9f0c9 (trap kills the suite pids, exit 130) |
| 2 | Major | `CONVENTIONS.md:75` | The CODE-4 trim (card budget) turned "ask the user to install it" into "install a missing one", which tells a deepseek session to install a plugin itself, against ASK-2 | fixed in 6d9f0c9 ("the user installs it"), card updated by hand |
| 3 | Major | `CONVENTIONS.md:110` | The LOT-7 trim dropped "the user runs" before `claude-profile claude`; the deepseek card carries LOT-7 but neither PROF-1 nor ASK-2, so it reads as an instruction to switch the profile | fixed in 6d9f0c9 ("the user's `claude-profile claude`"; "never a model's own claim" pays for it within the card budget) |
| 4 | Minor | `CONVENTIONS.md:96` | The GATE-7 trim "run by the autopilot when set" no longer names the parameter | fixed in 6d9f0c9 (`Integration command` restored) |
| 5 | Minor | `tests/run.sh:57` | An extra `.code` file and subshell per suite duplicate the status `wait <pid>` returns; a missing file turns into a fake FAIL | fixed in 6d9f0c9 (exit code from `wait`) |
| 6 | Minor | `autopilot.py:191` | `(TARGETED_TESTS.get(stack) or ("", ()))[1] or ()` is a roundabout fallback | fixed in e423dfd |
| 7 | Minor | `CONVENTIONS.md:13` | The LOT-1 trim dropped the sync commit title `docs: sync lots file status` | rejected: the `lot-start` skill hard-codes the commit command, and restoring it puts the card over its 4500-char budget |
| 8 | Minor | `CONVENTIONS.md:51,58` | GIT-1 lost "said to the user", GIT-5 lost its reason "No repository has branch protection" | rejected: minor (autopilot); both rules keep their imperative, OUT-0 covers telling the user, and the bytes are spent on findings 2 to 4 |
| 9 | Minor | `CONVENTIONS.md:70` | START-2 now says plain `git log` hides merge commits; it is the rtk rewrite that does | rejected: minor (autopilot); the hook rewrites every plain `git log`, so the instruction holds |
| 10 | Minor | `tests/run.sh:46` | Each suite's stderr is merged into its stdout buffer | rejected: by design, the buffered in-order output of deliverable 2 needs one stream per suite |
| 11 | Minor | `autopilot.py:856` | `--dry-run` prints the full system prompt on every step line | rejected: the lot's acceptance criterion asks `--dry-run` to show the command hint for each step, and `autopilot-dryrun.test.sh` asserts it |
| 12 | Minor | `docs/memory.md:41,69` | The conventions size (15124) and the card margin (18) went stale with findings 2 to 4 | fixed in 83ab7d3 (15158 bytes, 9-char margin) |

The `lot-test` commit (9831324) touches test files only and adds assertions;
none removed or loosened.

## Candidate lots
- The gate starts all 24 suites at once with no concurrency limit; fixed waits
  (`timeout 2` in `autopilot-watch.test.sh`, the 5 s barrier in
  `run-gate.test.sh`) may turn flaky on a slow 2-core CI runner. To watch on
  the lot's CI; a cap on parallel suites if it flakes.
- The deepseek card has 9 characters left of its budget and `CONVENTIONS.md`
  67 bytes of its cap: the next carded rule needs a budget decision (raise
  `CAP`, or drop a rule from the card) rather than another trim.
