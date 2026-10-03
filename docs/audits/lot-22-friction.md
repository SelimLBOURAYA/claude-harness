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

## lot-review
- `lot-review / 2` — the installed copy (1.1.1) says `--comment --fix` with no
  target. No PR existed, so `--comment` had nothing to do (this lot removes it),
  and the branch has no upstream since it was created `--no-track`: a targetless
  `code-review` would have diffed against `main`. The branch and
  `origin/develop` were named explicitly; the review itself found the same gap in
  the lot's new text (finding 2). Cost: none here, a wrong base otherwise.
- `lot-review / 3` — two fixes were cleanups (finding 5's duplicate python calls,
  finding 8) in the same hunks as defects; the skill asks to split `fix` and
  `refactor` commits, which would have meant splitting hunks. Kept in one `fix`
  commit. Cost: a judgement call the skill does not settle.
- `lot-review / 4` — the installed template's **Harness ref** is the clone's
  `HEAD`, which here is the lot branch itself; the installed copy has no
  `--installed-sha`, so the lot's own `plugin-currency.py --installed-sha
  --plugin-root <cache>/1.1.1` gave 30b4930. Its single **Reviewed at** field was
  replaced by this lot's **Read at** / **Reviewed at** pair, so that the audit of
  this lot reads the fields its new step 0 expects. Cost: two extra commands.

## lot-audit
- `lot-audit / 0` — the installed copy (1.1.1) stops when the review's recorded
  commit is behind `HEAD`, which the review report's own commit always makes
  true: the step can never pass as written. This lot fixes it (deliverable 7);
  step 0 was read as the lot's version, which accepted d0ab2e5 (docs and census
  only). Cost: none, but a literal reading blocks every lot.
- `lot-audit / 2` — the installed copy invokes `Skill(security-review)`, whose
  prompt demands sub-agents; the lot's deliverable 8 (inline phases) was applied
  ahead of the promotion. Cost: none.
- `lot-audit / 7` — the audit was finished by a forked session; Claude Code's
  background isolation refused writes to the shared checkout, so the report was
  written in a detached worktree (`.claude/worktrees/lot-22-audit`) and brought
  back to the lot branch by fast-forward. The skill does not foresee a session
  that cannot write in `$AUDIT_REPO`. Cost: one worktree, one extra merge.
