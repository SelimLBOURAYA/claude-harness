# Lot Review — Lot 40 — feat/lot-40-model-routing

**Harness ref:** 3.0.0
**Model:** claude-opus-5-5
**Target:** local diff origin/develop...HEAD
**Reviewed at:** b98f131
**Verdict:** Fixed

No PR is open yet. The branch carries no `test(40)` commit: the lot's tests came
with the `feat(40)` commit (GATE-3), and `lot-test` left no trace on the branch,
so the `lot-test` boundary check had no commit to read.

The scope was checked against the lot section (dev-plan.md, LOT 40): the 8
deliverables are in the diff, `rules/deepseek.json` is current
(`deepseek-card.py --check` silent), and the base-URL refusal still reads
`settings.json` before any step, so dropping the `--settings` profile file
lets no step run on DeepSeek.

## Findings
| # | Severity | Location | Finding | Outcome |
|---|----------|----------|---------|---------|
| 1 | Low | `plugins/claude-harness/hooks/subagent-model.py:22` | A non-object `tool_input` made `.get` raise, breaking the hook's "never blocks" contract | fixed in b98f131, case added to `tests/subagent-model.test.sh` |
| 2 | Info | `plugins/claude-harness/autopilot/watch.py:87` | The 16-character agent column cuts marked names (`≠claude-haiku-5-`) | rejected: display only, the `↳` prefix already had the same width before this lot |
| 3 | Info | `plugins/claude-harness/autopilot/watch.py:92` | `TASKS` keeps the description of a background subagent, whose result has no `resolvedModel` | rejected: one short string per subagent for the life of a watch process |
| 4 | Info | `plugins/claude-harness/hooks/session-context.sh:106` | A model picked with `/model` or the app picker is not seen by the card | rejected: the lot's stated shortcut (comment in place, README), measured at the first run |
| 5 | Info | `plugins/claude-harness/autopilot/autopilot.py:225` | Opus steps get the advisor ban in the system prompt and in the card | rejected: the prompt line is needed for Haiku `ship`, which gets no card; the duplicate costs one line |

## Project memory

`docs/memory.md` agrees with the code (`MODELS`, `step_settings()`, the step
line read by `watch.py`, the hook matcher `Agent|Task`); 5,5K characters, under
the cap. No change.

## Candidate lots
none
