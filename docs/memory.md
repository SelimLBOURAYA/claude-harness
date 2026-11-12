# Project memory

> Working notes for the agent, not the truth: the code and git are. Check a
> note against the code before it guides a write, and fix in the current lot a
> note the code contradicts. The development session rewrites this file at its
> close (`lot-start` Step B3), never appending a lot journal; at most 6000
> characters (MEM-1).

## Code map

- `plugins/claude-harness/hooks/`: `git-guard.py` (git/gh rules, merge only by
  `lot-ship`), `lot-lock-guard.py` + `lot-confirm.sh` (write lock opened by the
  user's `lot-start confirm N`), `session-context.sh` (state, `CAP`/`TABLE_CAP`),
  `ponytail-context.sh` (CODE-6 text), `lotfile.py` (gate parameters, status
  table, lock, `profile`), `plugin-currency.py`, `mirror-sync.sh`.
- `plugins/claude-harness/skills/<name>/SKILL.md`; `lot-start/sync-status.py`
  maps develop merges to status rows.
- `CONVENTIONS.md`: master of the rules; `.github/scripts/deepseek-card.py`
  generates `rules/deepseek.json` from it, by rule ID.
- `plugins/claude-harness/autopilot/autopilot.py`: one lot, a `claude -p`
  session per step; `tests/autopilot.test.sh` fakes `claude`, `gh`, `notify-send`.
- `templates/project/`: skeleton for `bootstrap-project`; its
  `.claude/settings.json` holds the master permission rules (lot 33).
- `.github/workflows/`: reusable workflows; `sync-projects.yml` pushes the
  `synced_files` and the `permissions` key (`synced_permissions`) to the 8 repos.
- `tests/run.sh` runs every `tests/*.test.sh` (helpers in `tests/lib.sh`).

## Decisions

- Consumers run `main`; nothing reaches the 8 repos before the user promotes
  `develop` → `main`. Skills read `CONVENTIONS.md`, the plugin version and the
  memory template from `origin/main`, never the working tree (lot 24);
  `bootstrap-project` still copies `templates/project/` from it.
- Freeze since lot 24: a change needs a broken CI, a security flaw or a real
  incident; lots 26, 27, 30 and 33 are user-decided exceptions.
- Skills and docs cite a rule by its ID, never restate it (lot 24).
- `CONVENTIONS.md` stays within 15146 bytes (15000 + CODE-6, lot 33), English,
  no dated story; a new ID prefix goes in the citation regex of its test.
- Every lot bumps the plugin version in its own commit,
  `chore(N): bump the plugin to X.Y.Z`, in `plugin.json` and both fields of
  `.claude-plugin/marketplace.json`.
- Lot branches are created `--no-track`: one tracking `develop` sends a bare
  `git push` there (lot 22).
- `lot-test` writes test files only; the dev session writes the memory (lot 26).
- Autopilot (lots 27-29): the script checks each step itself, never trusts the
  model's status; `HARNESS_AUTOPILOT=1` turns a guard ask into a deny; allow
  and deny lists go per process; answers go back into the stopped session,
  never into the Lots file; the script confirms the lot, after its checks.
- Profile (lot 33): `lotfile.py profile` is deepseek when the host of
  `ANTHROPIC_BASE_URL` is not `api.anthropic.com`, which the desktop app sets.
  `lot-review` keeps `printenv` (no permission prompt) and cites it.
- Permission rules (lot 33), second layer behind the guard: Claude Code matches
  the command the `rtk` hook rewrote, so each rule exists bare and behind `rtk`
  and `rtk proxy`; none opens on `*`, which would deny a commit message quoting
  the command. Synced as one key: projects keep their own LSP plugins.
- `git-guard.py` sees through shell keywords and groupings; backticks, `eval`
  and a command name in a variable stay out by decision (lots 25, 33).
- Claude Code keeps at most 10,000 characters of a hook's context, no setting:
  `ponytail` has its own hook instead of a share of `CAP` (lot 33).

## Pitfalls

- The deepseek card (4500 characters) has a margin of 7, and
  `tests/deepseek-card.test.sh` adds 5 to OUT-1: shorten a carded rule before
  lengthening one. MEM-1 is off the card for this reason.
- The session runs the installed plugin copy, not the branch: a fix on the
  branch acts only after promotion and update.
- No local `shellcheck`: CI runs the workflows lint.
- `tests/run.sh` and `tests/lib.sh` unset `HARNESS_AUTOPILOT` and
  `ANTHROPIC_BASE_URL`; a suite that tests them sets them after `lib.sh` (lot 29).
- `claude plugin update --scope project` with no project install at this path
  updates another project's: Step A0 checks `installed_plugins.json` (lot 30)
  and runs verbatim (`PLUGIN_UPDATE` in the allowlist).
- Under auto mode, a Bash call the `rtk` hook rewrites (`grep`, `cat`, `git`)
  gets "no verdict" once: re-issue the rewritten command, or use Read (lot 33).
- `WebFetch` fails while the small model is a deepseek one: `curl` the `.md`
  pages of the Claude Code docs instead (lot 33).

## Open questions

- `lot-test` section 2 has no `Stack = harness` branch, and sections 3.1 and
  3.2 have nothing to act on when `Coverage tool` is `none` (friction 22-24).
- Tested only against the fake `claude`: `--answer` with `--resume`,
  `--disallowedTools`, and `SessionStart` in `claude -p`, which the first real
  run after promotion shows by the `ponytail` text in each step's log. A real
  run verified a slash prompt in `-p`, `structured_output`, `UserPromptSubmit`
  on `--resume`, and that a permission ask in `-p` is a deny: every command a
  step runs must be in `allowed_tools()`.
- The 8 projects' `CLAUDE.md` skill tables lack the `ponytail` row (lot 33).
