# Lot Review — Lot 36 — feat/lot-36-census-guard-unfreeze

**Harness ref:** 2.9.0
**Model:** Claude Opus 5.5 (claude-opus-5-5), under the autopilot
**Target:** local diff origin/develop...HEAD (no PR open yet)
**Reviewed at:** 8940791
**Verdict:** Fixed

## Findings
| # | Severity | Location | Finding | Outcome |
|---|----------|----------|---------|---------|
| 1 | Major | `plugins/claude-harness/autopilot/autopilot.py:216` | `census_only` skipped every diff line starting with `---` or `+++`, not only the file header: removing a line whose text starts with `--` (a markdown `---` rule, `-- note`) next to a census row passed the guard | fixed in 8940791 (headers skipped only before the first `@@`; regression case `censusdashes` in `tests/autopilot.test.sh`) |
| 2 | Minor | `plugins/claude-harness/autopilot/autopilot.py:216` | `git diff` ran without `--no-color --no-ext-diff`: a user's `color.diff=always` or `diff.external` made every census-only commit stop the run, the false positive the lot removes | fixed in 8940791 |
| 3 | Minor | `plugins/claude-harness/autopilot/autopilot.py:230` | A census row appended to a `CLAUDE.md` with no final newline shows the last line removed and re-added, so the run stops | rejected: minor (autopilot); fails safe (a stop, never a bypass), and the repos' `CLAUDE.md` end with a newline |
| 4 | Minor | `plugins/claude-harness/autopilot/autopilot.py:524` | `check_test_files` accepts a census row for any `docs/audits/` file, not only the lot's friction report | rejected: the lot's specification (deliverable 1) accepts the census rows of any `docs/audits/` file for both checks |
| 5 | Minor | `tests/lot-start-sync.test.sh:123` | The real-plan case asserts `.lots_file` only, not the rows parsed | rejected: minor (autopilot); `sync-status.py` exits on a missing status table before printing, so the case does prove the table parses |

Project memory (`docs/memory.md`): checked against the code, no stale note; 5 KB, within MEM-1.
`lot-test` boundary: `bbdd01f` touches `tests/` only, additions only, no assertion weakened.

## Candidate lots
none
