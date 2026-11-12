# Lot Audit — Lot 32 — feat/lot-32-autopilot-integration

**Harness ref:** 2.7.0
**Scope:** 18 modified files | **Fix commit:** 7d95e33 | **Verdict:** Ready for PR

## Summary
| Dimension    | Critical | Warning | Info |
|--------------|----------|---------|------|
| Security     | 0        | 0       | 2    |
| Performance  | 0        | 1       | 0    |
| Architecture | 0        | 0       | 1    |

Security discovery and false-positive filtering ran inline, without sub-agents:
the diff (317 lines) fits in the session's context.

## Security
| Severity | Location | Finding | Action |
|----------|----------|---------|--------|
| Info | `plugins/claude-harness/autopilot/autopilot.py:561` | `Integration command` runs with `shell=True`; its source is the repo's own `CLAUDE.md`, the same trust level as `Validation command` (line 399), and it never joins a session's allowlist | rejected: minor (autopilot) |
| Info | `plugins/claude-harness/autopilot/autopilot.py:351` | The integration-check session reads the command's log, output of the repo's own backend and scenario: a model input, but not an attacker-controlled one | rejected: minor (autopilot) |

## Performance
| Severity | Location | Finding | Action |
|----------|----------|---------|--------|
| Warning | `plugins/claude-harness/autopilot/autopilot.py:575` | After a zero exit, the command's background children (a backend started with `&`, `docker compose` helpers) stayed alive in its process group, holding the backend port against a `--resume` or the next lot's run | fixed in 7d95e33: the group is killed once the command exits; test `integrationleftover` |

## Architecture
| Severity | Location | Finding | Action |
|----------|----------|---------|--------|
| Info | `plugins/claude-harness/autopilot/autopilot.py:323` | The log lives under `~/.claude/autopilot/<project>/`, outside the session's working directory; the session reads it with `Read`, never through Bash, so no allowlist entry is needed, but no test runs a real session against it | rejected: minor (autopilot) |

Checked, nothing to report: the step order comes from `steps(params)` alone
(run, `--resume`, `--dry-run`, `step_audit`'s next step); DOC-5 and GATE-7
match the lot's specification; `rules/deepseek.json` carries neither rule;
`CLAUDE.md` and `AGENTS.md` are identical, as are the template pair; the
`harness-invariants.yml` requirement of the new row is out of scope, as the
lot's decisions state.

## Coverage exclusions
| Exclusion | Business code? | Proposed action |
|-----------|----------------|-----------------|
| (none) | n/a | none |

## Migrations
n/a: `Migrations directory` is `n/a`.

## Lot-specific notes
- The new test was checked green with the fix (`./tests/run.sh`, 16/16).
  Running it against the code without the fix was not done: the shell
  permissions of this session denied that run.
- Review finding 8 (a `|` in `Integration command` is cut by the Markdown
  table parser of `lotfile.py`) stays outside the lot's diff; a script named
  in the row is the workaround.

## Recommended next steps
1. `lot-ship`.
2. In elya-frontend, the lot that adds its `Integration command` row: the
   command must stop the backend it starts; the autopilot now kills what is
   left, but a `docker compose` stack started detached lives outside the
   process group and survives.
