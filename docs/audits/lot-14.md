# Lot Audit — Lot 14 — summerize-youtube adoption

**Harness ref:** `chore/sync-lot-12-status`, from `317469e`
**Workflows actually executed:** `@main`, i.e. `a0de7d1`
**Target repo:** `summerize-youtube`, branch `chore/harness-adoption`
**Commits:** `8de293c`, `8ba257e`, `16e12b9`
**Scope:** 15 files, +548 −563 | **Verdict:** Ready for PR — checklist complete,
no Critical in the lot's own diff. One **Critical** portfolio finding was
discovered by this audit and is recorded below: it is not caused by this lot and
cannot be fixed inside it.

`summerize-youtube` is the last of the eight adoptions and the easiest of them,
because there is nothing to break: the project is frozen before its lot 00, with
no `package.json`, no `src/`, and no image. What it had instead was the portfolio's
last surviving copy of the old harness — seven `SKILL.md` files under `skill/`, a
directory Claude Code never scanned, including the `sprint` skill that the
stop-after-PR decision removed everywhere else.

## Summary

| Dimension | Critical | Warning | Info |
|---|---|---|---|
| Security | 0 | 0 | 4 |
| Performance | 0 | 0 | 1 |
| Architecture | 0 | 1 | 2 |
| Harness | 1 | 2 | 1 |

## The two decisions this lot had to make

Both were put to the user before any file was written, because both are values
`ci.yml` reads and neither has a defensible default.

**1. `Stack` is `other`, not `backend`.** The harness stack vocabulary is
`backend | frontend | harness | other`, where `backend` means Java/Maven
(spotless, dependency-check, `src/main/java`) and `frontend` means npm (prettier,
eslint, `npm audit`). This is a **Node backend**, which none of them describes.
Called with `backend`, `lint.yml` installs Java, looks for a `pom.xml` that does
not exist and skips every step — two green checks that ran nothing. Called with
`frontend` it runs the right tools for the wrong reason, and `lot-deliverables.yml`
then demands an `integration-check` report from a service that has no frontend at
all, Notion being its consultation layer. `other` is the honest value; the `lint`
job is not called, and the reason is written in `ci.yml` where the next reader
meets it.

This is the second repository to land on `other` for want of a branch in
`lint.yml` — `deployment` was the first, at lot 13. See Harness.

**2. `Coverage threshold` is `0`, not `0.80`.** `dev-plan.md` section 6 commits to
a Jest gate failing the build under 80 %, and `CLAUDE.md` announced it. There is
no source file: a threshold above zero applied to an empty scope passes whatever
the tests do and turns real without warning at the first file that appears, which
is precisely what lot 17 was written to refuse. The row now reads `0` with the
reason inline, and lot 00 — the lot that creates the skeleton — raises it to
`0.80` in the same commit as the first code, as a ratchet.

Note that `harness-invariants` would **not** have caught the fiction here: its
lot 17 step resolves the source layout from `Stack`, and on `other` it exits with
a notice. The two decisions interact, and only the second one is load-bearing.

## Common checklist, item by item

| # | Item | State |
|---|---|---|
| 1 | Branch `chore/harness-adoption` from `develop` | Yes, from `a625200` |
| 2 | `.claude/settings.json`, marketplace + plugin, `"ref": "main"` | New file; `jq -e` on the ref and on `enabledPlugins` passes |
| 3 | Local skills removed, project-specific ones kept | Seven `skill/*/SKILL.md` deleted, all generic. None was project-specific, so no `.claude/skills/` is created; `CLAUDE.md` records that there is none to keep in sync |
| 4 | `CLAUDE.md`: gate parameters, plugin skill names, no sprint chaining, LOTD block kept, census, `AGENTS.md` mirror | `cmp` silent. The `sprint` skill and its row are gone; the LOTD block is kept and extended from three steps to four |
| 5 | `CONVENTIONS.md` = lot 5 master | Was stale from byte 83; re-copied, `cmp` against `origin/main:CONVENTIONS.md` silent |
| 6 | `ci.yml` calls the lot 3 workflows, `branches: ["**"]`, SHA-pinned actions, `permissions: contents: read`, `concurrency`; `dependabot.yml` | Three actions, each pinned by SHA with a version comment |
| 7 | `.claude/settings.local.json`: `git push *`, `gh pr *`, `git *` removed | No such entries: the file holds `Skill(claude-api)` and `WebSearch` only, and is untracked, as in every other adopted repo |
| 8 | `.gitignore`: `.env`, `*.local.md` | Both already present since the first commit |
| 9 | Branch naming documented | `CLAUDE.md` § Workflow: `feat/lot-XX-<short-description>`, replacing the `lot-XX-slug` form the file carried, which `branch-naming.yml` would have rejected |
| 10 | Image / frontend workflows | n/a today — lot 07 dockerises and publishes `ghcr.io/selimlbouraya/summerize-youtube`; `ci.yml` says which lot uncomments the two jobs |
| 11 | Gate green + this report | See Validation gate |
| 12 | Lots file opens with a `\| Lot \| Branche \| Statut \|` table | `dev-plan.md` had no such table; added at line 12, 12 rows, statuses frozen, legend included |
| 13 | `CLAUDE.md` § Skills: pointer to the local harness clone for non-Claude agents | Yes |
| 14 | Image repo: the image lot calls `image-publish.yml` | n/a until lot 07, stated in `ci.yml` |

Item 12 needed the user's explicit approval and got it: `dev-plan.md` carries a
rule forbidding any edit beyond its `Status` column. The scope sections below the
new table are untouched and remain the authority; the table is a view over them.

Three departures from `templates/ci-caller.yml`, each commented in the file:

- **No `paths-ignore`.** Same reasoning as lot 13: what this repository ships
  today is documentation, and `harness-invariants` checks exactly those files.
  With `paths-ignore: ["**.md"]` a push breaking the `CLAUDE.md` / `AGENTS.md`
  mirror would trigger no job. Lot 07 adds it back with the image.
- **No `lint` job.** See the `Stack` decision above.
- **The validation gate guards on `package.json`.** `npm run lint && npm run
  test:cov` has nothing to run before lot 00. The guard reports the skip in the
  job summary rather than exiting 0 in silence, and lot 00 deletes it.

## Security

The `security-review` skill was invoked as step 2 of `lot-audit` prescribes, but
it collected its diff from the session's working directory (`claude-harness`)
instead of the audited repository, and analysed the lot 13 documentation commits.
Its output is discarded as out of scope. The review below was done by hand against
the checklist, on the correct diff. **This is a skill defect, filed under Harness.**

| Severity | Location | Finding | Action |
|---|---|---|---|
| Info | `.github/workflows/ci.yml` | No `${{ }}` interpolation reaches any `run:` block — the only three occurrences are the `concurrency` key, its `cancel-in-progress` expression, and `secrets.HARNESS_READ_TOKEN` passed through a `secrets:` mapping to the reusable workflow. Workflow injection has no entry point | None |
| Info | `.github/workflows/ci.yml` | Trigger is `pull_request`, never `pull_request_target`: a fork PR runs without repository secrets and cannot reach the trust boundary. `permissions: contents: read` is declared at file level and no job raises it | None |
| Info | `.github/workflows/ci.yml` | The three actions are pinned by commit SHA (`actions/checkout` v7.0.1, `actions/setup-node` v7.0.0, `actions/upload-artifact` v7.0.1), so a tag re-point cannot change what runs (P5-#9). The reusable workflows are pinned to `@main` of a private repository under the owner's sole control — a mutable ref, and the deliberate design: the eight repos follow the harness production branch | None |
| Info | whole diff | No secret, credential, token or absolute user path is introduced. `.claude/settings.json` declares a marketplace source and nothing else. `dependabot.yml` carries no token | None |

Once lot 00 lands, `npm ci` will execute dependency lifecycle scripts in CI. That
is the normal cost of a Node build, bounded here by `contents: read` and by the
absence of any secret in the `validate` job.

## Performance

| Severity | Finding | Action |
|---|---|---|
| Info | Nothing runtime is touched; there is no runtime yet. The `validate` job is a checkout and a file test until lot 00 | None |

## Architecture

| Severity | Location | Finding | Action |
|---|---|---|---|
| Warning | Gate parameters | The repository has **no executable guarantee** about anything: the validation gate is a declared no-op, and `Stack: other` means no lint either. It is protected by `harness-invariants`, `commit-format` and `branch-naming` — document guards only. This is honest rather than hidden, which is the improvement, but a declared zero is still a zero | Lot 00 ends it: skeleton, gate, and the `0.80` threshold in the same commit. Tracked in the `dev-plan.md` status table |
| Info | `.github/dependabot.yml` | The `npm` ecosystem is declared before `package.json` exists. Dependabot reports an unused ecosystem and opens nothing, so lot 00 inherits its dependency watch without a second config commit. No `docker` block: there is no Dockerfile before lot 07 | None |
| Info | `README.md` | The repository layout block still advertised `skill/` and a hard-coded 80 % coverage figure; both corrected, the threshold now pointing at the Gate parameters table as its single source | Fixed in `16e12b9` |

## Harness

| Severity | Location | Finding | Action |
|---|---|---|---|
| **Critical** | `harness-invariants.yml` + the GitHub Dependabot secret store, **all eight repos** | `harness_token: ${{ secrets.HARNESS_READ_TOKEN }}` resolves to the **empty string** on a Dependabot-triggered `pull_request`: Dependabot runs read a separate secret store, and `HARNESS_READ_TOKEN` exists only in the Actions store on every repo checked (`kreadevis-backend`, `elya-frontend`, `meal-planner-backend`, `deployment`, `summerize-youtube` — Dependabot store empty on all five). The workflow then falls back to `secrets.harness_token \|\| github.token`, which is scoped to the calling repository and cannot see the private harness: `fatal: repository 'https://github.com/SelimLBOURAYA/claude-harness/' not found`, exit 128. **Verified live**, not deduced: `kreadevis-backend` PR #39 (run `35505459702`, job `106064388294`) shows `harness-invariants / invariants` red, with five Dependabot PRs open in that state. Consequence: the weekly dependency PR is **structurally red** in a portfolio whose only merge lock is "never merge a red PR" (no branch protection on the free plan, P6-D1). Every week this teaches the reader that a red `harness-invariants` is normal — the exact erosion P5-#11 recorded on elya | **User action, GitHub setting, same shape as lot 6b**: add `HARNESS_READ_TOKEN` to the **Dependabot** secret store of the eight repos (`gh secret set HARNESS_READ_TOKEN --app dependabot --repo <repo>`). Outside this lot's scope — it is a portfolio-wide setting, not a file in `summerize-youtube`. **Proposed as a blocking item of lot 15**, whose job is exactly the control re-audit and the promotion checklist |
| Warning | `lint.yml` | Still no branch for anything but Java and npm-frontend. Two repositories have now landed on `Stack: other` to avoid two green checks that ran nothing — `deployment` (shell + compose) at lot 13, and this one (Node backend). A Node backend branch is a near-duplicate of the existing frontend branch, minus `frontend-dist` | Proposed for lot 15, alongside the `other` branch lot 13 already asked for. Recorded, not changed: a harness edit during an adoption lot is out of scope |
| Warning | `lot-audit` skill, step 2 | `Skill(security-review)` collects its diff from the session's working directory, with no way to point it at another repository. Every adoption lot audits a repo that is not the one the session is rooted in, so the security step has silently reviewed the **wrong diff** each time it was invoked this way. Caught here only because the returned diff was recognisably lot 13's | Proposed for lot 15: `lot-audit` must either `cd` into the target repo before invoking the skill, or state in the report that the manual checklist was used. This audit used the manual checklist and says so |
| Info | gate allégé vs `lot-audit` step 0 | `lot-audit` stops when `docs/audits/lot-N-review.md` is missing. No adoption lot from 7 to 14 has one: the `Gate allégé des lots de remédiation` of `dev-plan.md` defines three items — tests, audit, validation gate — and no review step. The plan won here, as it did for the seven preceding lots | Unchanged from lot 13's finding; lot 15 resolves the contradiction in one direction or the other |

## Coverage exclusions

| Exclusion | Business code? | Proposed action |
|---|---|---|
| (none) | – | None declared. `Coverage threshold` is `0` with the reason written down, so there is no number to inflate and nothing to hide behind an exclusion. Lot 00 sets `0.80` and may then declare exclusions, which `harness-invariants` will check against `coverage_infra_packages` |

## Migrations

`Migrations directory` is `n/a` and the `migrations-immutable` job is not called.
Prisma migrations arrive at lot 01, under `prisma/migrations/`; that lot adds the
job in the same commit as its first changeset, and the expand/contract rule of
CONVENTIONS.md section 7 starts applying there.

## Validation gate

```
$ npm run lint && npm run test:cov
```

Not runnable: there is no `package.json`. This is the declared state of the
repository, not a skipped step — `ci.yml` detects it, writes
`validation gate: **skipped**, no package.json yet (pre-lot-00)` into the job
summary, and lot 00 removes the guard.

Invariants replayed against the working tree before the push, each one the shell
of the corresponding `harness-invariants.yml` step:

| Check | Result |
|---|---|
| `cmp CLAUDE.md AGENTS.md` | silent |
| `CONVENTIONS.md` vs `origin/main` master | silent after the re-copy |
| `jq -e '…source.ref == "main"'` and plugin enabled | true |
| no `skill/` directory | ok, seven files removed |
| 11 gate parameter rows present | ok |
| coverage threshold has a subject (lot 17) | threshold `0`, accepted as an honest zero |
| no exclusion covers a business package (lot 17) | no exclusion declared |
| census covers every skill and report | ok, nothing under `.claude/skills` or `docs/audits` |
| lots file opens with a status table | line 12, header `\| Lot \| Branche \| Statut \| Objectif \|` |
| every status row carries an emoji | ok, 12 rows |
| no calendar commitment | ok |
| `ci.yml`, `dependabot.yml` parse as YAML; `settings.json` as JSON | ok |

Repository prerequisites from lot 6b, verified on this repo: visibility
`PRIVATE`, default branch `develop`, `HARNESS_READ_TOKEN` present in the Actions
secret store — and **absent** from the Dependabot store, which is the Critical
above.

## Left open

1. **The Dependabot token gap makes eight repos structurally red once a week.**
   The single most consequential finding of the adoption wave, and the only one
   that needs an owner action rather than a commit. See Harness.
2. **`lint.yml` covers two of the four stacks it accepts.** Two repositories now
   opt out rather than produce vacuous green.
3. **`lot-audit`'s security step audits the session's directory.** Every
   cross-repo audit is affected retroactively; lots 7 to 13 should be assumed to
   have had no automated security step.
4. **This repository still guarantees nothing executable.** Lot 00 is what
   changes that, and it is frozen until elya is deployed.

## Recommended next steps

1. Open the PR on `summerize-youtube` and merge it once the checks are green.
2. Set `HARNESS_READ_TOKEN` in the Dependabot secret store of the eight repos.
3. Lot 15 — the control re-audit — takes the three harness findings above plus
   lot 13's `other` branch request.

## Recommended lot

None. The adoption wave ends here, and lot 15 already exists with exactly the
right scope for the four items in "Left open". The Critical is added to it as a
blocking prerequisite rather than opening a lot of its own, because it is a
GitHub setting on eight repositories — the same shape as lot 6b, which is also a
user-executed settings lot.
