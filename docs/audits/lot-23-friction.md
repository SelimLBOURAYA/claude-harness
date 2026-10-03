# Lot 23 — Skill friction

## lot-start
- `lot-start / A2` — step 4 still points at a quick start section that this
  repository's `README.md` does not have (already recorded in lot 22). Cost: one
  grep of the headings.
- `lot-start / A3` — in a worktree-isolated background session, the rtk rewrite
  of every `git` call (`rtk git …`, `rtk proxy git …`) is refused by Claude Code's
  isolation guard, which cannot read what `rtk` runs. Every git call went through
  `/usr/bin/git`, which the rtk hook does not rewrite. Already met in lot 22
  (`lot-ship / 2`); the previous session of this lot stopped on it instead.
  Cost: one aborted session, a dozen refused commands.
- `lot-start / A6` — the plugin was reinstalled during the session (the installed
  copy was stuck at 30b4930 under an unchanged version, the subject of this lot).
  The hooks run from the refreshed files, but the skill text is the one loaded
  at session start, so this run followed the pre-lot-22 A6 without `--no-track`:
  the branch tracked `origin/develop`, and the upstream was unset by hand. Cost:
  one extra command, and a gate skill text that silently lags behind its hooks.

## lot-test
- `lot-test / 1` — the same stale skill text: the loaded copy says to diff
  against `develop`, the installed file (lot 22) against the fetched
  `origin/develop`. The installed file was read and followed. Cost: one grep.
- `lot-test / 2` — `Stack = harness` still has no branch in section 2 (already
  recorded in lot 22); the matrix was built per deliverable. Cost: none.
- `lot-test / 3.1` — `Coverage tool` is `none`: 3.1 and 3.2 have nothing to act
  on. Cost: none.

## lot-review
- `lot-review / 1` — the snippet's `git -C "$REVIEW_REPO" …` and `rtk proxy git
  -C …` forms are refused by the worktree isolation guard (same cause as
  `lot-start / A3`); every call went through a plain `/usr/bin/git` from the
  worktree. The worktree is also shallow, so `origin/develop` showed one commit
  and the merge style of develop could not be read from history. Cost: four
  refused commands.
- `lot-review / 2` — `code-review --fix` warned that its `lotfile.py` fix would
  trip `lot-audit` step 0 as "code after the review"; it does not, the fix commit
  comes before **Reviewed at**. Cost: one check, a misleading caution.
- `lot-review / 3` — the `workflows` suite skips its shell lint when `shellcheck`
  is not installed, so the edited `sync-projects.sh` was not linted locally; only
  CI lints it. Cost: none, a check that did not run.

## lot-audit
- `lot-audit / 2` — `security-review` returns a complete-looking report and the
  step did not say it was an input of step 7: the first run ended its turn on
  it, with no performance or architecture audit, no report and no commit. Cost:
  the audit asked a second time. Fixed in this lot: the checklist and step 2 now
  say that steps 2 to 6 produce findings, never a deliverable.
- `lot-audit / 0` — the review (`Reviewed at` `ca87666`) pre-dates `b5e5ac7`,
  which edits `lot-audit/SKILL.md` and its test: the step says stop and re-run
  `lot-review`. A fix to the skill under audit, made after the review, always
  trips it. Cost: one stopped run and one question; waived by the owner.
- `lot-audit / 0b` — `git fetch`, `git diff`, `git log` were refused by the
  worktree isolation guard (the rtk rewrite, same cause as `lot-start / A3`); the
  skill's snippets name `git -C "$AUDIT_REPO"` and `rtk proxy git`, both refused.
  Cost: one stopped run; `exclude_commands = ["git"]` was added to the rtk config
  for the session.
- `lot-audit / 2` — the permission classifier denied one read command batching
  `ci.yml`, `projects.json` and `dev-plan.md` ("Self-Modification"), so those
  three were not read and are listed as unverified in the report. Cost: a partial
  step 2 and step 4.

## lot-ship
- `lot-ship / 2` – the snippets name the plain and the rtk-wrapped VCS calls, and compound
  shell batches mentioning it; the worktree isolation guard refuses them (same
  cause as `lot-start / A3`). Every call went through `/usr/bin/git`, one simple
  command at a time. Cost: four refused batches.
