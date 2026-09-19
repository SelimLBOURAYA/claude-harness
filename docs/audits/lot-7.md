# Lot Audit — Lot 7 — kreadevis-backend adoption

**Harness ref:** `chore/harness-adoption-reports`, from `23aa7be`
**Target repo:** `kreadevis-backend`, branch `chore/harness-adoption`
**Commits:** `0c3695b` (kb lot 22), `ee5a40a` (adoption), `2bc9e83` (CI fixes)
**Verdict:** ✅ checklist complete, validation gate green, no Critical.
**Merge blocked** by two owner actions, neither a defect of this lot - see
"Left open".

Scope: the common adoption checklist (items 1 to 14 of `dev-plan.md`), plus the
kb-specific items, plus kb lot 22 delivered in the same pull request on the
user's decision of 2026-09-19.

## Summary

| Dimension | Critical | Warning | Info |
|---|---|---|---|
| Security | 0 | 1 | 1 |
| Performance | 0 | 1 | 0 |
| Architecture | 0 | 1 | 1 |
| Harness | 0 | 1 | 1 |

## The finding this lot actually uncovered

`spring-boot-liquibase` was absent from the dependency graph. Spring Boot 4 moved
the autoconfigurations out of `spring-boot-autoconfigure` into per-technology
modules, so `liquibase-core` sat on the classpath while **nothing read**
`spring.liquibase.change-log`. The consequence is wider than the one P5 recorded:
the changesets had never applied anywhere, **including production** - the schema
in any running environment was created by something other than the changelog.

```
$ ./mvnw dependency:tree | grep -i liquibase
[INFO] +- org.liquibase:liquibase-core:jar:5.0.3:compile
```

That single missing module is why lot 22 was a genuine prerequisite of the image
lot and not a formality: `image-smoke.yml` would have been the first place the
changesets ever ran, on the image about to be published.

## Common checklist, item by item

| # | Item | State |
|---|---|---|
| 1 | Branch `chore/harness-adoption` from `develop` | ✅ |
| 2 | `.claude/settings.json`, marketplace + plugin, `"ref": "main"` | ✅ new file |
| 3 | Local skills removed, none project-specific kept | ✅ 8 files deleted, including `sprint` |
| 4 | `CLAUDE.md`: gate parameters, plugin skill names, no sprint chaining, ⛔ LOTD kept, census, `AGENTS.md` mirror | ✅ |
| 5 | `CONVENTIONS.md` = lot 5 master | ✅ `cmp` silent |
| 6 | `ci.yml` calls the lot 3 workflows, `branches: ["**"]`, SHA-pinned actions, `permissions: contents: read`, `concurrency`; `dependabot.yml` | ✅ |
| 7 | `.claude/settings.local.json`: `git push *` and `gh pr *` removed | ✅ (no blanket `git *` was present) |
| 8 | `.gitignore`: `.env`, `*.local.md` | ✅ already compliant |
| 9 | Branch naming documented | ✅ `CLAUDE.md` § Branch naming |
| 10 | Image repo: `image-smoke` via `image-publish` | ✅ both present, commented, uncommented by KB.17 |
| 11 | Gate green + this report | ✅ |
| 12 | Lots file opens with a `\| Lot \| Branche \| Statut \|` table | ✅ first table at line 25, one non-conforming status fixed (`⚠️` → `⬜`, lot 19) |
| 13 | Skills section points non-Claude agents at the local clone | ✅ |
| 14 | No build/push steps written in the repo | ✅ |

kb-specific items: `lot-audit/checklists.md` is no longer a repo file (it ships
with the plugin), so the census entry it asked for does not apply; the remaining
`skill/` references disappeared with `.claude/skills/`; the expand/contract rule
was kept verbatim and extended with the lot 22 consequence.

## Security

| Severity | Location | Finding | Action |
|---|---|---|---|
| Warning | `.claude/settings.local.json` | `Bash(git commit *)`, `Bash(git checkout *)`, `Bash(git rm *)` remain allowed without confirmation. They are not in V3's list and the git guard hook still covers the destructive forms, but `git checkout .` discards uncommitted work silently | Left as is; revisit if the guard ever stops covering it |
| Info | `HARNESS_READ_TOKEN` | `ci.yml` passes it unconditionally; the secret is present on kb (verified at lot 6b) | None |

## Performance

| Severity | Finding | Action |
|---|---|---|
| Warning | The gate went from ~30 s to **54 s**: two PostgreSQL containers start, one shared by the four integration tests and one dedicated to `LiquibaseMigrationIntegrationTest`. Measured locally, cold image already pulled | Accepted. A single shared container would save ~20 s and cost the "applies to an empty database" assertion, which is the point of the test |

## Architecture

| Severity | Finding | Action |
|---|---|---|
| Warning | `PostgresIntegrationTest` starts its container in a static initialiser rather than through `@Testcontainers`/`@Container`. That extension stops the container in each class's `afterAll`, which breaks a container shared by several classes; Ryuk reaps the singleton at JVM exit | Documented in the class javadoc |
| Info | `OpenApiSmokeTest` moved from the `test` profile (H2) to `integration-test`. It now boots against the real schema, which is what a smoke test of the published spec should do | None |

## Harness

| Severity | Finding | Action |
|---|---|---|
| Warning | The test is named `LiquibaseMigrationIntegrationTest`, not `LiquibaseMigrationIT` as `lots.md` specified. Surefire's default includes do not match `*IT`, and matching the spec name would have meant adding `maven-failsafe-plugin` - a new build plugin, so a §4 decision - for one class | Deviation recorded in `kreadevis-backend/lots.md` lot 22 |
| Info | `lint.yml` defaults `java_version` to 21; kb passes `"25"` explicitly | None |

## Validation gate

```
$ ./mvnw verify
Tests run: 203, Failures: 0, Errors: 0, Skipped: 0
All coverage checks have been met.
BUILD SUCCESS  (53.6 s)
```

Negative check, as lot 22 required: pointing changeset 003 at a non-existent
table makes the gate fail with
`liquibase.exception.DatabaseException: ERROR: relation "public.quotes_does_not_exist" does not exist`.
Reverted, not committed.

## What the first real pull request caught

Three red checks on PR #34, none of them a defect in kb. Being the pilot repo,
this is exactly what lot 7 was for - the seven remaining repos inherit the fixes.

| Check | Cause | Fix |
|---|---|---|
| `lint / audit` | OWASP dependency-check 13 builds its database from the NVD API, which now rejects unauthenticated callers (`Invalid API Key, length of 0`). The step aborted before analysing anything, so the "informative" scan reported nothing at all | `lint.yml` takes an optional `nvd_api_key` secret and degrades to an explicit skip without it |
| `lint / audit` (second defect) | The job carried `continue-on-error: true`, which keeps the *run* green but still publishes the check run with conclusion `failure`. The pull request showed red for a signal declared informative - and §7 says a red pull request is never merged, so an informative red check teaches the reader to ignore red | `continue-on-error` moved from the job to the two scan steps; `tests/workflows.test.sh` now asserts the job carries none |
| `migrations-immutable` | The `rollback` block added to the merged changeset `005-backfill-created-by` (deployment amendment C3) is a modification of an existing migration. The workflow is right: it cannot know that this particular changeset had never been applied anywhere | Reverted in `2bc9e83`. The C3 rollback is deferred to the lot that reconciles the production schema with the changelog - the one moment the base has applied nothing and the changeset can still be edited |
| `harness-invariants` | `actions/checkout` of `SelimLBOURAYA/claude-harness` returns **403** with `HARNESS_READ_TOKEN`. The secret exists on kb (set 2026-09-19) but does not grant read on the harness repository - the usual cause is a fine-grained PAT whose repository selection omits it | **Owner action (§4)**, see below |

Harness invariants were replayed locally with the same shell the workflow runs
(mirror, conventions copy, marketplace ref, no `skill/`, 11 gate parameters,
census, lots status table): all pass. The workflows themselves are only
exercisable on the pull request.

## Left open

- **`HARNESS_READ_TOKEN` (owner)**: re-issue or re-scope it so it can read
  `SelimLBOURAYA/claude-harness`. Until then `harness-invariants` is red on
  every adoption pull request, kb's included, and §7 forbids merging them.
- **Harness promotion (owner)**: the consuming repos pin
  `...claude-harness/.github/workflows/*.yml@main`, so the `lint.yml` fix above
  only reaches them once `develop` is promoted to `main`. Adoption PRs stay red
  on `lint / audit` until then.
- The C3 `rollback` block on changeset `005`, see the table above.
- kb lot 17 (image) still ⬜; it uncomments the two image jobs of `ci.yml` with
  the `Dockerfile` and `compose.ci.yml` it adds.
- Production schema provenance: since Liquibase never ran, whatever schema the
  dev and prod databases carry did not come from the changelog. Before the first
  real deployment, `DATABASECHANGELOG` has to be seeded or the schema rebuilt
  from the changesets. Out of this lot's scope, raised to the user.
