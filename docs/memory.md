# Project memory

> Working notes for the agent, not the truth: the code and git are. Check a
> note against the code before it guides a write, and fix in the current lot a
> note the code contradicts. The development session rewrites this file at its
> close (`lot-start` Step B3), never appending a lot journal; at most 6000
> characters (MEM-1).

## Code map

- `plugins/claude-harness/hooks/`: `git-guard.py` (git/gh rules, merge only by
  `lot-ship`), `lot-lock-guard.py` + `lot-confirm.sh` (write lock, user's
  `lot-start confirm N`), `session-context.sh` (state, `CAP`/`TABLE_CAP`),
  `ponytail-context.sh` (CODE-6), `lotfile.py` (parameters, table, lock,
  `profile`), `plugin-currency.py`, `mirror-sync.sh`.
- `plugins/claude-harness/skills/<name>/SKILL.md`; `lot-start/sync-status.py`
  maps develop merges to status rows.
- `CONVENTIONS.md`: master of the rules; `.github/scripts/deepseek-card.py`
  generates `rules/deepseek.json` from it, by rule ID.
- `plugins/claude-harness/autopilot/autopilot.py`: one lot, a `claude -p`
  session per step; `integration` runs the repo's command and its session
  writes the report (lot 32); `step_ship` removes the lot lock once the PR is
  `MERGED` (lot 35); gate checks accept census rows (lot 36); from a terminal
  it starts `autopilot/watch.py` and stops it with the run (lot 34).
- `autopilot/watch.py`: the live watch (lot 34), copied from the personal
  `autopilot-run` skill; reads the newest `~/.claude/autopilot/<project>/*.jsonl`.
- `tests/autopilot.test.sh` fakes `claude`, `gh`, `notify-send`.
- `templates/project/`: skeleton for `bootstrap-project`, holding the master
  permission rules in its `.claude/settings.json` (lot 33).
- `.github/workflows/`: reusable workflows; `sync-projects.yml` pushes the
  `synced_files` and the `permissions` key (`synced_permissions`) to the 8 repos.

## Decisions

- Consumers run `main`: nothing reaches the 8 repos before the user promotes
  `develop` → `main`. Skills read `CONVENTIONS.md`, the plugin version and the
  memory template from `origin/main` (lot 24); `bootstrap-project` copies
  `templates/project/` from it.
- Skills and docs cite a rule by ID, never restate it (lot 24).
- `CONVENTIONS.md` stays within 15225 bytes (15134 after lot 35), English,
  no dated story; a new ID prefix goes in the citation regex of its test.
- Every lot bumps the plugin version in its own commit,
  `chore(N): bump the plugin to X.Y.Z`, in `plugin.json` and both fields of
  `.claude-plugin/marketplace.json`.
- Lot branches are created `--no-track`: one tracking `develop` sends a bare
  `git push` there (lot 22).
- `lot-test` writes test files only; the dev session writes the memory (lot 26).
- Autopilot (lots 27-35): the script checks each step itself, never the model's
  status; `HARNESS_AUTOPILOT=1` denies what a guard would ask; allow and deny
  lists go per process; answers go into the stopped session, not the lots file.
- Watch (lot 34): started only when stdout is a terminal and the run is not
  `--dry-run`, in the same terminal; the personal `autopilot-run` skill keeps
  its own copy until the promotion.
- Integration (lot 32): the backend is local; `autopilot.py` runs the command
  itself, log under `~/.claude/autopilot/<projet>/`, 20 min at most, only for a
  frontend with a command other than `n/a`, between `audit` and `ship`; the
  report must be in `develop...HEAD`.
- Profile (lot 33): `lotfile.py profile` is deepseek when the host of
  `ANTHROPIC_BASE_URL` is not `api.anthropic.com`; `lot-review` cites
  `printenv`, no permission prompt.
- Permission rules (lot 33): second layer behind the guard; Claude Code matches
  the command `rtk` rewrote, so each rule exists bare and behind `rtk`/`rtk
  proxy`; none opens on `*`; projects keep their own LSP plugins.
- `git-guard.py` sees through shell keywords and groupings; backticks, `eval`
  and a command name in a variable stay out by decision (lots 25, 33).
- Claude Code caps a hook's context at 10,000 characters: `ponytail` has its
  own hook instead of a share of `CAP` (lot 33).

## Pitfalls

- The deepseek card has a 9-char margin (lot 35): a new carded rule needs
  ~180 chars cut elsewhere; the autopilot denies `python3 .github/scripts/*`,
  so edit it by hand and let `deepseek-card.test.sh` prove it.
- The session runs the installed plugin, not the branch: a fix acts only after
  promotion and update.
- No local `shellcheck`: CI runs the workflows lint.
- `tests/run.sh` and `tests/lib.sh` unset `HARNESS_AUTOPILOT` and
  `ANTHROPIC_BASE_URL`; a suite testing them sets them after `lib.sh` (lot 29).
- `claude plugin update --scope project` with no project install here updates
  another project's: Step A0 checks `installed_plugins.json` and runs it
  verbatim (`PLUGIN_UPDATE` in the allowlist) (lot 30).
- Under auto mode, a Bash call the `rtk` hook rewrites (`grep`, `cat`, `git`)
  gets "no verdict" once: re-issue it, or use Read (lot 33).
- `tests/autopilot.test.sh`: `fixture` takes the `Integration command` third;
  `AUTOPILOT_INTEGRATION_TIMEOUT` and `AUTOPILOT_STEP_TIMEOUT` override the
  ceilings for the timeout cases (lot 32).
- Importing `watch.py` in a test writes `__pycache__` beside it unless
  `sys.dont_write_bytecode` is set; the line truncates the model to 16 chars
  (lot 34).
- `WebFetch` fails while the small model is a deepseek one: `curl` the `.md`
  pages of the Claude Code docs instead (lot 33).

## Open questions

- Untested against a real `claude`: `--answer --resume`, `--disallowedTools`
  and `SessionStart` in `claude -p`. A permission ask in `-p` is a deny: a
  step's commands must be in `allowed_tools()` (lots 28-33).
- The watch's positive launch (stdout a terminal) has no automated test; the
  suite proves the redirected case (lot 34).
- The 8 projects' skill tables lack the `ponytail` row (lot 33).
- `Integration command` reaches `harness-invariants.yml` only in a later lot,
  once the 8 repos declare the row, not at this promotion (lot 32).
