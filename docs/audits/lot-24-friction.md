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

## lot-test
- `lot-test / 3.1` — `shellcheck` is not installed on this machine, so
  `./tests/run.sh` skips the shell lint of `workflows.test.sh` and reports green;
  the lint runs only in CI. The lot rewrote `lot-confirm.sh`, `session-context.sh`
  and several test scripts, and lot 23 already needed a shellcheck fix after its
  push. Cost: the shell changes reach the PR unlinted.

## lot-review
- `lot-review / 0` — the `SessionStart` stale-plugin warning came back, with the
  same cause as `lot-start / A1` (installed 1.2.0 identical to `plugins/` at
  `main`, shallow marketplace clone). The fix of this lot is active only after
  the promotion. Cost: four diagnostic commands before the review started.
- `lot-review / 4` — the installed skill (1.2.0) asks for a **Read at** field and
  a friction section in every case; the lot's own version drops both. The report
  follows the installed one, which the installed `lot-audit` reads next. Cost:
  none, an ambiguity until the promotion.
- `lot-review / 2` — `code-review` ran about 11 minutes, and an untracked
  `__pycache__/plugin-currency.cpython-312.pyc` appeared in
  `plugins/claude-harness/hooks/` during the run; removed by hand. Cost: one
  check.
