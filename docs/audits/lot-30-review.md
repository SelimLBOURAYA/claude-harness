# Lot Review — Lot 30 — feat/lot-30-plugin-update-before-lot

**Harness ref:** 2.5.0
**Model:** claude-opus-5-5
**Target:** local diff origin/develop...HEAD
**Reviewed at:** 9f50f6f
**Verdict:** Fixed

Profile guard (Step 0): `ANTHROPIC_BASE_URL` was `https://api.anthropic.com`,
not empty. The owner chose to run the review in this session ("continue ici"),
on the Anthropic API with Opus; the review did not run in a new session (LOT-7).

## Findings
| # | Severity | Location | Finding | Outcome |
|---|----------|----------|---------|---------|
| 1 | Major | `plugins/claude-harness/skills/lot-start/SKILL.md:46` | The `enabledPlugins` guard does not prove a project-scope install: meal-planner-frontend enables the plugin without one, and the CLI would have updated kreadevis-frontend instead | fixed in 264e178: guard on `installed_plugins.json`, project entry at `$LOT_REPO` |
| 2 | Minor | `plugins/claude-harness/skills/lot-start/SKILL.md:56` | The version-change stop said nothing to the autopilot | fixed in 264e178: end `blocked`, rerun the autopilot |
| 3 | Minor | `tests/skills.test.sh:131` | The test pinned the guard of finding 1 | fixed in 264e178 |
| 4 | Minor | `plugins/claude-harness/skills/lot-start/SKILL.md:4` | Description line past the wrap width | fixed in 264e178 |
| 5 | Minor | `plugins/claude-harness/skills/lot-start/SKILL.md:54` | The step assumed the session opens at the repository root | fixed in 264e178: `cd` to `$LOT_REPO` first otherwise |

`lot-test` boundary: its one `test(30)` commit (c92b290) touches `tests/skills.test.sh` only and adds assertions. Project memory checked against the code; its lot 30 note was corrected in 9f50f6f.

## Candidate lots
- Repositories that enable the plugin without a project-scope install (meal-planner-frontend) run the user-scope copy: Step A0 skips them, PLUG-1 keeps them current.
