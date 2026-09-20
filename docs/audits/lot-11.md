# Lot Audit — Lot 11 — elya adoption

**Harness ref:** `chore/harness-adoption-reports`, from `8148c96`
**Target repo:** `elya`, branch `chore/harness-adoption`, PR #16
**Commits:** `cc86684` (adoption)
**Verdict:** ✅ checklist complete after one fix applied here, validation gate
green, no Critical.

Scope: the common adoption checklist (items 1 to 14 of `dev-plan.md`) and the
elya-specific items. No runtime code is touched: the diff is CI, plugin
declaration and documentation, plus the removal of the local `skill/` directory.

## Summary

| Dimension | Critical | Warning | Info |
|---|---|---|---|
| Security | 0 | 1 | 2 |
| Performance | 0 | 0 | 1 |
| Architecture | 0 | 1 | 1 |
| Harness | 0 | 2 | 1 |

## The finding this lot actually uncovered

The JaCoCo gate on elya is declared at `0.80` and it measures nothing.

`./mvnw verify` ends with `Analyzed bundle 'elya' with 0 classes` followed by
`All coverage checks have been met.` The repository has exactly two classes in
`src/main/java` — `ElyaApplication` and `config/FlywayConfig` — and the
`Coverage exclusions` of the Gate parameters (`com/elya/config/**`,
`com/elya/web/dto/**`, `com/elya/ElyaApplication.class`) cover both. The bundle
the rule is applied to is therefore empty, and an empty bundle satisfies every
ratio rule there is.

Nothing is wrong with the exclusions: none of them covers business code, because
there is no business code yet (elya lot 1.3 is still ⬜). What is wrong is that
the gate reads as a guarantee. The first commit that adds a class outside those
three patterns puts the 0.80 rule into force in the same run, without warning,
on code written in that same commit.

This is the third consecutive adoption lot where the coverage number turned out
not to measure what it claims — mpb (lot 9, exclusions hiding most of the
business code), mpf (lot 10, `Lines 100 % (1/1)`), elya (this lot, zero
classes). See the Recommended lot section.

## Common checklist, item by item

| # | Item | State |
|---|---|---|
| 1 | Branch `chore/harness-adoption` from `develop` | ✅ |
| 2 | `.claude/settings.json`, marketplace + plugin, `"ref": "main"` | ✅ new file |
| 3 | Local skills removed, none project-specific kept | ✅ 7 files deleted, including `sprint` |
| 4 | `CLAUDE.md`: gate parameters, plugin skill names, no sprint chaining, ⛔ LOTD kept, census, `AGENTS.md` mirror | ✅ `cmp` silent |
| 5 | `CONVENTIONS.md` = lot 5 master | ✅ `cmp` silent |
| 6 | `ci.yml` calls the lot 3 workflows, `branches: ["**"]`, SHA-pinned actions, `permissions: contents: read`, `concurrency`; `dependabot.yml` | ✅ three actions pinned by SHA with a `# vX.Y.Z` comment |
| 7 | `.claude/settings.local.json`: `git push *`, `gh pr *`, `git *` removed | ⚠️ **not done by the adoption commit** — fixed during this audit, see Security |
| 8 | `.gitignore`: `.env`, `*.local.md` | ✅ both already present; the lot adds `.claude/settings.local.json` |
| 9 | Branch naming documented | ✅ `CLAUDE.md` § Branch naming, and `LOTS.md` moved off `feat/lot-N-M-slug` |
| 10 | Image repo: `image-smoke` via `image-publish` | ✅ both present, commented, uncommented by elya LOT 6 |
| 11 | Gate green + this report | ✅ |
| 12 | Lots file opens with a `\| Lot \| Branche \| Statut \|` table | ✅ at line 8, 12 rows, statuses all among ⬜ 🔄 ✅ ⏸️ ❄️ |
| 13 | Skills section points non-Claude agents at the local clone | ✅ |
| 14 | No build/push steps written in the repo | ✅ |

elya-specific items (`dev-plan.md` LOT 11): stack facts corrected (Raspberry Pi
gone from the four places it survived, frontend stated as Angular 21 with the
21 → 22 bump named as an `elya-frontend` lot per P6-D7), the sprint-chaining
contradiction removed, `SchemaMigrationIT` kept, `Health path = /health` and
`Image name = ghcr.io/selimlbouraya/elya` recorded in the Gate parameters. All ✅.

## Security

Step 2 of `lot-audit` prescribes `Skill(security-review)`. It was invoked twice
and did not audit this lot — see the Harness section. The manual checklist of
`lot-audit/checklists.md` was applied instead, as that skill's own fallback
instructs.

| Severity | Location | Finding | Action |
|---|---|---|---|
| Warning | `.claude/settings.local.json` | The file still allowed `Bash(git *)` and `Bash(gh pr *)`, which checklist item 7 names explicitly. V3 (lot 0) established that the plugin's `PreToolUse` guard returns `deny` and `ask` even against an allow-list entry, so the destructive forms stayed blocked; what the blanket entry removed was the confirmation tier on every ordinary `git push` and `gh pr create` | **Fixed in this audit**: both entries removed. The file is gitignored, so the change is local-only and appears in no diff — `git status` stays clean |
| Info | `.github/workflows/ci.yml` | `HARNESS_READ_TOKEN` and `NVD_API_KEY` are passed through `secrets:` to the reusable workflows and never echoed, interpolated into a `run:` block or written to a summary. `permissions: contents: read` is declared at file level, so the callers inherit the minimum | None |
| Info | whole diff | No secret, credential, token or absolute user path (`/home/selim/…`) is committed by this lot. `.env` and `*.local.md` were already ignored | None |

## Performance

| Severity | Finding | Action |
|---|---|---|
| Info | No runtime code is touched, so there is nothing to measure. The gate itself runs in 14.7 s locally, `SchemaMigrationIT` included (Testcontainers pulls `postgres:17` once) | None |

## Architecture

| Severity | Location | Finding | Action |
|---|---|---|---|
| Warning | `pom.xml` / Gate parameters | The `0.80` JaCoCo threshold is applied to an empty bundle, see above. It will start gating, silently, at the first business class | Raised against elya LOT 1.3; not fixed here, because pinning a threshold requires code to measure |
| Info | `.github/workflows/ci.yml` | The `image-publish` and `image-smoke` jobs ship commented out. §3 forbids commented-out code, but here it is the plan's explicit instruction (P6-D9): LOT 6 uncomments both in the same commit as the `Dockerfile` and `compose.ci.yml`, and the comment block states that | None |

## Harness

| Severity | Location | Finding | Action |
|---|---|---|---|
| Warning | `lot-audit/SKILL.md` step 2 | `Skill(security-review)` resolves its diff from the **session's working directory**, not from the audited repository. Invoked from a `claude-harness` session to audit `elya`, it returned the diff of `chore/harness-adoption-reports` — a review of the wrong repository, which a report would have recorded as this lot's security step | Fallback checklist applied and recorded here. The skill needs either a repository argument or an explicit instruction that a cross-repo audit runs from a session opened in the target repo |
| Warning | local clones | Both clones had no `refs/remotes/origin/HEAD`, so `security-review` aborted outright on `git log origin/HEAD...` before any review. Set with `git remote set-head origin -a` in `claude-harness` and `elya`. The other six repos are presumably in the same state | The skill should not depend on a ref that `git clone --branch` does not always create |
| Info | *(P5-#11 recall, as the plan requires)* | elya's CI was red **from 2026-07-10 to 2026-09-17**, longer than the 2026-08-06 the plan records — 21 failing runs, cause a broken Maven wrapper URL, fixed by `chore/fix-maven-wrapper-url`. Pull requests were merged throughout. With no branch protection available (P6-D1), the only guard is `lot-ship` refusing a red `gh pr checks`, plus the reviewer | None; recorded |

## Coverage exclusions

| Exclusion | Business code? | Proposed action |
|---|---|---|
| `com/elya/config/**` | No — `FlywayConfig` only, today | Keep; re-examine when `config/` gains security configuration (LOT 5) |
| `com/elya/web/dto/**` | No — the package does not exist yet | Keep |
| `com/elya/ElyaApplication.class` | No | Keep |

None hides business code. They are nonetheless why the measured bundle is empty,
see Architecture.

## Migrations

`Migrations directory` is `src/main/resources/db/migration/`. This lot touches
no file in it: `V1__init_schema.sql` is byte-identical to `develop`. No
expand/contract question arises. `migrations-immutable` is green on PR #16, and
`SchemaMigrationIT` executes the changeset against a real `postgres:17`, which
is the portfolio model P5-#7 asks the other backends to copy.

## Validation gate

```
$ ./mvnw verify
Tests run: 2, Failures: 0, Errors: 0, Skipped: 0  -- com.elya.SchemaMigrationIT
jacoco:check — Analyzed bundle 'elya' with 0 classes
All coverage checks have been met.
BUILD SUCCESS — 14.7 s
```

PR #16: 16 checks, 16 pass, 0 fail — `harness-invariants`, `commit-format`,
`branch-naming`, `lot-deliverables`, `migrations-immutable`, `lint` and
`validate`. Unlike lots 7 to 10, this PR's runs did **not** fail at workflow
load: the `develop` → `main` promotion carrying `enforce` and the `lint.yml`
secrets block has happened since.

## Recommended lot

**Reason**: the same Warning — a coverage figure that does not measure the code
it claims to — now appears on three consecutive adoption lots (9, 10, 11),
which is the second trigger in `lot-audit`'s enrichment rule.

The three repositories fail differently (exclusions, no specs, no classes), so
there is nothing to fix in a single place. What is missing is the check that
would have caught all three: `harness-invariants.yml` reads the
`Coverage threshold` row already, and could fail when a repository's own
coverage run reports an empty or near-empty analysed bundle while declaring a
non-zero threshold.

**Approved and delivered on this branch**, in reduced form. Two static checks
were added to `harness-invariants.yml`, neither of which reads a coverage report
or runs a build:

1. a numeric, non-zero `Coverage threshold` requires at least one source file
   outside the `Coverage exclusions` patterns — the elya case;
2. no exclusion pattern may cover a business package, the segment list being the
   `coverage_infra_packages` input — the mpb case, the one that did the damage.

Both are exercised for real by `tests/workflows.test.sh`: the shell is extracted
from the workflow and run against fixture repositories, because a grep would have
passed on all three of the repositories that motivated the lot.

The third possibility — having CI read the coverage report itself — was set
aside: it would impose an artefact name and format contract on all 8 repos, or a
build duplicating `validate`. Four repos of eight are adopted; the question is
settled at lot 15, with the full picture.

Affected files: `.github/workflows/harness-invariants.yml`,
`templates/ci-caller.yml`, `tests/workflows.test.sh`, `dev-plan.md`.

**Consequence for this lot**: the new check was run against the five adoption
branches. kb (`0.70`, 62 files), kf (`79`, 43), mpb (`0.88`, 66) and mpf
(threshold `0`) pass; elya failed, which is this report's own finding.

Fixed on elya in `97a432f`, on the same PR #16: the `<minimum>` of `pom.xml` and
the `Coverage threshold` row both drop to `0` with the reason written in each,
and elya LOT-1.3 — the first ticket producing classes outside the exclusions —
now carries the deliverable that measures the real level and raises it. Not a
relaxation of the ratchet: there was nothing to measure, and an empty bundle
satisfies every ratio rule. `./mvnw verify` stays green, and both new invariant
steps now pass on elya.

## Left open

- **elya LOT 1.3** inherits the coverage question: the first business class puts
  the 0.80 rule into force in its own commit.
- **elya LOT 6** uncomments the two image jobs and adds the `Dockerfile`,
  `compose.ci.yml` and the `docker` dependabot ecosystem, all in one commit.
- **elya-frontend** carries the Angular 21 → 22 bump (P6-D7); `CLAUDE.md:18`
  moves to 22 only after that lot lands, never before.
- The five other clones very likely have no `origin/HEAD` either, see Harness.
