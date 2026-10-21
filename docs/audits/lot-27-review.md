# Lot Review — Lot 27 — feat/lot-27-autopilot

**Harness ref:** 2.0.1
**Model:** Claude Opus 5.5 (`claude-opus-5-5`)
**Target:** local diff origin/develop...HEAD
**Reviewed at:** 2842a83
**Verdict:** Fixed

No pull request was open at review time. All the fixes are in
`plugins/claude-harness/autopilot/autopilot.py`, with `README.md`,
`tests/autopilot.test.sh` (3 new scenarios and one assertion pair) and one
arbitration row in `dev-plan.md`. They went into one `fix(27)` commit. The two
cleanups (#9, #10) sit in the same hunks as the fixes, so they were not split
into a separate `refactor(27)` commit.

## Findings
| # | Severity | Location | Finding | Outcome |
|---|----------|----------|---------|---------|
| 1 | High | `plugins/claude-harness/autopilot/autopilot.py:323` | A stop in the fix session recorded `resume=fix`, a step that is not in `SEQUENCE`, so `--resume` crashed with a `ValueError` | fixed in 2842a83: the run now resumes at `test` |
| 2 | High | `plugins/claude-harness/autopilot/autopilot.py:343` | `gate_step` called `expect_ok` before its checks, so a `blocked` review or audit resumed at the next step and its commits were never checked | fixed in 2842a83: the out-of-diff and report checks now run before the status decides |
| 3 | High | `plugins/claude-harness/autopilot/autopilot.py:347` | The out-of-diff check only covered commits titled `fix\|refactor(N)`, so any other commit type escaped it | fixed in 2842a83: every commit of the step is checked, against the lot diff, `docs/audits/`, the Lots file and `docs/memory.md` |
| 4 | High | `plugins/claude-harness/autopilot/autopilot.py:253` | The log is appended to and was read from its start, so a same-day rerun with no result event read back an earlier session's `ok` | fixed in 2842a83: `parse_output` reads from the session's starting offset |
| 5 | Medium | `plugins/claude-harness/autopilot/autopilot.py:319` | `before` was reset on each pass of the loop, so the commits of the first `lot-test` (the one that answered `failed`) escaped the test-files-only check | fixed in 2842a83: `check_test_files` now runs after each `lot-test` session |
| 6 | Medium | `plugins/claude-harness/autopilot/autopilot.py:248` | The session runs in its own process group, so Ctrl-C killed only the script, left the session running unattended and wrote no state | fixed in 2842a83: the process group is killed and the stop is recorded as `interrupted` |
| 7 | Medium | `plugins/claude-harness/autopilot/autopilot.py:185` | `Bash(python3 *)` in the allowlist allows `python3 -c` to run any git command out of `git-guard.py`'s sight | fixed in 2842a83, the owner's decision: limited to `python3 ~/.claude/plugins/cache/claude-harness/*`; README, test and `dev-plan.md` arbitration updated |
| 8 | Low | `plugins/claude-harness/autopilot/autopilot.py:338` | After a stop for an out-of-diff commit, `--resume` recomputes the lot diff from HEAD, so a commit left in place then passes | rejected, the owner's decision: the README asks for the reason to be settled before `--resume`, so a commit left in place counts as accepted |
| 9 | Low | `plugins/claude-harness/autopilot/autopilot.py:118` | `git()` re-implemented `lotfile.run_git`, without its timeout and `OSError` handling | fixed in 2842a83: `git = lotfile.run_git` |
| 10 | Low | `plugins/claude-harness/autopilot/autopilot.py:186` | The "Validation command is `n/a` or empty" parsing was written twice | fixed in 2842a83: one `validation_command(params)` helper |

## Candidate lots
- The profiles' own allowlist (`~/.claude/settings*.json`, outside the repo)
  grants `Bash(docker *)`. That is the same class of bypass as #7 for the
  unattended sessions (`docker run … git push --force`). It is user
  configuration, not lot code, so it is left to the owner.
