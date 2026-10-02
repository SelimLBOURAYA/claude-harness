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
