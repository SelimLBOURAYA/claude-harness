---
name: bootstrap-project
description: >-
  Generates a harnessed repository from templates/project: documents, gate
  parameters, plugin declaration, CI caller and dependabot, then verifies the
  result against harness-invariants. Use when starting a new project, or when
  bringing an existing repository under the harness for the first time.
metadata:
  version: "1.0"
---

# Bootstrap Project — generate a harnessed repository

Produces a repository that passes `harness-invariants.yml` on its first push.
Everything below comes from `~/ENV/projets/claude-harness/templates/`; nothing is
improvised, because a skeleton improvised once becomes the skeleton forever.

## Step 0 — Gather what the templates need

Ask the user for anything not already obvious from the repository, and **stop**
rather than guess. Every one of these lands in a file that later gates the build:

| Needed | Used by |
|---|---|
| Project name, one-line description | `CLAUDE.md`, `README.md` |
| `Stack`: `backend`, `frontend`, `harness` or `other` | every gate skill and workflow |
| `Validation command` | `lot-test`, the CI validate job |
| `Coverage tool`, `Coverage threshold`, `Coverage exclusions` | `lot-test`, `lot-audit` |
| `Migrations directory` (or `n/a`) | `migrations-immutable.yml` |
| `Frontend backend pair` (or `n/a`) | `integration-check` |
| `Health path`, `Image name` (backend) | `image-smoke.yml`, `image-publish.yml` |
| `Dist forbidden pattern` (frontend) | `frontend-dist.yml` |
| Language, framework, database, build tool | `CLAUDE.md` Stack table |
| The project's secrets and where they are read | `CLAUDE.md`, `.env.example` |

A parameter that genuinely does not apply is `n/a`. **Never delete the row** — a
missing row and an oversight look identical six months later, and
`harness-invariants.yml` fails on absence.

## Step 1 — Copy the skeleton

```bash
HARNESS=~/ENV/projets/claude-harness
cp -r "$HARNESS/templates/project/." .
mkdir -p .github/workflows docs/audits
cp "$HARNESS/templates/ci-caller.yml"   .github/workflows/ci.yml
cp "$HARNESS/templates/dependabot.yml"  .github/dependabot.yml
cp "$HARNESS/CONVENTIONS.md"            CONVENTIONS.md
```

`CONVENTIONS.md` is **copied, never written**. It is a byte-identical copy of the
harness master, and `harness-invariants.yml` compares the two on every build. The
same rule applies forever: to change a convention, edit the master and propagate.

On a **frontend**, delete `Dockerfile` and `compose.ci.yml`. On a **backend**,
delete the `frontend-dist` job from `ci.yml`.

## Step 2 — Fill the placeholders

Replace every `{{PLACEHOLDER}}` with the values from Step 0, in:

`CLAUDE.md`, `README.md`, `lots.md`, `.env.example`, `.github/workflows/ci.yml`,
and `Dockerfile` / `compose.ci.yml` when they are kept.

Then mirror, in the same change:

```bash
cp CLAUDE.md AGENTS.md
grep -rn '{{' . --include='*.md' --include='*.yml' --include='Dockerfile'
```

The `grep` must come back empty. A `{{PLACEHOLDER}}` left in `ci.yml` is a
workflow that fails on its first run; one left in `CLAUDE.md` is a gate parameter
the skills will read literally.

## Step 3 — Trim the dependabot template

Keep only the `package-ecosystem` blocks the project actually has. A `maven` block
in a repository with no `pom.xml` produces a weekly error, and a weekly error
teaches the team to ignore dependabot.

`github-actions` is always kept: it is what keeps the pinned SHAs current (P5-#9).

## Step 4 — Branches and first commit

```bash
git switch -c develop 2>/dev/null || git switch develop
git add -A
git commit -m "chore: bootstrap the project from the harness skeleton"
git push -u origin develop
```

`main` is production and `develop` is integration, from the first commit. If the
repository already has `main` and no `develop`, create `develop` from `main` and
say so — never fall back to working on `main`.

## Step 5 — Verify before declaring it done

```bash
<Validation command>                 # from the Gate parameters just written
cmp CLAUDE.md AGENTS.md              # silent
cmp CONVENTIONS.md ~/ENV/projets/claude-harness/CONVENTIONS.md   # silent
jq -e '.extraKnownMarketplaces["claude-harness"].source.ref == "main"' .claude/settings.json
```

The `ref` check is the one worth doing by hand. Without `"ref": "main"` the
project follows the harness **default** branch, `develop`, and every unpromoted
harness merge goes live here at the next session start.

Then push and read the first CI run. `harness-invariants.yml` green is the
acceptance criterion of this skill; anything it reports is a placeholder or a
deleted row, both fixed here rather than by loosening the workflow.

## Step 6 — Report

State: the files created, the gate parameters chosen (especially any `n/a` and
why), what was deleted for the stack, and the CI run result. Then stop — writing
lot 0 is the user's call, not this skill's.

## Rules

- Copy from `templates/`, never retype. A skeleton that drifts from the templates
  is a second skeleton.
- `CONVENTIONS.md` is copied from the harness master and never edited locally.
- Every gate parameter row present, `n/a` where it does not apply.
- `"ref": "main"` in `.claude/settings.json`, and `@main` on every harness
  workflow the caller uses.
- No `{{PLACEHOLDER}}` survives the bootstrap.
- `develop` exists and is the working branch before any feature work starts.
