# Lot Audit — Lot 40 — feat/lot-40-model-routing

**Harness ref:** 3.0.0
**Scope:** 22 modified files | **Fix commit:** none needed | **Verdict:** Ready for PR

The security review ran inline, without sub-agents: the diff (about 460 lines)
fits in the session's context. `./tests/run.sh` is green on b98f131, the tree
`lot-review` left; this audit changes no code.

## Summary
| Dimension    | Critical | Warning | Info |
|--------------|----------|---------|------|
| Security     | 0        | 0       | 2    |
| Performance  | 0        | 0       | 2    |
| Architecture | 0        | 0       | 2    |

## Security
| Severity | Location | Finding | Action |
|----------|----------|---------|--------|
| Info | `plugins/claude-harness/autopilot/autopilot.py:368` | The profile settings file (`--settings settings.claude.json`) is gone: every step now inherits `~/.claude/settings.json`. The refusal at `autopilot.py:892-902` still reads that file's `env.ANTHROPIC_BASE_URL` and the process's own before any step, so an active `deepseek` profile stops the run instead of sending Claude steps to another host. | none needed: the guard the lot section requires is in place and tested |
| Info | `plugins/claude-harness/hooks/subagent-model.py:31` | The `systemMessage` carries `subagent_type` and `model`, values the model chose. They reach the user's display only, never the model's context, and `json.dumps` escapes them. `watch.py` passes every new line (subagent description, type, model, effort) through `CONTROL.sub`, so a model's text cannot drive the terminal. | none needed |

The `--settings` JSON, `--model` and `--advisor` values are constants passed as
argv elements, with no shell. `session-context.sh` matches `ANTHROPIC_MODEL` with
`case` and feeds `awk` only fixed section names: nothing a variable holds is
evaluated. No secret, token or new absolute path in the diff.

## Performance
| Severity | Location | Finding | Action |
|----------|----------|---------|--------|
| Info | `plugins/claude-harness/hooks/session-context.sh:102-119` | The routing card adds about 1,300 characters (~350 tokens) to every SessionStart under the `claude` profile, compactions included, inside the existing 9,000-character `CAP` that reserves its room first. | none needed: the lot's purpose; measured at the first run |
| Info | `plugins/claude-harness/autopilot/autopilot.py:97` | An Opus or Haiku step keeps the owner's `advisorModel` (`--advisor off` is refused, V2) and is held off the advisor by one prompt line only: a step that ignores it pays for an Opus advisor call. | none needed: the lot section's chosen fallback; the first-run measure counts advisor calls per step |

The new PostToolUse hook starts one `python3` per `Agent` call (~30 ms), and
`watch.py` keeps one short string per subagent: both negligible.

## Architecture
| Severity | Location | Finding | Action |
|----------|----------|---------|--------|
| Info | `CONVENTIONS.md:104` | PROF-1 grew and `CONVENTIONS.md` has 6 bytes left under its 15,225-byte cap: the next rule change must cut text first. | none needed: noted in `docs/memory.md` |
| Info | `plugins/claude-harness/hooks/session-context.sh:106` | The card's model comes from `ANTHROPIC_MODEL`, then `settings.json`: a `/model` or app-picker choice is not seen. | none needed: stated shortcut, comment in place and README |

Scope against the lot section: the 8 deliverables are in the diff and no other
skill or hook file changed. `rules/deepseek.json` is current
(`deepseek-card.py --check` silent). The census carries `rules/model-routing.md`
and `hooks/subagent-model.py` enters the repository layout (DOC-1, `cmp CLAUDE.md
AGENTS.md` silent). Version `4.0.0` in `plugin.json` and both
`marketplace.json` fields. The remaining `deepseek` mentions in `lot-test` and
`lot-review` concern the interactive profile, which stays.

## Coverage exclusions
| Exclusion | Business code? | Proposed action |
|-----------|----------------|-----------------|
| (none) | n/a | none |

## Migrations
n/a (`Migrations directory` is `n/a`).

## Lot-specific notes
- The branch carries no `test(40)` commit: the tests came with `feat(40)`, and
  `lot-test` left no trace on the branch.
- V1 to V5 are taken from the `feat(40)` commit body; this audit did not rerun
  them against a real `claude`.

## Recommended next steps
1. `lot-ship` for lot 40.
2. After the `develop` → `main` promotion, the first autopilot run measures cost
   and time per step against the section's medians, advisor calls per Sonnet
   step and Haiku subagents per Opus step.
