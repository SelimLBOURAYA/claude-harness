# {{PROJECT_NAME}} — Project conventions

{{ONE_LINE_DESCRIPTION}}

Cross-cutting rules live in [`CONVENTIONS.md`](CONVENTIONS.md), a byte-identical copy
of the master `claude-harness/CONVENTIONS.md`. They are **not** repeated here. This
file holds what is specific to this project.

## Stack

| Item | Value |
|---|---|
| Language | {{LANGUAGE}} |
| Framework | {{FRAMEWORK}} |
| Database | {{DATABASE}} |
| Build | {{BUILD_TOOL}} |
| CI | GitHub Actions, calling the reusable workflows of `claude-harness` at `@main` |

## Gate parameters

The skills read this table instead of hard-coding anything. Every row is present;
a row that does not apply carries `n/a`, never omission — a missing row is
indistinguishable from an oversight.

| Parameter | Value |
|---|---|
| `Stack` | `{{STACK}}` |
| `Validation command` | `{{VALIDATION_COMMAND}}` |
| `Coverage tool` | `{{COVERAGE_TOOL}}` |
| `Coverage threshold` | `{{COVERAGE_THRESHOLD}}` |
| `Coverage exclusions` | `{{COVERAGE_EXCLUSIONS}}` |
| `Migrations directory` | `{{MIGRATIONS_DIR}}` |
| `Lots file` | `lots.md` |
| `Frontend backend pair` | `{{PAIRED_REPO}}` |
| `Health path` | `{{HEALTH_PATH}}` |
| `Dist forbidden pattern` | `{{DIST_FORBIDDEN_PATTERN}}` |
| `Image name` | `{{IMAGE_NAME}}` |

The contract of this section is documented in the harness `README.md`.

## Architecture

{{LAYERS_AND_PACKAGES}}

## Data model

{{ENTITIES_AND_RELATIONS}}

## Project-specific secrets

| Variable | Role | Where it is read |
|---|---|---|
| `{{SECRET_ENV_VAR}}` | {{ROLE}} | `{{CONFIG_FILE}}` |

All of them are `${ENV_VAR}` placeholders with **no default value** (§5), listed
in `.env.example`, and `.env` is gitignored.

## Branching and delivery

Standard §7 model: `main` is production, `develop` is integration. Branches
`feat/lot-N-slug` from `develop`, PR to `develop`, merged by `lot-ship` once its
CI is green (GIT-6). The promotion `develop` → `main` is **user-only**.

## Skills

Skills come from the `claude-harness` plugin, not from `.claude/skills/`. In a
Claude Code session with the plugin enabled they are announced as
`claude-harness:<name>`.

| Skill | Trigger | Role |
|---|---|---|
| `lot-start` | before any lot development, and on `lot-start confirm N` | Syncs the status table with develop, asks every ambiguity, creates the branch; the user's `lot-start confirm N` opens writes |
| `lot-test` | lot code complete | Tests written and green, coverage at the threshold above |
| `lot-review` | after `lot-test`, in a new session | Code review of the lot, applied fixes and one batch of questions for the findings that need a decision; **requires the `claude` profile** |
| `lot-audit` | after `lot-review` | Security, performance and architecture audit, findings fixed; writes `docs/audits/lot-N.md` |
| `lot-ship` | after `lot-audit` | Commits, push, PR to `develop`, merge once the CI is green, then stop |
| `harness-sync` | harness or docs may have drifted | Detects and fixes drift between docs, skills and reality |
| `integration-check` | before any front PR | Manual front ↔ real backend smoke, writes `docs/audits/lot-0-integration.md` |
| `dep-update` | dependency refresh | Patch/minor applied, major proposed |
| `i-have-adhd` | user invokes it | Focus aid, never model-invoked |

**Gate, mandatory in order**: `lot-test → lot-review → lot-audit → lot-ship`,
opened by `lot-start` before any development.
Each lot gets its own invocation of every gate skill.

A stale plugin stops lot work (`CONVENTIONS.md` PLUG-1). Agents that load no
plugin read the procedures from
`~/ENV/projets/claude-harness/plugins/claude-harness/skills/<name>/SKILL.md`
(DOC-6); CI enforces every blocking invariant for all agents.

Project-specific skills, if any, live in `.claude/skills/<name>/SKILL.md` — the
directory Claude Code scans — and are listed in the census below.

## Project documents

| Document | Role |
|---|---|
| [`CLAUDE.md`](CLAUDE.md) | This file — project conventions, gate parameters, census |
| [`AGENTS.md`](AGENTS.md) | Byte-identical mirror of `CLAUDE.md` |
| [`CONVENTIONS.md`](CONVENTIONS.md) | Copy of the cross-cutting conventions master |
| [`README.md`](README.md) | Presentation and quick start |
| [`lots.md`](lots.md) | Planning: lots, statuses, specifications (French) |
| `docs/audits/` | Lot reports produced by `lot-review` and `lot-audit` |

Any document added to this project is added to this census **in the same commit**.
`harness-invariants.yml` fails the build when a `SKILL.md` or a report is missing
from it.

## Validation gate

```bash
{{VALIDATION_COMMAND}}
```

Green before every commit and before the PR (GATE-2).
