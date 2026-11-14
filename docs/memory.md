# Project memory

> Working notes for the agent, not the truth: the code and git are. Check a
> note against the code before it guides a write, and fix in the current lot a
> note the code contradicts. The development session rewrites this file at its
> close (`lot-start` Step B3), never appending a lot journal; at most 6000
> characters (MEM-1).

## Code map

- `hooks/lotfile.py` also reads the profile and a lot's section range
  (`section <root> <lot>`); `session-context.sh` caps its injections.
- `skills/lot-start/sync-status.py` maps develop merges to status rows; a
  backticked SHA in the lots file reconciles a stop.
- `autopilot/autopilot.py` (one `claude -p` per step): `integration` runs the
  repo's command then writes the report (32); `step_ship` removes the lock once
  merged (35); census rows accepted (36); an out-of-diff stop resumes at the
  next step if the step did not fail and its report is committed (39);
  `TARGETED_TESTS` and `commands_hint` carry the Stack's commands (37).
- `autopilot/watch.py`: newest run jsonl, complete lines, terminal only (34).
- `tests/autopilot-lib.sh` holds the fakes and the `fixture` (37).
- `templates/project/.claude/settings.json` holds the master permission rules
  (33); `sync-projects.yml` pushes `synced_files` and `synced_permissions`.

## Decisions

- Consumers run `main`: skills read `CONVENTIONS.md`, the version and the memory
  template from `origin/main` (24).
- Skills and docs cite a rule by ID (24).
- `CONVENTIONS.md` stays under 15225 bytes, English, no dated story; a new ID
  prefix enters its test's citation regex.
- Every lot bumps the version in `plugin.json` and both `marketplace.json`
  fields.
- Lot branches are `--no-track` (22); `lot-test` writes test files only; the dev
  session writes the memory (26).
- Autopilot (27-35): the script checks each step; `HARNESS_AUTOPILOT=1` denies
  what a guard would ask; lists per process; answers go into the stopped
  session.
- Integration (32): the script runs the frontend's command (local backend,
  20 min max) between `audit` and `ship`; the report must be in
  `develop...HEAD`.
- Profile (33): deepseek when `ANTHROPIC_BASE_URL`'s host is not
  `api.anthropic.com`; `lot-review` cites `printenv`.
- Permission rules (33): each exists bare and behind `rtk`/`rtk proxy`, none on
  `*`.
- Gate cost (37): one green `Validation command` per tree; a gate deliverable
  added to a green tree does not rerun it; `lot-ship` runs it once on the final
  tree (GATE-1, GATE-2, GATE-8).
- `git-guard.py` sees through keywords and groupings; backticks, `eval`, a
  variable command stay out (25, 33).
- A lot section (38): `## LOT <id>` at level 2, case and leading zeros ignored,
  to the next heading outside a fence; none or several means no range;
  `lot-ship` updates it (39).
- Memory margin (39): the close leaves `docs/memory.md` within 5000 characters,
  MEM-1 stays 6000.

## Pitfalls

- The deepseek card has a 9-char margin (37): cut text elsewhere, never a clause
  saying who acts; `python3 .github/scripts/*` is denied, so edit it by hand and
  prove it with `deepseek-card.test.sh`.
- The session runs the installed plugin, not the branch: a fix acts only after
  promotion.
- `tests/run.sh` and `lib.sh` unset `HARNESS_AUTOPILOT` and
  `ANTHROPIC_BASE_URL`; a suite testing them sets them after `lib.sh` (29).
- `claude plugin update --scope project` without a local project install updates
  another project's: Step A0 checks `installed_plugins.json` (30).
- An `rtk`-rewritten Bash call gets "no verdict" once: re-issue it, or use Read
  (33).
- `tests/autopilot-lib.sh`: `fixture` takes `Integration command` third;
  timeouts have env overrides; the fake's log flattens `$*` (32, 37).
- Importing `watch.py` writes `__pycache__` unless `sys.dont_write_bytecode` is
  set (34).
- The git guard reads a commit `-m` body starting with `- ` as a short flag:
  start the body with a word (39).
- `sync-status.py` maps a `chore/lot-N-*` merge to the lot: when it only plans,
  cite its SHA in the lots file (39).
- Under autopilot, `python3` runs only from the plugin cache; exercise a repo
  script through `./tests/run.sh` (38, 39).

## Open questions

- Untested against a real `claude`: `--answer --resume`, `--disallowedTools` and
  `SessionStart` in `claude -p`; a permission ask in `-p` is a deny, so a
  step's commands must be in `allowed_tools()` (28-33).
- `Integration command` reaches `harness-invariants.yml` only once the 8 repos
  declare it (32).
