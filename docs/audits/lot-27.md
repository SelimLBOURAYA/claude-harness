# Lot Audit — Lot 27 — feat/lot-27-autopilot

**Harness ref:** 2.0.1
**Scope:** 18 modified files | **Fix commit:** 88e4440 | **Verdict:** Ready for PR

## Summary
| Dimension    | Critical | Warning | Info |
|--------------|----------|---------|------|
| Security     | 0        | 1       | 2    |
| Performance  | 0        | 0       | 1    |
| Architecture | 0        | 1       | 2    |

`Skill(security-review)` ran with its discovery and false-positive phases done
inline, without sub-agents, because the diff fits in one session's context. It
kept no finding at its confidence bar (≥ 8). The Warning below is a hardening
item found during the same read.

## Security
| Severity | Location | Finding | Action |
|----------|----------|---------|--------|
| Warning | `plugins/claude-harness/autopilot/autopilot.py:319` | The lot ID comes from the model's structured answer. It was checked only through `lot_base()`, which keeps what precedes the first dot, so `5.x/../../y` passed on a `feat/lot-5-*` branch. That value then named log files under `~/.claude/autopilot/` and the report paths | fixed in 88e4440: the `LOT_ID` regex accepts only the IDs `lot-confirm.sh` accepts, the run stops before the confirmation otherwise, and a new test covers it |
| Info | `plugins/claude-harness/autopilot/autopilot.py:187` | The allowlist is not a sandbox. Under `acceptEdits`, a session can edit a script the `Validation command` runs and then run it, so `git-guard.py` and `lot-lock-guard.py` stop mistakes, not a hostile session. The interactive profiles already allow `Write`/`Edit` plus `./mvnw *`, so this is no new exposure. What contains it is the CI on the pull request and the manual `develop` → `main` promotion | open: by design (arbitrage "Permissions"), no change |
| Info | `plugins/claude-harness/autopilot/autopilot.py:297` | The `Validation command` runs with `shell=True`, read from `CLAUDE.md`. On `--resume` it is re-read from the branch, which the sessions may have edited. Running it is no worse than the previous row (any session can already run code through it) | open: same cause as the previous row, no change |

## Performance
| Severity | Location | Finding | Action |
|----------|----------|---------|--------|
| Info | `plugins/claude-harness/autopilot/autopilot.py:201` | `parse_output` reads the session log from its starting offset in a single read. A session's stream-json output is a few MB at most, which is negligible next to a session that runs for minutes | open: no change needed |

## Architecture
| Severity | Location | Finding | Action |
|----------|----------|---------|--------|
| Warning | `plugins/claude-harness/skills/lot-review/SKILL.md:196`, `plugins/claude-harness/skills/lot-audit/SKILL.md:241` | The Autopilot sections told the model that only the `fix(N)` commits are checked, against the lot diff, `docs/audits/` and the Lots file. Since the review fixes, the script checks every commit of the step, whatever its status, and also allows `docs/memory.md` | fixed in 88e4440: both sections now describe the check the script runs |
| Info | `plugins/claude-harness/autopilot/autopilot.py:130` | When `git rev-parse HEAD` fails, `before` is `None`. `changed_files` then gets no output, so the check passes on an empty list. HEAD always exists once lot-start has created the branch | open: unreachable after `step_start`, no change |
| Info | `dev-plan.md:2185` | Deliverable 6 still says the script checks "the `fix(N)` commits". The code is now stricter (every commit), which meets the spec | open: the Lots file changes only on the owner's approval; `lot-ship` or a later amendment can align the wording |

Conventions checked against the diff: standard library only (V6), no new
dependency (ASK-1), no hard-coded identifier or absolute path (the paths come
from `~`), no silent `catch` (each `except` either stops with a reason or
falls back on purpose), `CLAUDE.md` = `AGENTS.md` (DOC-1), and the new script
and report are in the census.

## Coverage exclusions
| Exclusion | Business code? | Proposed action |
|-----------|----------------|-----------------|
| (none) | n/a | none: shell test suite, no coverage instrumentation |

## Migrations
n/a (`Migrations directory` is `n/a`).

## Lot-specific notes
- **Merge without a human**: `lot-ship` merges through `gh pr merge`, which
  `git-guard.py` allows only for a `feat/lot-*` → `develop` pull request whose
  checks are all green. Under `HARNESS_AUTOPILOT=1`, every "ask" of the guard
  becomes a deny (`tests/git-guard.test.sh`). The variable can only make the
  guard stricter, so a session that sets it gains nothing.
- **Lock confirmation**: the script submits `lot-start confirm N` only after
  `status: ok`, no questions, `sync-status.py` exiting 0, a `feat/lot-N-*`
  branch and, since 88e4440, a well-formed lot ID. `lot-confirm.sh` still
  accepts only that exact prompt.
- **Profile precondition**: the script refuses to start when `settings.json`
  or the environment carries `ANTHROPIC_BASE_URL`, so the Opus steps cannot
  run at DeepSeek.
- **Not verified by an actual run**: whether a `UserPromptSubmit` hook fires on
  a `-p` prompt passed on stdin, which the lock confirmation needs. It is the
  lot's third validation criterion (first run on a real project). If it does
  not fire, the dev step stops on `lot-lock-guard.py` with a readable reason.
  No unguarded write happens.

## Recommended next steps
1. `lot-ship`.
2. After the promotion to `main`: run `--dry-run`, then a first real run on one
   project, as the lot's validation criteria require.
3. Owner's call, outside the repo: the profiles' `Bash(docker *)` belongs to the
   same class as the narrowed `python3` (see `lot-27-review.md`).
