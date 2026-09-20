# claude-harness — Project conventions

Central, versioned agentic harness for the portfolio: skills, hooks, reusable CI
workflows and the project skeleton, distributed as a Claude Code plugin.

Cross-cutting rules live in [`CONVENTIONS.md`](CONVENTIONS.md) (the **master** copy
since lot 5) and are not repeated here. This file holds what is specific to this repo.

## Stack

| Item | Value |
|---|---|
| Languages | Bash (hooks, tests), Python 3 (command parsing), YAML (workflows), Markdown (skills, docs) |
| Runtime dependencies | `bash`, `python3`, `jq`, `git`, `gh` — all preinstalled, none added |
| Distribution | Claude Code plugin marketplace (`.claude-plugin/marketplace.json`) |
| Consumers | The 8 portfolio repos, which follow the `main` branch of this repo |
| CI | GitHub Actions, reusable `workflow_call` workflows under `.github/workflows/` |

## Gate parameters

| Parameter | Value |
|---|---|
| `Stack` | `harness` |
| `Validation command` | `./tests/run.sh` |
| `Coverage tool` | none (shell test suite, no coverage instrumentation) |
| `Coverage threshold` | n/a |
| `Coverage exclusions` | (none) |
| `Migrations directory` | n/a |
| `Lots file` | `dev-plan.md` |
| `Frontend backend pair` | n/a |
| `Health path` | n/a |
| `Dist forbidden pattern` | n/a |
| `Image name` | n/a |

The contract of this section is documented in [`README.md`](README.md#gate-parameters);
every consuming repo carries the same section in its own `CLAUDE.md`.

## Repository layout

```
.claude-plugin/marketplace.json      marketplace manifest (this repo = marketplace)
plugins/claude-harness/
  .claude-plugin/plugin.json         plugin manifest
  hooks/hooks.json                   hook wiring (PreToolUse git guard, PostToolUse mirror)
  hooks/git-guard.py                 git/gh command guard
  hooks/mirror-sync.sh               CLAUDE.md <-> AGENTS.md mirror
  skills/<name>/SKILL.md             generic skills shared by every repo
.github/workflows/*.yml              reusable workflows called by every repo
templates/                           project skeleton, CI caller, dependabot
tests/run.sh                         validation gate of this repo
docs/audits/                         lot audit reports
docs/audits/portfolio/               cross-cutting portfolio audits (P4, P5, P6)
```

## Branching and delivery

Standard §7 model: `main` is what the consuming repos actually run, `develop` is
integration. A change is only active in the 8 repos after the user promotes
`develop` → `main`. Branches `feat/lot-N-slug` from `develop`, PR to `develop`.

The promotion `develop` → `main` is **manual and user-only** — never done by an agent.

## Skills

Skills are shipped by the plugin, not by `.claude/skills/`. In a Claude Code session
with the plugin enabled they are announced as `claude-harness:<name>`.

| Skill | Trigger | Role |
|---|---|---|
| `lot-test` | lot code complete | Tests written and green, coverage gate at the repo threshold |
| `lot-review` | after `lot-test` | Code review of the lot, inline PR comments and applied fixes; **requires the `claude` profile** |
| `lot-audit` | after `lot-review` | Security, performance and architecture audit; writes `docs/audits/lot-N.md` |
| `lot-ship` | after `lot-audit` | Commits, push, PR to `develop`, then stop until merge |
| `harness-sync` | harness or docs may have drifted | Detects and fixes drift between docs, skills and reality |
| `integration-check` | before any front PR | Manual front ↔ real backend smoke, writes `docs/audits/lot-0-integration.md` |
| `dep-update` | dependency refresh | Patch/minor applied, major proposed |
| `bootstrap-project` | new repo, or a repo joining the harness | Generates the repository from `templates/project/` and verifies it against `harness-invariants` |
| `i-have-adhd` | user invokes it | Focus aid, never model-invoked |

**Gate, mandatory in order**: `lot-test → lot-review → lot-audit → lot-ship`.
Each lot gets its own invocation of every gate skill.

**Non-Claude agents** (Cursor, DeepClaude/OpenRouter, any agent that does not load
plugins): read the procedures directly from the local clone at
`~/ENV/projets/claude-harness/plugins/claude-harness/skills/<name>/SKILL.md`.
Every blocking invariant is also enforced in CI, which is the only agent-agnostic guard.

## Project documents

| Document | Role |
|---|---|
| [`CLAUDE.md`](CLAUDE.md) | This file — project conventions, gate parameters, census |
| [`AGENTS.md`](AGENTS.md) | Byte-identical mirror of `CLAUDE.md` |
| [`CONVENTIONS.md`](CONVENTIONS.md) | **Master** of the cross-cutting conventions (lot 5) |
| [`README.md`](README.md) | Plugin installation, the two owner settings that make the harness consumable, gate parameters contract |
| [`dev-plan.md`](dev-plan.md) | Remediation plan — lots, decisions, findings matrices (French) |
| `plugins/claude-harness/skills/bootstrap-project/SKILL.md` | New project generation skill |
| `plugins/claude-harness/skills/dep-update/SKILL.md` | Dependency refresh skill |
| `plugins/claude-harness/skills/harness-sync/SKILL.md` | Harness drift detection skill |
| `plugins/claude-harness/skills/i-have-adhd/SKILL.md` | Focus aid skill |
| `plugins/claude-harness/skills/integration-check/SKILL.md` | Front ↔ backend smoke skill |
| `plugins/claude-harness/skills/lot-audit/SKILL.md` | Lot audit skill |
| `plugins/claude-harness/skills/lot-audit/checklists.md` | Detailed audit checklists |
| `plugins/claude-harness/skills/lot-review/SKILL.md` | Lot code-review skill |
| `plugins/claude-harness/skills/lot-ship/SKILL.md` | Lot delivery skill |
| `plugins/claude-harness/skills/lot-test/SKILL.md` | Lot test and coverage skill |
| `docs/audits/lot-0.md` | Lot 0 report — technical verifications V1 to V7 |
| `docs/audits/lot-1.md` | Lot 1 report — hooks |
| `docs/audits/lot-2.md` | Lot 2 report — generic skills |
| `docs/audits/lot-2b.md` | Lot 2b report — `lot-review` skill |
| `docs/audits/lot-3.md` | Lot 3 report — reusable CI workflows |
| `docs/audits/lot-4.md` | Lot 4 report — project skeleton |
| `docs/audits/lot-5.md` | Lot 5 report — conventions master |
| `docs/audits/lot-6.md` | Lot 6 report — portfolio audits moved in |
| `docs/audits/lot-6b.md` | Lot 6b report — GitHub settings made by the user |
| `docs/audits/lot-0-6-review.md` | Lot review report for the whole foundation branch |
| `docs/audits/lot-7.md` | Lot 7 report — kreadevis-backend adoption |
| `docs/audits/lot-8.md` | Lot 8 report — kreadevis-frontend adoption |
| `docs/audits/lot-9.md` | Lot 9 report — meal-planner-backend adoption |
| `docs/audits/lot-10.md` | Lot 10 report — meal-planner-frontend adoption |
| `docs/audits/lot-11.md` | Lot 11 report — elya adoption |
| `docs/audits/lot-12.md` | Lot 12 report — elya-frontend adoption |
| `docs/audits/lot-13.md` | Lot 13 report — deployment adoption |
| `docs/audits/portfolio/p4-meta-harness-2026-09-17-v2.md` | P4 portfolio audit (supersedes the removed morning v1) |
| `docs/audits/portfolio/p5-harness-cicd-2026-09-17.md` | P5 CI/CD guards audit |
| `docs/audits/portfolio/p6-meta-portfolio-2026-09-17.md` | P6 cross-cutting portfolio audit |
| `templates/project/` | Project skeleton generated into a new repo |
| `templates/project/CLAUDE.md` | Skeleton project conventions, placeholders filled at bootstrap |
| `templates/project/AGENTS.md` | Byte-identical mirror shipped with the skeleton |
| `templates/project/README.md` | Skeleton readme |
| `templates/project/lots.md` | Skeleton lots file, opens with the status table |
| `templates/ci-caller.yml` | Caller workflow template for consuming repos |
| `templates/dependabot.yml` | Dependabot template for consuming repos |

Any document added to this repo is added to this census **in the same commit**.

## Validation gate

```bash
./tests/run.sh
```

Runs every `tests/*.test.sh`. It must be green before any commit, and the reusable
workflows must be green on the PR.
