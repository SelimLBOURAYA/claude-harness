# {{PROJECT_NAME}}

{{ONE_PARAGRAPH: what this service does and who calls it.}}

## Quick start

```bash
cp .env.example .env        # then fill it in; .env is gitignored
{{RUN_COMMAND}}
```

The application **fails fast** at startup if a required variable is missing. That
is deliberate: a service that boots with a half-filled configuration fails later,
somewhere less obvious.

## Validation gate

```bash
{{VALIDATION_COMMAND}}
```

Green before every commit, and green before the pull request is opened.

## Agent harness

This repository is driven by the `claude-harness` plugin: skills, git guards and
the reusable CI workflows. It is declared in `.claude/settings.json` and pinned to
the harness `main` branch.

- Conventions: [`CONVENTIONS.md`](CONVENTIONS.md) — a copy of the master, never
  edited here.
- Project specifics and the gate parameters the skills read:
  [`CLAUDE.md`](CLAUDE.md).
- Planning: [`lots.md`](lots.md).

Agents that do not load Claude Code plugins read the procedures from the local
clone at `~/ENV/projets/claude-harness/plugins/claude-harness/skills/`. Every
blocking rule is also enforced in CI, which is the only guard no agent can skip.

## Branches

`main` is production, `develop` is integration. Work branches from `develop` and
pull requests target `develop`. The `develop` → `main` promotion is done by the
repository owner, never by an agent.
