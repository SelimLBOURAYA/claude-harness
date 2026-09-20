# Lot Audit — Lot 12 — elya-frontend adoption

**Harness ref:** `chore/sync-dev-plan-status`, from `14d7250`
**Workflows actually executed:** `@main`, i.e. `e87839c`
**Target repo:** `elya-frontend`, branch `chore/harness-adoption`, PR #11
**Commits:** `1575976` (adoption)
**Verdict:** ✅ checklist complete, validation gate green, 16 checks green on the
PR, no Critical. Two debts opened deliberately and written into elya-frontend
lot 1.

Scope: the common adoption checklist (items 1 to 14 of `dev-plan.md`) and the
elya-frontend-specific items. No runtime code is touched: the diff is CI, plugin
declaration, documentation, the removal of the local `skill/` directory, and the
Prettier pass the `lint` job would otherwise have failed on.

## Summary

| Dimension | Critical | Warning | Info |
|---|---|---|---|
| Security | 0 | 0 | 3 |
| Performance | 0 | 0 | 1 |
| Architecture | 0 | 2 | 1 |
| Harness | 0 | 2 | 1 |

## The finding this lot actually uncovered

**Prettier and the harness documents pull in opposite directions.**

`lint.yml` runs `npx prettier --check .` as soon as the repository carries a
Prettier configuration, and `.prettierrc` has been committed here since the
skeleton. On the adopted tree that check reported 11 files, `CONVENTIONS.md`,
`CLAUDE.md`, `AGENTS.md` and `lots.md` among them. Formatting those four is
exactly what `harness-invariants.yml` forbids: `CONVENTIONS.md` must stay
byte-identical to the harness master, and `AGENTS.md` byte-identical to
`CLAUDE.md`. Running `prettier --write .` on this repository turns the
invariants job red; not running it turns the lint job red.

kreadevis-frontend hit the same wall at lot 8 and answered with a
`.prettierignore` listing the harness-governed paths, but that file is in the
repository, not in the harness: nothing propagates it, and nothing tells the
next adopted frontend it exists. This lot copies kf's file verbatim rather than
inventing a second answer, and the Harness section records that it belongs in
`templates/project/`.

Five files remained: `README.md`, `angular.json`, `src/index.html`,
`tsconfig.app.json`, `tsconfig.spec.json`. They were formatted here — 19
insertions, 29 deletions, no semantic change — because an adoption that leaves
the first CI run red is not an adoption.

## Second finding — the coverage figure, for the fourth time

`Coverage threshold` was `80` lines, and the run reports `Lines 100 % (2/2)`.

The `@angular/build:unit-test` builder instruments only what a spec imports. The
suite holds one spec, `src/app/app.spec.ts`, which imports `app.ts` alone:
`app.config.ts`, `app.routes.ts`, `main.ts` and `core/http/api-base-url.token.ts`
never appear in the report at all. The 80 was satisfied by two lines of a
five-file application.

Lowered to `0` with the reason written into `CLAUDE.md`, as mpf and elya did.
`angular.json` is strict JSON and the builder schema rejects an unknown key —
`Data path "/coverageThresholds" must NOT have additional properties(_comment)`,
verified — so the reason lives in `CLAUDE.md` alone and the figure stands bare.
elya-frontend lot 1 carries the deliverable: instrument every file under `src/`,
read the real number, set the threshold to it. A ratchet only goes up.

Fourth consecutive adoption with this shape: mpb (lot 9), mpf (lot 10), elya
(lot 11), elya-frontend (this lot). The lot 17 invariant now refuses a non-zero
threshold with no subject — but it was **not** exercised here: the workflows run
from `@main`, and `main` is still `e87839c`, which predates lot 17. The two new
steps were replayed by hand against this tree instead, and both pass.

## Third finding — the production bundle already carries the forbidden literal

`environment.ts` ships `apiBaseUrl: 'http://localhost:8080'` with
`production: true`. `angular.json` declares `fileReplacements` in the
**development** configuration only, so the production build compiles
`environment.ts` itself, and `app.config.ts` imports it on the bootstrap path to
provide `API_BASE_URL`. Verified on the real bundle: one match for
`localhost:8080` in `dist/elya-frontend/browser/main-R7YFHMDO.js`.

`frontend-dist` therefore runs with `enforce: false` — the lot 8 mechanism,
which annotates in `::warning::` and writes a `report-only` line in the job
summary instead of publishing a failed check run. It is green on PR #11, in
report-only mode.

This is not a new defect: the deployability audit of 2026-09-17 recorded it, and
elya-frontend lot 1 already carried `apiBaseUrl: ''` in its scope with
`grep -r "localhost:8080" dist/` coming back empty as an acceptance criterion.
What this lot adds is the instruction to flip `enforce` back to `true` in that
same lot, written in `lots.md` and in the `ci.yml` comment, so the tolerance
cannot outlive its reason.

## Common checklist, item by item

| # | Item | State |
|---|---|---|
| 1 | Branch `chore/harness-adoption` from `develop` | ✅ from `f972d93`, after the user merged PR #10 |
| 2 | `.claude/settings.json`, marketplace + plugin, `"ref": "main"` | ✅ new file, `jq -e` on the ref passes |
| 3 | Local skills removed, none project-specific kept | ✅ 8 files deleted, `sprint` and `i-have-adhd` included; no `.claude/skills/` created, nothing here is project-specific |
| 4 | `CLAUDE.md`: gate parameters, plugin skill names, no sprint chaining, ⛔ LOTD kept, census, `AGENTS.md` mirror | ✅ `cmp` silent; the "Sprint chaining" paragraph is gone and replaced by "No lot chaining" |
| 5 | `CONVENTIONS.md` = lot 5 master | ✅ `cmp` against `origin/main:CONVENTIONS.md` silent |
| 6 | `ci.yml` calls the lot 3 workflows, `branches: ["**"]`, SHA-pinned actions, `permissions: contents: read`, `concurrency`; `dependabot.yml` | ✅ three actions pinned by SHA with a `# vX.Y.Z` comment; dependabot trimmed to npm + github-actions |
| 7 | `.claude/settings.local.json`: `git push *`, `gh pr *`, `git *` removed | ✅ no such file in this repo; the path is now gitignored so a future one stays local |
| 8 | `.gitignore`: `.env`, `*.local.md` | ✅ `*.local.md` was present; the lot adds `.env`, `.env.*`, `!.env.example` and `.claude/settings.local.json` |
| 9 | Branch naming documented | ✅ `CLAUDE.md` § Branch naming; `lots.md` already used `feat/lot-N-slug` |
| 10 | Frontend: `frontend-dist.yml` with the Gate parameters pattern | ✅ `localhost:8080`, `enforce: false`, see above |
| 11 | Gate green + this report | ✅ |
| 12 | Lots file opens with a `\| Lot \| Branche \| Statut \|` table | ✅ moved to line 5, 17 rows, every row carries a status among ⬜ 🔄 ✅ ⏸️ ❄️ |
| 13 | `CLAUDE.md` § Skills: pointer to the local harness clone for non-Claude agents | ✅ |
| 14 | Image repo: the image lot calls `image-publish.yml` | ✅ both jobs shipped commented, uncommented by elya-frontend lot 12 |

Two rows needed work that the checklist does not name:

- **Item 12 had to be more than a move.** Four rows of the status table carried
  no status at all — lots 10, 11, 13 and 17, dissolved or merged into another
  lot. `harness-invariants` requires one of ⬜ 🔄 ✅ ⏸️ ❄️ on every row of the
  first table, so they now read ❄️, and a `| H | chore/harness-adoption |` row
  was added as mpf did.
- **The calendar-commitment check fired on a false positive.** Its pattern is a
  date followed by `livraison|cible|target|deadline`, and `lots.md` said
  "décision 2026-07-13 — l'ancienne cible `arm64`" — a CPU architecture, not a
  delivery date. Reworded to "l'ancienne architecture `arm64`". The check is
  right to be blunt, but this is the kind of hit a future adopter will also get.

## Security

| Severity | Location | Finding | Action |
|---|---|---|---|
| Info | `.github/workflows/ci.yml` | `HARNESS_READ_TOKEN` and `NVD_API_KEY` are passed through `secrets:` to the reusable workflows, never echoed, interpolated into a `run:` block or written to a summary. `permissions: contents: read` is declared at file level | None |
| Info | whole diff | No secret, credential, token or absolute user path (`/home/selim/…`) is committed by this lot | None |
| Info | `lint / audit` | `npm audit --audit-level=high` passes on the PR. The bundle embeds no secret by construction: everything an Angular build ships is public, and the session JWT lives in an HttpOnly cookie the frontend never reads | None |

## Performance

| Severity | Finding | Action |
|---|---|---|
| Info | No runtime code is touched. The gate runs in ~4 s locally (build 1.9 s, Vitest 2.05 s) and the whole CI run in 1 m 3 s | None |

## Architecture

| Severity | Location | Finding | Action |
|---|---|---|---|
| Warning | `angular.json` / Gate parameters | The coverage threshold measured two lines of one file, see above | Lowered to `0` with the reason written down; raised by elya-frontend lot 1, which owns the instrumentation change |
| Warning | `src/environments/environment.ts` | `apiBaseUrl: 'http://localhost:8080'` under `production: true` reaches the production bundle | `frontend-dist` in report-only mode; fixed and re-enforced by elya-frontend lot 1, instruction written in `lots.md` and in the `ci.yml` comment |
| Info | `.github/workflows/ci.yml` | `image-publish` and `image-smoke` ship commented out. §3 forbids commented-out code; here it is the plan's explicit instruction (P6-D9), and the comment block names the lot that uncomments them | None |

## Harness

| Severity | Location | Finding | Action |
|---|---|---|---|
| Warning | `templates/project/` | No `.prettierignore` in the skeleton, while `lint.yml` runs Prettier on every frontend that has a config. kf wrote one at lot 8, elya-frontend copies it at lot 12, and the next frontend will rediscover the conflict from scratch. The file encodes a harness rule — that `CONVENTIONS.md`, `CLAUDE.md`, `AGENTS.md` and `lots.md` have a formatting the repository does not own — so it belongs to the harness | Proposed for lot 15 or a short chore lot: add `.prettierignore` to `templates/project/`, and have `bootstrap-project` copy it for a frontend |
| Warning | `@main` vs `develop` | The lot 17 invariants are on `develop` and were not exercised by this PR, because the callers pin `@main` and `main` is still `e87839c`. A harness lot is only really tested on the next adoption **after** its promotion. Both new steps were replayed by hand here and pass | Recorded; the promotion is the user's, and lot 15 re-runs the invariants across all repos |
| Info | `bootstrap-project` | The skill was invoked for this lot as §13 requires, but it describes generating a repository from the skeleton, not bringing an existing one under the harness. Its Step 5 verification block was the usable half; the procedure followed was the common checklist of `dev-plan.md`. The skill's own description claims both jobs | Worth either splitting the skill or pointing its description at the checklist for the adoption case |

## Coverage exclusions

None declared — the Gate parameters row reads `(none)`. There is therefore no
business package hidden behind a pattern; what hides the code here is the
builder's import-driven instrumentation, which is the Architecture finding above
and not an exclusion problem.

## Migrations

`Migrations directory` is `n/a`: this is a frontend, and the `migrations-immutable`
job is not called at all. Nothing to check.

## Validation gate

```
$ npm run build && npm test
Application bundle generation complete. [1.882 seconds]
Test Files  1 passed (1)
     Tests  1 passed (1)
Lines      : 100% ( 2/2 )      <- two lines, see above

$ npx --no-install prettier --check .
All matched files use Prettier code style!
```

PR #11: **16 checks, 16 pass, 0 fail** — 8 distinct checks run twice, once on the
`push` event and once on `pull_request`: `branch-naming`, `commit-format`,
`frontend-dist / dist`, `harness-invariants / invariants`, `lint / audit`,
`lint / format`, `lot-deliverables / deliverables`, `validate`. Run time 1 m 3 s.

Invariants replayed by hand against the working tree, including the two lot 17
steps that `@main` does not yet carry:

| Check | Result |
|---|---|
| `cmp CLAUDE.md AGENTS.md` | silent |
| `CONVENTIONS.md` vs `origin/main` master | silent |
| `jq -e '…source.ref == "main"'` | true |
| no `skill/` directory | ok |
| 11 gate parameter rows present | ok |
| coverage threshold has a subject (lot 17) | threshold `0`, accepted as honest |
| no exclusion covers a business package (lot 17) | no exclusion declared |
| census covers every skill and report | ok |
| lots file opens with a status table | line 5 |
| no calendar commitment | ok after the `arm64` rewording |

## Left open

1. **`.prettierignore` is not in the skeleton.** Two repositories now carry the
   same file, written twice. See Harness.
2. **elya-frontend lot 1 carries three debts, not one.** The Angular 21 → 22
   upgrade it already had, plus the coverage instrumentation and the
   `enforce: true` flip added by this lot. Its scope grew; it is still one lot
   because all three land in the same branch before any feature work.
3. **`integration-check` has no first passage yet.** The transversal rule
   written into `lots.md` names lot 2 as the first lot that calls the API, so
   `docs/audits/lot-0-integration.md` appears there. Lot 1 opens no request and
   records a "sans objet" line.
