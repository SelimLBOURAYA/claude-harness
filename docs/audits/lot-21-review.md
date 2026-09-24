# Lot Review — Lot 21 — feat/lot-21-response-floor-friction

**Harness ref:** 9bad8e6
**Model:** claude-opus-5-5
**Target:** local diff origin/develop...HEAD (the local `develop` was behind and still carried lot 20)
**Reviewed at:** 9bad8e6
**Fix commit:** 798651e
**Verdict:** Fixed, 3 findings deferred

## Findings
| # | Severity | Location | Finding | Outcome |
|---|----------|----------|---------|---------|
| 1 | High | `plugins/claude-harness/skills/harness-sync/friction-digest.py:69` | `file_date` took the committer date of the file's last change: a rebase merge of the lot, or any later edit of an old friction file, moved its entries after the fix and reported the fix `ineffective`. | fixed in 798651e — author date of the commit that added the file; test 4c |
| 2 | Medium | `plugins/claude-harness/skills/harness-sync/friction-digest.py:147` | A key whose first fix proved ineffective stayed `ineffective`, and was drafted again, even once a second correction lot was planned. | fixed in 798651e — a pending lot wins; test 4b |
| 3 | Medium | `plugins/claude-harness/skills/harness-sync/friction-digest.py:147` | A cited lot marked ✅ without a `**Mergé** le` line (rebase merge, lot 19) stayed `planned` forever. | fixed in 798651e — classified `addressed`, no date to measure against; test 4 updated |
| 4 | Medium | `plugins/claude-harness/skills/lot-ship/SKILL.md:110` | The pre-push check tested only that each heading exists, while `lot-deliverables.yml` also fails a bare heading: the PR would go red after the push. | fixed in 798651e — same awk logic as the CI step |
| 5 | Low | `plugins/claude-harness/skills/harness-sync/friction-digest.py:102` | `missing_sections` ignored bare headings that CI rejects. | fixed in 798651e — a bare heading counts as missing; test 4d |
| 6 | Low | `plugins/claude-harness/skills/harness-sync/SKILL.md:107` | The doc let a rejected draft be cited "under the lot or note that set it aside", but only `## LOT` sections are parsed. | fixed in 798651e — doc states the `## LOT` requirement |
| 7 | Low | `plugins/claude-harness/skills/harness-sync/friction-digest.py:203` | Window guard written as a slice plus a per-element condition. | fixed in 798651e — plain `if` |
| 8 | Medium | `plugins/claude-harness/skills/harness-sync/friction-digest.py:151` | `ineffective` is measured against the merge on `develop`, but consuming repos run the fix only after the `develop` → `main` promotion and a plugin refresh: a friction between the two dates reports a fix that never ran. | deferred to a candidate lot — needs a promotion date, a design change |
| 9 | Medium | `plugins/claude-harness/skills/harness-sync/SKILL.md:95` | The window is "lots holding an open or ineffective key, and at least the last 3", not arbitrage 2's "every lot since the last run, and at least the last 3": `harness-sync` persists no record of its last run. | deferred — user decision: either amend arbitrage 2 to the window built, or plan a lot that records the last run |
| 10 | Low | `templates/ci-caller.yml:64` | The template passes `friction_from_lot` to `lot-deliverables.yml@main`, which does not declare it before the promotion. | rejected: the template and the workflow reach `main` in the same promotion, and `bootstrap-project` reads the template from the installed plugin, i.e. `main` |

## Inline comments posted
No PR open at review time: findings recorded here only.

## Candidate lots
- Measure a correction's effect from its promotion to `main`, not its merge on `develop` (finding 8).
- Record the last `harness-sync` run so the digest window matches arbitrage 2 (finding 9), if the user keeps that arbitrage.
