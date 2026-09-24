# Lot 21 — Skill friction

## lot-start
- `lot-start / A3` — `sync-status.py` maps a lot only through a merge commit, so
  lot 20, merged by rebase (PR #35, `f06b364`..`a3df13d`), was not seen: the row
  stayed 🔄 with no stop raised, and `in_progress: ["20"]` read as an open lot.
  Cost: a check of the PR by hand, one question to the user, the row fixed by
  hand in the sync commit.
- `lot-start / A4` — the candidate's section existed only on the planning branch,
  whose PR (#39) was still open: branching from `origin/develop` would have
  produced a lot branch without its own specification. The skill says nothing
  about a candidate planned but not merged. Cost: one round trip to the user,
  who merged #39 before the branch was created.
- `lot-start / A6` — `git switch -c feat/lot-N-<slug> origin/develop` makes the
  new branch track `origin/develop`; a bare `git push` from it targets
  `develop`. `lot-ship` pushes with an explicit `-u origin <branch>`, so nothing
  went wrong, but the tracking is wrong from the first commit.
- `lot-start / B2` — the step that opens this file did not exist yet when lot 21
  was confirmed (this lot adds it): the section was written after the
  development commits instead of right after the sync commit.

## lot-test
- `lot-test / 2` — the skill selects its rules by `Stack`, with a backend and a
  frontend branch only; `Stack = harness` (shell and Python suites, fixture
  repositories, workflow steps extracted and executed) has no branch, so the
  matrix was built from the lot's criteria alone.
- `lot-test / 3.1` — `Coverage tool` is `none` and the threshold `n/a`: the
  « open the coverage report and look at it » step has nothing to open, and the
  skill does not say what stands in for it on an uninstrumented stack.
- `lot-test / 5` — the installed plugin (1.0.0) predates this lot, so the loaded
  skill had no friction step; the section was written from the lot's own
  `SKILL.md`. Inherent to a lot that changes the gate it runs under.

## lot-review
- `lot-review / 1` — the target `develop...HEAD` read the local `develop`, which
  was behind `origin/develop` and still lacked lot 20: the diff showed 39 files
  instead of 23. The skill never fetches nor names the remote branch. Cost: one
  wrong diff read, the target switched to `origin/develop...HEAD` by hand.
- `lot-review / 2` — no PR is open before `lot-ship`, so `--comment` has nothing
  to post to on every lot that follows the gate order; only `--fix` ran.
- `lot-review / 5` — the installed plugin (1.0.0) predates this lot, so the
  loaded skill has no friction step; this section was written from
  `CONVENTIONS.md` §13.

## lot-audit
- `lot-audit / 0` — the review records `Reviewed at` before its own fix commit,
  so `HEAD` is always ahead of it; the step says "behind HEAD → stop" without
  exempting the review's fix and report commits. Resolved by the lot 20
  precedent, not by the skill text.
- `lot-audit / 1` — the step diffs against the local `develop`, which was stale;
  `origin/develop` had to be used by hand, as in `lot-review / 1`.
- `lot-audit / 2` — `security-review` asks for sub-tasks per finding; with a
  small, fully read surface the analysis ran inline, a deviation the skill does
  not anticipate.
