# Lot Audit — Lot 34 — feat/lot-34-autopilot-watch

**Harness ref:** 2.10.0
**Scope:** 11 modified files | **Fix commit:** 1e512e9 | **Verdict:** Ready for PR

Run under the autopilot (`HARNESS_AUTOPILOT=1`). The diff fits in the session's
context: the `security-review` discovery and false-positive phases ran inline,
without sub-agents.

## Summary
| Dimension    | Critical | Warning | Info |
|--------------|----------|---------|------|
| Security     | 0        | 1       | 0    |
| Performance  | 0        | 0       | 1    |
| Architecture | 0        | 0       | 1    |

## Security
| Severity | Location | Finding | Action |
|----------|----------|---------|--------|
| Warning | `plugins/claude-harness/autopilot/watch.py:58` | The watch printed the model's text, tool inputs, denial messages and URLs from the log straight to the terminal: a JSON string decodes `\u001b`, so a prompt-injected session could emit ANSI/OSC escape sequences (title rewrite, OSC 52 clipboard write, screen clearing) in the operator's terminal | fixed in 1e512e9 (`lines()` replaces C0 and C1 controls with `?`; test `a watch line carries no control character from the log`) |

No other finding: the watch only reads `~/.claude/autopilot/<basename>/*.jsonl`
of the operator's own account, runs `sys.executable` on a fixed path beside
`autopilot.py` with an argument list (no shell), handles no secret and exposes
no route.

## Performance
| Severity | Location | Finding | Action |
|----------|----------|---------|--------|
| Info | `plugins/claude-harness/autopilot/watch.py:21` | `newest()` globs and stats every log of the project folder once a second; the folder grows with each run | rejected: minor (autopilot); a few hundred `stat` calls a second have no measurable cost |

## Architecture
| Severity | Location | Finding | Action |
|----------|----------|---------|--------|
| Info | `plugins/claude-harness/autopilot/watch.py:89` | The rendered labels (`refusé`, `fin d'étape`) are French, the rest of the plugin's output English | rejected: minor (autopilot); the lot specifies the local script taken as is, and these are operator-facing strings, not agent instructions (DOC-2) |

`autopilot.py` keeps its layering: `start_watch`/`stop_watch` are two small
functions, the child is stopped in a `finally` covering merge, stop and Ctrl-C,
and no dependency was added (V6, standard library only).

## Coverage exclusions
| Exclusion | Business code? | Proposed action |
|-----------|----------------|-----------------|
| (none) | n/a | none |

## Migrations
n/a (`Migrations directory` is `n/a`).

## Lot-specific notes
- Deliverable 2 checked: `start_watch` runs after the `--dry-run` return
  (`autopilot.py:795-806`) and returns `None` when standard output is not a
  terminal; both paths are tested (`script` and redirected output).
- The review's rejected finding 8 (module-level `MODEL`) was not reopened.

## Recommended next steps
1. `lot-ship`.
