# Lot Audit — Lot 9 — meal-planner-backend adoption

**Harness ref:** `chore/harness-adoption-reports`, from `23aa7be`
**Target repo:** `meal-planner-backend`, branch `chore/harness-adoption`, PR #22
**Commits:** `99824b2` (adoption)
**Verdict:** ✅ checklist complete, validation gate green, no Critical.

Scope: the common adoption checklist (items 1 to 14 of `dev-plan.md`) plus the
mpb-specific items. One behaviour change outside pure configuration: the JaCoCo
scope, see below.

## Summary

| Dimension | Critical | Warning | Info |
|---|---|---|---|
| Security | 0 | 2 | 0 |
| Performance | 0 | 0 | 1 |
| Architecture | 0 | 1 | 1 |
| Harness | 0 | 0 | 1 |

## The finding this lot actually uncovered

`dev-plan.md` (harness) described mpb as the repository with "couverture creuse"
and planned "des lots de tests pour remonter vers 0.80". That premise is wrong,
and the direction of the fix is the opposite one.

The 80 % JaCoCo rule was measured on a scope that excluded `auth/**`,
`planning/**`, `shopping/**`, `Recipe` and `Ingredient` — most of the business
code. The number said 80 % of whatever happened to be tested. With the full
scope restored, the measured line coverage is **0.8936** (915/1024 lines;
branches 0.7009, 164/234). The threshold was therefore **raised** to `0.88`, as
a ratchet, and the plan's remediation lot is moot. What the exclusions hid was
not missing tests — it was a meaningless gate.

## Common checklist, item by item

| # | Item | State |
|---|---|---|
| 1 | Branch `chore/harness-adoption` from `develop` | ✅ |
| 2 | `.claude/settings.json`, marketplace + plugin, `"ref": "main"` | ✅ new file |
| 3 | Local skills removed, none project-specific kept | ✅ `skill/` deleted (7 skills, incl. `sprint`), plus `prompt-harness.md` |
| 4 | `CLAUDE.md`: gate parameters, plugin skill names, no sprint chaining, ⛔ LOTD kept, census, `AGENTS.md` mirror | ✅ |
| 5 | `CONVENTIONS.md` = lot 5 master | ✅ `cmp` silent |
| 6 | `ci.yml` calls the lot 3 workflows, `branches: ["**"]`, SHA-pinned actions, `permissions: contents: read`, `concurrency`; `dependabot.yml` | ✅ incl. `migrations-immutable` on `src/main/resources/db/migration` |
| 7 | `.claude/settings.local.json`: `gh pr *` removed | ✅ n/a, the repo had no such file |
| 8 | `.gitignore`: `.env`, `*.local.md` | ✅ both added |
| 9 | Branch naming documented | ✅ `CLAUDE.md` § Workflow item 1 |
| 10 | Front-specific `frontend-dist` call | ✅ n/a, backend |
| 11 | Gate green + this report | ✅ |
| 12 | Lots file opens with a `\| Lot \| Branche \| Statut \|` table | ✅ created at line 12 of `dev-plan.md`, 15 rows |
| 13 | Skills section points non-Claude agents at the local clone | ✅ |
| 14 | No build/push steps written in the repo | ✅ the `docker-build` job is gone; `image-publish` / `image-smoke` stay commented until mpb lot 13 |

mpb-specific items: the JaCoCo scope and ratchet (above), the hard-coded
Postgres password removed, `.env.example` created.

## Security

| Severity | Location | Finding | Action |
|---|---|---|---|
| Warning | `docker-compose.yml` | `POSTGRES_PASSWORD: mealplanner` was committed in clear. Replaced by `${POSTGRES_PASSWORD:?…}` — no default, compose refuses to start without it (CONVENTIONS.md §5) | Fixed in this lot. The value was a local-development password and was never a production credential, but it is in the git history: if it is ever reused, rotate it |
| Warning | `docker-compose.yml` | `ports: "5432:5432"` and the app port publish on `0.0.0.0`, which bypasses UFW on a host that relies on it | Left open: mpb lot 13 already carries "ports publiés sur `127.0.0.1` uniquement" as an explicit deliverable. Not pulled forward into a `chore/` branch |

## Performance

| Severity | Finding | Action |
|---|---|---|
| Info | `./mvnw verify` runs in 33 s, 37 tests. Restoring the JaCoCo scope costs nothing measurable — instrumentation was already active on the whole bundle, only the *check* was narrowed | None |

## Architecture

| Severity | Finding | Action |
|---|---|---|
| Warning | CONVENTIONS.md §2.5 violation, pre-existing: the `*IT` tests run on H2 with `spring.flyway.enabled: false` and `ddl-auto: create-drop` (`src/test/resources/application-test.yaml`). `FlywayMigrationIT` therefore verifies Hibernate's generated DDL, not `V1__initial_schema.sql` — no migration is exercised anywhere in the gate. `dev-plan.md` §2 still advertises "Tests: JUnit 5, Spring Boot Test, H2" as if that were the target state | Left open: mpb lot 13 already makes the Testcontainers `postgres:17` switch mandatory (was optional before audit P5). Flagged here so that the 0.8936 figure is not read as stronger evidence than it is — it is H2 coverage |
| Info | `CLAUDE.md` § Stack says "Prod DB: PostgreSQL 16" while lot 13 aligns on 17. Left as-is: the statement is true today, and the lot that changes it updates it | None |

## Harness

| Severity | Finding | Action |
|---|---|---|
| Info | mpb is the first adopting repo whose lots file is `dev-plan.md` rather than `lots.md`, and the first to call `migrations-immutable.yml` with a Flyway (not Liquibase) directory. Both inputs behaved as designed; no workflow change was needed for this lot | None |

## Validation gate

```
$ JWT_SECRET=… ./mvnw verify
Tests run: 37, Failures: 0, Errors: 0, Skipped: 0
jacoco:check — All coverage checks have been met.
BUILD SUCCESS  Total time: 33.437 s
```

Harness invariants were replayed locally with the same shell the workflow runs
(mirror `cmp`, conventions copy, marketplace ref, no `skill/`, 11 gate
parameters, census over the 13 audit reports, lots status table at line 12, no
calendar commitment): all pass.

## Left open

- **mpb lot 13** carries three items this audit refuses to pull forward:
  Testcontainers `postgres:17` with Flyway active, ports bound to `127.0.0.1`,
  and uncommenting the two image jobs.
- The two owner actions of `docs/audits/lot-7.md` apply here identically:
  `HARNESS_READ_TOKEN` cannot read the harness (403), so `harness-invariants`
  fails on this pull request for a reason no commit in this repo can fix; and
  the `lint.yml` fixes only reach this repo once the harness `develop` is
  promoted to `main`.
