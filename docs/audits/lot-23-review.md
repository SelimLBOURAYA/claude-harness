# Lot Review — Lot 23 — feat/lot-23-sync-automerge

**Harness ref:** bc2f15b
**Model:** claude-opus-5-5
**Target:** local diff origin/develop...HEAD (no PR open)
**Read at:** 555b371
**Fix commit:** ca87666
**Reviewed at:** ca87666
**Verdict:** Fixed

## Findings
| # | Severity | Location | Finding | Outcome |
|---|----------|----------|---------|---------|
| 1 | major | `plugins/claude-harness/hooks/lotfile.py:261` | A sub-lot lock accepts only its own audit commit as evidence, but the scan read develop with `--first-parent`: under a merge-commit pull request, the audit commit sits on the second parent, so the lock was never dropped and writes stayed open on a landed lot. The lot's test only covered an audit commit made on develop itself | fixed in ca87666 — sub-lot locks scan every commit develop reaches, whole-lot locks keep `--first-parent`; merge-commit test case added (fails without the fix). A squash merge still erases the audit subject: the user re-confirms or removes the lock |
| 2 | major | `.github/scripts/sync-projects.sh:58` | `open_pr` did not filter on the base branch, and its result is now merged automatically: a `chore/sync-harness-files` pull request opened by hand against `main` under the token account would be picked up and merged into `main` | fixed in ca87666 — `--base "$base"`, asserted in `tests/sync-projects.test.sh` |
| 3 | minor | `.github/scripts/sync-projects.sh:63` | The "cannot read the token account" error was printed once at the top, even on a run with nothing to merge, and the project that then failed did not say which pull request was left open | fixed in ca87666 — the error is printed by `merge_pr`, per project, naming the pull request |
| 4 | minor | `plugins/claude-harness/hooks/plugin-currency.py:244` | `plugin_unchanged` needs main's tip in the marketplace clone: before a refresh it is absent, `git diff` exits 128 and a documents-only commit still warns, where deliverable 6 and the README said it raises nothing | owner decision 2026-10-03: limitation accepted, no fetch from the hook; README wording fixed in ca87666 (silent once the clone holds the commit; the refresh it asks for is what fetches it) |
| 5 | minor | `.github/scripts/sync-projects.sh:87` | `--merge` is fixed and retried three times: on a repository that disallows merge commits every attempt fails the same way | rejected: merge commit is arbitrage 3 of the lot, and the portfolio repositories allow it; the failure is loud (project failed, PR left open) |
| 6 | minor | `.github/scripts/sync-projects.sh:73` | The author and files checks read `gh pr view` right after the force-push, possibly still on the previous head, so the files check may validate another commit than the merged one | rejected: the three checks are the lot's specification; `--match-head-commit` pins the merged commit, which the script built from the synced files only, so a stale file list can only be another commit of the script's own |
| 7 | nit | `.github/workflows/ci.yml:93` | `plugin-version` also runs on push events, where `BASE_SHA` is empty: a `::warning::` on every push, and only the agreement of the three version fields is checked | rejected: the pull request event is the gate (every change reaches develop through one); the push run still checks the three fields agree, and the warning states the limit instead of a silent skip |
| 8 | nit | `plugins/claude-harness/skills/lot-audit/SKILL.md:51` | The awk filter of step 0 switches on any `## ` line, including one inside a fenced code block | rejected: no `CLAUDE.md` of the portfolio nor the template carries a `## ` line inside a fence; a fenced `## ` line ends the census skip early and only stops the audit (fail-safe); content could pass unreviewed only behind a fenced literal `## Project documents` line |

`./tests/run.sh`: 14/14 suites green after the fixes (the `workflows` shell lint
skipped, `shellcheck` not installed).

## Candidate lots
none
