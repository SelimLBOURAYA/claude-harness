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
