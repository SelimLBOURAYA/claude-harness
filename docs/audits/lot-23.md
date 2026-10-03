# Lot Audit — Lot 23 — feat/lot-23-sync-automerge

**Harness ref:** bc2f15b
**Scope:** 23 modified files (origin/develop...b5e5ac7) | **Verdict:** Ready for PR

## Summary
| Dimension    | Critical | Warning | Info |
|--------------|----------|---------|------|
| Security     | 0        | 0       | 2    |
| Performance  | 0        | 0       | 1    |
| Architecture | 0        | 1       | 2    |

`./tests/run.sh`: 14/14 suites green (the `workflows` shell lint is skipped,
`shellcheck` is not installed).

## Security
`Skill(security-review)` ran inline, without sub-agents: the diff (about 66 KB)
fits in the session, so discovery and the false-positive filter were done in the
same process. No finding reached the confidence threshold of 8.

| Severity | Location | Finding | Action |
|----------|----------|---------|--------|
| Info | `.github/scripts/sync-projects.sh:90` | The sync pull requests are now merged into the `develop` of the 8 projects with no human and no CI gate, so a compromise of the harness `main` or of `SYNC_TOKEN` propagates without a pause. Bounded by three conditions the script enforces and `tests/sync-projects.test.sh` covers: the token account's own pull request, nothing outside `synced_files`, `--match-head-commit` on the pushed SHA (which also closes the window between the checks and the merge). The arbitrage and its scope are written in `CONVENTIONS.md` §7 | Accepted, documented. Keep the token fine-grained to the 8 repositories (README) |
| Info | `.github/workflows/ci.yml` (`plugin-version` job) | Not verified: the workflow-level `permissions:` and `on:` blocks, and the content of `synced_files` in `projects.json` (does it carry any workflow file, which a merge would then ship with the `workflow` scope), were not read in this audit: the read was refused by the session's permission classifier. The diff shows neither a `pull_request_target` nor a secret in the new job, and `tests/workflows.test.sh` asserts `pull_request` on `develop` | To check by the owner before merging: `grep -n 'permissions' .github/workflows/ci.yml` and `jq .synced_files projects.json` |

## Performance
| Severity | Location | Finding | Action |
|----------|----------|---------|--------|
| Info | `.github/scripts/sync-projects.sh:93` | `merge_pr` retries three times, 5 s apart: up to 10 s per project, 80 s for 8 projects, on a path that only runs when a convention changes | None |

`lotfile.py` reads up to 200 commits without `--first-parent` for a sub-lot lock,
and `plugin-currency.py` adds one `git diff --quiet` under the hook timeout, only
when the installed SHA differs from main's tip. Both bounded.

## Architecture
| Severity | Location | Finding | Action |
|----------|----------|---------|--------|
| Warning | `plugins/claude-harness/skills/lot-audit/SKILL.md`, `tests/skills.test.sh` | These two files changed in `b5e5ac7`, after the lot review (**Reviewed at** `ca87666`), so `lot-audit` step 0 would stop on them. The owner waived the stop in the session ("lot-review a déjà été exécuté"); the change is two paragraphs of skill text and two `grep` assertions, no hook or script logic. This audit read them, but a review did not | Waived by the owner; recorded here and in the friction file. Re-run `lot-review` if the waiver is not wanted |
| Info | `.github/workflows/ci.yml:93` | On a `push` event `BASE_SHA` is empty: only the agreement of the three version fields is checked, with a `::warning::` saying so. The pull request event is the gate (already weighed and rejected in the lot review, finding 7) | None |
| Info | `CONVENTIONS.md` §7, `README.md` | The exception to "never auto-merge" and to "never merge a red PR" is stated once in §7 and pointed to from the red-CI rule; `tests/conventions.test.sh` asserts the three bounding conditions. The `CONVENTIONS.md` change propagates to the 8 projects through `sync-projects` itself | None |

Checked against `CONVENTIONS.md` and the repo's `CLAUDE.md`: the version check
moved to the one repository it concerns (`ci.yml`) and is asserted wired; the
three version fields move together (1.2.0); `CLAUDE.md` = `AGENTS.md`; the census
carries the lot's documents.

## Coverage exclusions
| Exclusion | Business code? | Proposed action |
|-----------|----------------|-----------------|
| none (`Coverage tool` is `none`) | n/a | n/a |

## Migrations
n/a (`Migrations directory` is `n/a`).

## Lot-specific notes
- Step 0 of this audit: the review is `docs/audits/lot-23-review.md`, **Reviewed
  at** `ca87666`; `b5e5ac7` landed after it (see the Architecture warning).
- Review findings 4 to 8 were rejected or accepted by the owner in the review;
  they are not re-raised here.

## Recommended next steps
1. Optionally check the two unverified points of the Security table
   (`permissions` of `ci.yml`, `synced_files` of `projects.json`).
2. `lot-ship`: push and open the PR to `develop`.
3. The `Validation command` (`./tests/run.sh`) must be green before the PR; it was
   at the time of this report.
