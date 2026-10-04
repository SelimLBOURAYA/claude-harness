# Lot 24 — Skill friction

## lot-start
- `lot-start / A1` — before the skill ran, the `SessionStart` hook printed the
  stale-plugin warning (installed 1.2.0 `caa6c8c`, `main` at `98cddbd`) although
  the installed copy was byte-identical to `plugins/` at `main`: the only commit
  in between was the lot 24 plan. The lot 23 content check, `plugin_unchanged`,
  runs `git diff <installed> <tip> -- plugins` in the marketplace clone, which
  Claude Code keeps shallow (one commit), so the installed SHA is unknown there
  and the check falls back to the warning on any commit to `main`. Cost: one
  stopped turn, three diagnostic commands, and the user's override of the stop.
  Fixed in this lot: the check compares versions only.
- `lot-start / A2` — step 4 still points at a quick start section that this
  repository's `README.md` does not have (C13, fixed in this lot). Cost: one grep
  of the headings.
