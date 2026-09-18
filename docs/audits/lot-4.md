# Lot Audit — Lot 4 — feat/lot-0-6-harness-foundation

**Harness ref:** `feat/lot-0-6-harness-foundation` (lot 3 at `bcf159b`)
**Scope:** 8 skeleton files + 1 skill + 1 test suite (63 assertions)
**Verdict:** ✅ Ready for PR — the validation criterion was met locally, with one
stated limit

Findings **#10**, #22, #25; P5-#9, P5-#18; P6-D3, P6-D9, P6-D10, P6-D13.

## Summary

| Dimension | Critical | Warning | Info |
|---|---|---|---|
| Security | 0 | 0 | 3 |
| Harness | 0 | 1 | 2 |
| Architecture | 0 | 1 | 1 |

## What the lot delivers

| Deliverable | Content |
|---|---|
| `templates/project/CLAUDE.md` + `AGENTS.md` | Stack, the full `Gate parameters` table, architecture, data model, secrets, branching, the Skills table with the plugin names and the gate order, the non-Claude-agent pointer (P6-D3), and the documents census. Shipped already mirrored |
| `templates/project/.claude/settings.json` | Marketplace declared with `"ref": "main"` and the plugin enabled |
| `templates/project/.gitignore` | `.env` out, `*.local.md` the only ignored markdown, and a comment stating that `CLAUDE.md`/`AGENTS.md`/`CONVENTIONS.md`/`lots.md` are never added (§8, #22) |
| `templates/project/.env.example` | Committed template, every secret empty, cross-referenced with the `CLAUDE.md` secrets table |
| `templates/project/lots.md` | Opens with `\| Lot \| Branche \| Statut \|` (P6-D10), states the legend, states that there are no dates (P6-D5), and carries the per-lot section shape |
| `templates/project/README.md` | Quick start, gate, harness pointers, branch model |
| `templates/project/Dockerfile` | Backend image, **no build stage** (P5-#18), non-root, healthcheck with a start period |
| `templates/project/compose.ci.yml` | The image under test plus a real PostgreSQL, for `image-smoke.yml` (§2.5) |
| `bootstrap-project` skill | Six steps from parameters to a green first CI run, replacing `prompt-harness.md` (#10) |

## The two decisions worth stating

**`CONVENTIONS.md` is not in the skeleton.** It would be a third copy of the
master, sitting in a directory nobody re-copies, drifting silently until
`harness-invariants.yml` fails in a repository generated six months later. The
bootstrap skill copies it from the harness at generation time and a test asserts
the skeleton does **not** carry one.

**`ci.yml` is not in the skeleton either.** `templates/ci-caller.yml` already is
that file; a second copy under `templates/project/.github/workflows/` would be
the same drift one level down. The skill copies it in, and a test asserts the
duplicate does not exist.

Both are the same rule: one artefact, one location. The skeleton holds what is
only ever a starting point; anything that must stay in step with something else
is copied from that something else.

## The Dockerfile, and why it has no build stage

The obvious backend Dockerfile builds in a first stage with
`./mvnw package -DskipTests` and copies the jar into a second. That jar is **not
the jar the tests ran on**: different Maven version, different local repository,
different resolution of every version range, and no tests. CI would report green
on bytes nobody ships, and ship bytes nobody tested.

So the template has a single stage and a `COPY target/*.jar`. The jar comes from
the validation job, uploaded as `tested-artifact` and downloaded into the build
context by `image-publish.yml`. The reasoning is written in the file, at the top,
because the tempting version is the one someone will "fix" it back to.

A test rejects `skipTests`, `mvnw package` and any `FROM … AS build` outside a
comment.

## Security

| Severity | Location | Finding | Action |
|---|---|---|---|
| Info | `.env.example` | Every secret key is present with an **empty** value. A test rejects any line assigning a value to a name matching `PASSWORD`, `SECRET`, `TOKEN`, `API_KEY` — a template that ships a working dev credential is how a dev credential reaches production | None |
| Info | `compose.ci.yml` | `POSTGRES_PASSWORD: ci` is a literal, and stays one: a throwaway credential for a CI-only container with no published port. The comment says so, so it is not read later as an example to copy | None |
| Info | `Dockerfile` | Non-root user, no secret, no default for one, `MaxRAMPercentage` rather than a fixed heap | None |

## Harness

| Severity | Location | Finding | Action |
|---|---|---|---|
| Warning | `templates/project/` | The skeleton is **static text with placeholders**, not a generator. Nothing mechanically prevents a bootstrap that forgets Step 2 and commits `{{STACK}}` into a gate parameter. The skill's `grep -rn '{{'` is the guard, and it is an instruction like any other | Accepted. The failure is loud on the first CI run: `harness-invariants.yml` fails on a `Stack` row it cannot read. Promoting the skeleton to a script is a lot of its own, not a line in this one |
| Info | all skeleton files | Placeholders are `{{UPPER_CASE}}`, asserted. A lower-case one reads like real content and survives the bootstrap unnoticed; the single documented exception is `{{slug}}` in a branch name, where upper case would itself be wrong |
| Info | `ci-caller.yml` | The two image jobs and the `tested-artifact` upload ship **commented out** (P6-D9), to be enabled by the project's own image lot. Publishing before there is anything to deploy fills a registry with tags nobody pulls, and a red smoke job on a service that does not yet boot teaches the team to ignore red | None |

## Architecture

| Severity | Location | Finding | Action |
|---|---|---|---|
| Warning | `bootstrap-project` | The skill is the **ninth** shipped skill, and the first that is not part of the lot gate. The Skills table in `CLAUDE.md`, `README.md` and the skeleton's own `CLAUDE.md` now lists nine entries in three places, each maintained by hand | Accepted, and it is exactly what `harness-sync` exists to catch. Worth revisiting if a tenth skill arrives |
| Info | `tests/skeleton.test.sh` | The suite re-encodes each `harness-invariants.yml` rule against the skeleton files rather than running the workflow. That is duplication, deliberately: it is the only way to check the criterion without a runner, and one assertion pins the three shared parameter labels so the two cannot drift apart silently | None |

## Coverage exclusions

n/a — `Coverage tool` = none.

## Migrations

n/a — `Migrations directory` = n/a.

## Validation criteria

- [x] A throwaway repo generated from the skeleton passes `harness-invariants.yml`
      — **run locally**, not on a runner. A fixture copied `templates/project/`,
      `ci-caller.yml`, `dependabot.yml` and the conventions master into a temp
      directory, filled every placeholder with plausible backend values, and
      executed each check of the workflow as shell: mirror identical, conventions
      identical, `ref` = `main`, plugin enabled, no `skill/`, all eleven gate rows
      present, census complete, lots file opening on `| Lot | Branche | Statut |`,
      zero surviving placeholder. All green
- [x] Report `docs/audits/lot-4.md`

The gap between "run locally" and the criterion as written is the GitHub runner
itself: `actions/checkout` of a private harness, the job graph, the `secrets`
plumbing. That is the same gap as lot 3's, and it closes with the same run.

## Out of repo, for the user

Three lot 4 items are deletions outside this repository and are listed in the PR
body rather than performed here:

- `~/ENV/projets/prompt-harness.md` — superseded by `bootstrap-project` (#10)
- `~/.claude/templates/project-skeleton/` — the non-conforming user-level
  skeleton (P6-D13): no mirrored `AGENTS.md`, no Skills table, no gate
  parameters, no census
- `meal-planner-backend/prompt-harness.md` — belongs to lot 9, in that repo's own PR

The root memory that references the first two needs the same correction; it is on
the lot 5 list.

## Recommended next steps

1. Delete the two superseded skeletons **after** the first real bootstrap
   succeeds, not before.
2. Generate the first consuming repo with `bootstrap-project` at lot 7 and read
   what the first CI run says; that is the criterion's runner half.
