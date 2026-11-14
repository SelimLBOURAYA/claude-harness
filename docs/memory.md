# Project memory

> Working notes for the agent, not the truth: the code and git are. Check a
> note against the code before it guides a write, and fix in the current lot a
> note the code contradicts. The development session rewrites this file at its
> close (`lot-start` Step B3), never appending a lot journal; at most 6000
> characters (MEM-1).

## Code map

- `plugins/claude-harness/hooks/`: `git-guard.py` (git/gh rules, merge only by
  `lot-ship`), `lot-lock-guard.py` + `lot-confirm.sh` (write lock),
  `session-context.sh` (state, `CAP`/`TABLE_CAP`), `ponytail-context.sh`
  (CODE-6), `lotfile.py` (parameters, table, lock, `profile`),
  `plugin-currency.py`, `mirror-sync.sh`.
- `plugins/claude-harness/skills/<name>/SKILL.md`; `lot-start/sync-status.py`
  maps develop merges to status rows; `.github/scripts/deepseek-card.py`
  generates `rules/deepseek.json` from `CONVENTIONS.md`, by rule ID.
- `autopilot/autopilot.py`: one lot, a `claude -p` session per step;
  `integration` runs the repo's command and its session writes the report (lot
  32); `step_ship` removes the lot lock once the PR is `MERGED` (lot 35); gate
  checks accept census rows (lot 36); targeted test entries and the command
  hint come from `TARGETED_TESTS` (lot 37); `watch.py` starts from a terminal
  (lot 34).
- `autopilot/watch.py`: reads the newest `~/.claude/autopilot/<project>/*.jsonl`
  written since the run's start, complete lines only (lot 34).
- `tests/run.sh` runs every suite at once, buffers each output, prints them in
  file order (lot 37); `tests/autopilot-lib.sh` holds the fakes, the `fixture`
  and the helpers of the nine `tests/autopilot-*.test.sh`.
- `templates/project/`: skeleton for `bootstrap-project`, with the master
  permission rules in its `.claude/settings.json` (lot 33).
- `.github/workflows/`: reusable workflows; `sync-projects.yml` pushes
  `synced_files` and `synced_permissions` to the 8 repos.

## Decisions

- Consumers run `main`: nothing reaches the 8 repos before the promotion; skills
  read `CONVENTIONS.md`, the plugin version and the memory template from
  `origin/main` (lot 24).
- Skills and docs cite a rule by ID, never restate it (lot 24).
- `CONVENTIONS.md` stays within 15225 bytes (15158 after lot 37), English, no
  dated story; a new ID prefix goes in the citation regex of its test.
- Every lot bumps the plugin version in its own commit, in `plugin.json` and
  both fields of `.claude-plugin/marketplace.json`.
- Lot branches are created `--no-track` (lot 22); `lot-test` writes test files
  only; the dev session writes the memory (lot 26).
- Autopilot (lots 27-35): the script checks each step itself; `HARNESS_AUTOPILOT=1`
  denies what a guard would ask; allow and deny lists go per process; answers go
  into the stopped session, not the lots file.
- Watch (lot 34): started only when stdout is a terminal, never for `--dry-run`.
- Integration (lot 32): the backend is local; `autopilot.py` runs the command
  itself, 20 min at most, for a frontend with a command, between `audit` and
  `ship`; the report must be in `develop...HEAD`.
- Profile (lot 33): deepseek when `ANTHROPIC_BASE_URL`'s host is not
  `api.anthropic.com`; `lot-review` cites `printenv`, no prompt.
- Permission rules (lot 33): second layer behind the guard; each rule exists
  bare and behind `rtk`/`rtk proxy`; none opens on `*`.
- Gate cost (lot 37): one green `Validation command` per tree (GATE-1); a gate
  deliverable added to a green tree does not rerun it (GATE-2, GATE-8);
  `lot-ship` runs it once on the final tree. The autopilot allows and tells the
  Stack's targeted form.
- `git-guard.py` sees through shell keywords and groupings; backticks, `eval`
  and a command name in a variable stay out by decision (lots 25, 33).
- Claude Code caps a hook's context at 10,000 characters: `ponytail` has its
  own hook instead of a share of `CAP` (lot 33).

## Pitfalls

- The deepseek card has a 9-char margin (lot 37): a new carded rule needs its
  text cut elsewhere, never a clause that says who acts; the autopilot denies `python3 .github/scripts/*`, so edit
  the card by hand and let `deepseek-card.test.sh` prove it.
- The session runs the installed plugin, not the branch: a fix acts only after
  promotion and update.
- No local `shellcheck`: CI runs the workflows lint.
- `tests/run.sh` and `tests/lib.sh` unset `HARNESS_AUTOPILOT` and
  `ANTHROPIC_BASE_URL`; a suite testing them sets them after `lib.sh` (lot 29).
- `claude plugin update --scope project` with no project install here updates
  another project's: Step A0 checks `installed_plugins.json` (lot 30).
- Under auto mode, a Bash call the `rtk` hook rewrites (`grep`, `cat`, `git`)
  gets "no verdict" once: re-issue it, or use Read (lot 33).
- `tests/autopilot-lib.sh`: `fixture` takes the `Integration command` third;
  the timeout ceilings have env overrides (lot 32); the fake's log flattens
  `$*` now the system prompt carries the hint (lot 37).
- Importing `watch.py` in a test writes `__pycache__` unless
  `sys.dont_write_bytecode` is set; the line truncates the model to 16 chars
  (lot 34).
- `WebFetch` fails while the small model is a deepseek one: `curl` the `.md`
  pages of the Claude Code docs instead (lot 33).

## Open questions

- Untested against a real `claude`: `--answer --resume`, `--disallowedTools`
  and `SessionStart` in `claude -p`. A permission ask in `-p` is a deny: a
  step's commands must be in `allowed_tools()` (lots 28-33).
- The 8 projects' skill tables lack the `ponytail` row (lot 33).
- `Integration command` reaches `harness-invariants.yml` only in a later lot,
  once the 8 repos declare it (lot 32).
