# Project memory

> Working notes for the agent, not the truth: the code and git are. Check a
> note against the code before it guides a write, and fix in the current lot a
> note the code contradicts. The development session rewrites this file at its
> close (`lot-start` Step B3), never appending a lot journal; at most 6000
> characters (MEM-1).

## Code map

- `plugins/claude-harness/hooks/`: `git-guard.py` (git/gh deny rules, merge
  only by `lot-ship`), `lot-lock-guard.py` + `lot-confirm.sh` (write lock opened
  by the user's `lot-start confirm N`), `session-context.sh` (SessionStart
  state, `CAP`/`TABLE_CAP` budgets), `lotfile.py` (shared readers of gate
  parameters, status table, lock), `plugin-currency.py`, `mirror-sync.sh`.
- `plugins/claude-harness/skills/<name>/SKILL.md`: the gate skills;
  `lot-start/sync-status.py` maps develop merges to status rows.
- `CONVENTIONS.md`: master of the rules; `.github/scripts/deepseek-card.py`
  generates `plugins/claude-harness/rules/deepseek.json` from it, by rule ID.
- `templates/project/`: skeleton copied by `bootstrap-project`.
- `.github/workflows/`: reusable workflows; `sync-projects.yml` pushes the
  synced files of `projects.json` to the 8 repos.
- `tests/run.sh` runs every `tests/*.test.sh` (helpers in `tests/lib.sh`).

## Decisions

- Consumers run `main`; nothing reaches the 8 repos before the user promotes
  `develop` → `main`. Skills read `CONVENTIONS.md`, the plugin version and the
  memory template from `origin/main`, never the clone's working tree
  (harness-invariants compares against `main`). Lot 24. `bootstrap-project`
  still copies `templates/project/` from the working tree.
- Freeze since lot 24: a change needs a broken CI, a security flaw or a real
  incident; lots 26 and 27 are user-decided exceptions.
- Skills and docs cite a rule by its ID, never restate it; what a rule says is
  reviewed, not grepped (lot 24).
- `CONVENTIONS.md` stays within 15000 bytes, English, no dated story
  (`tests/conventions.test.sh`); a new ID prefix goes in its citation regex.
- Every lot bumps the plugin version in its own commit,
  `chore(N): bump the plugin to X.Y.Z`, in both `plugin.json` and
  `.claude-plugin/marketplace.json` (two fields there): `plugin-currency.py` compares the
  installed version with the one `main` declares.
- Lot branches are created `--no-track`: a branch tracking `develop` sends a
  bare `git push` there (lot 22).
- `lot-test` checks and completes the tests from a fresh session and writes
  test files only; the memory is written by the dev session, which alone knows
  the decisions (lot 26).

## Pitfalls

- The deepseek card budget (4500 rendered characters) is nearly full: lengthening
  a carded rule fails `tests/deepseek-card.test.sh`, and that test adds 5
  characters to OUT-1, so keep a margin of 10 or more. MEM-1 is off the card
  for this reason.
- The session runs the **installed** plugin copy, not the branch: a skill fixed
  on the branch still behaves the old way until promotion and update.
- `shellcheck` is not installed locally: the workflows suite skips its shell
  lint, CI runs it.
- `rtk` hides merge commits in `git log`: read history with `rtk proxy git log`.
- The lock guard sees `Edit`/`Write` only; a write through `Bash` bypasses it
  and is forbidden by `lot-start`.
- Popping a stash onto the lots file after the status sync conflicts on the
  table rows: resolve by hand, keep both.

## Open questions

- `lot-test` section 2 has no `Stack = harness` branch, and sections 3.1 and
  3.2 have nothing to act on when `Coverage tool` is `none` (friction 22-24).
- Lot 27 needs a deterministic marker of the development's close, now that the
  memory commit happens only when the file changes.
