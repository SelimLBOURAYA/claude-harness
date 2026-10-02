# Lot 22 — Skill friction

## lot-start
- `lot-start / A2` — step 4 says to read the quick start of `README.md`, but this
  repository's `README.md` has no such section (`Prerequisites`, `Installation`,
  `Update`…). Cost: one grep of the headings, nothing read.
- `lot-start / A6` — the branch was created with `--no-track`, not with the
  documented `git switch -c feat/lot-N-<slug> origin/develop`, which makes the
  branch track `develop` (already recorded in lot 21, `lot-start / A6`) and makes
  a bare `gh pr view` look for a pull request of head `develop`. This lot fixes
  the step (deliverable 3); applied here ahead of the fix. Cost: none.

## lot-test
- `lot-test / 1` — the installed copy (1.1.1) still says to diff against the local
  `develop`; this lot fixes the step (deliverable 2), so the diff was taken
  against the fetched `origin/develop` ahead of the promotion. Cost: none.
- `lot-test / 2` — `Stack = harness` has no branch in section 2 (backend or
  frontend specifics only), and the business-rule matrix families do not fit
  hooks, scripts and skill texts. The matrix was built from the lot's
  deliverables instead: one row per deliverable, each mapped to a fixture test or
  a skill-content assertion. Cost: nothing, but the skill is silent on this stack.
- `lot-test / 3.1` — `Coverage tool` is `none`: sections 3.1 (open the report) and
  3.2 (review the exclusions) have nothing to act on. Cost: none.
