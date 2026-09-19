# Lot Audit — Lot 10 — meal-planner-frontend adoption

**Harness ref:** `chore/harness-adoption-reports`, from `320cfbd`
**Target repo:** `meal-planner-frontend`, branch `chore/harness-adoption`, PR #21
**Commits:** `9422dd7` (adoption)
**Verdict:** ✅ checklist complete, validation gate green, no Critical **in this
lot**. The retroactive audit it produced does carry one, against lot 13 of the
target repo.

Scope: the common adoption checklist (items 1 to 14 of `dev-plan.md`), the
mpf-specific items, and the retroactive audit of lots 01 to 13 that the plan
required.

## Summary

| Dimension | Critical | Warning | Info |
|---|---|---|---|
| Security | 0 | 0 | 1 |
| Performance | 0 | 1 | 0 |
| Architecture | 0 | 1 | 1 |
| Harness | 0 | 1 | 1 |

The findings *about the target repository's existing code* are in
`meal-planner-frontend/docs/audits/retro-lots-01-13.md`, not duplicated here.
Its headline: lot 13 shipped `authInterceptor` and `authGuard` without
registering either, and `CLAUDE.md` asserted the opposite.

## The finding this lot actually uncovered

The plan told this lot to call `frontend-dist.yml` with the same dated
`continue-on-error` / `enforce: false` treatment as kreadevis-frontend, "as long
as mpf lot 14 has not added `fileReplacements`". That reasoning was applied
without checking the bundle. It is wrong here.

`angular.json` really has no `fileReplacements`, so `environment.prod.ts` is
dead code — but `environment.ts` is imported **only** by `AuthService` and the
three `core/api` services, and no reachable component uses any of them, so the
production build tree-shakes the whole branch away. Verified on the real
artifact: `grep -rlF "localhost:8080" dist/meal-planner/browser` returns
nothing.

So the job is set to `enforce: true`. It is green today and it turns red at the
exact commit of lot 11 that wires the API services — which is the commit that
must add `fileReplacements`. A report-only job would have stayed quiet through
precisely the change it exists to catch.

The general lesson for the remaining adoption lots: `Dist forbidden pattern`
describes the bundle, not the source tree. Grep the built artifact before
choosing `enforce`.

## Common checklist, item by item

| # | Item | State |
|---|---|---|
| 1 | Branch `chore/harness-adoption` from `develop` | ✅ |
| 2 | `.claude/settings.json`, marketplace + plugin, `"ref": "main"` | ✅ new file |
| 3 | Local skills removed, none project-specific kept | ✅ 8 files deleted, including `sprint` |
| 4 | `CLAUDE.md`: gate parameters, plugin skill names, no sprint chaining, ⛔ LOTD kept, census, `AGENTS.md` mirror | ✅ the "Sprint chaining" paragraph is replaced by the §2 step 9 no-chaining rule |
| 5 | `CONVENTIONS.md` = lot 5 master | ✅ `cmp` silent |
| 6 | `ci.yml` calls the lot 3 workflows, `branches: ["**"]`, SHA-pinned actions, `permissions: contents: read`, `concurrency`; `dependabot.yml` | ✅ |
| 7 | `.claude/settings.local.json`: `gh pr *` removed | ✅ n/a, no such file |
| 8 | `.gitignore`: `.env`, `*.local.md` | ✅ `.env` added, `*.local.md` already there |
| 9 | Branch naming documented | ✅ `CLAUDE.md` § Workflow and the `lots.md` delivery-rules table, both moved off `lot-XX-slug` |
| 10 | Front: `ci.yml` calls `frontend-dist.yml` with the Gate-parameters pattern | ✅ `enforce: true`, see above |
| 11 | Gate green + this report | ✅ |
| 12 | Lots file opens with a `\| Lot \| Branche \| Statut \|` table | ✅ at line 7, 8 rows |
| 13 | Skills section points non-Claude agents at the local clone | ✅ |
| 14 | No build/push steps written in the repo | ✅ image jobs commented until mpf lot 14 |

mpf-specific items: the retroactive audit, the karma threshold decision, the new
lot 16, and the `CLAUDE.md` correction about auth.

## Security

| Severity | Finding | Action |
|---|---|---|
| Info | The retroactive audit found no `innerHTML`, no `bypassSecurityTrust*`, no `eval`, no `: any`, no hard-coded secret and no stray `console.log`. Its two Majors (bearer token sent to `themealdb.com` once the interceptor is registered; both tokens in `localStorage`) are against existing code and are attached to mpf lot 11 | Nothing to fix in this lot |

## Performance

| Severity | Finding | Action |
|---|---|---|
| Warning | `npm run build` warns on three component stylesheets over the 4 kB budget (`meal-picker` 6.68 kB, `planner` 4.94 kB, `recipe-form` 4.38 kB). Pre-existing, unrelated to this lot. The initial bundle itself is well under budget (456 kB total output) | Raised, not fixed here |

## Architecture

| Severity | Finding | Action |
|---|---|---|
| Warning | `CLAUDE.md` described an auth wiring that does not exist. Corrected in this lot to state what is actually registered, with a pointer to the retroactive audit. A project instruction file that describes intent as fact is worse than silence: the next agent reads it as ground truth | Fixed in this lot |
| Info | The karma threshold stays at `0` rather than being pinned to the "measured level" the plan asked for. The measurement is `Lines 100 % (1/1)`: one spec for 28 source files, and the Angular karma builder only instruments what a spec imports. Encoding that as a gate would have been worse than 0, which at least reads as "not measured yet". The new lot 16 makes it measurable | `karma.conf.js` comment and `CLAUDE.md` ratchet note both state the reason |

## Harness

| Severity | Finding | Action |
|---|---|---|
| Warning | The plan's `enforce: false` instruction for this repo was wrong, see above. `dev-plan.md` is corrected in this lot | `dev-plan.md` updated |
| Info | `lint.yml` frontend steps (prettier, eslint) both skip here: the repo configures neither. The explicit `skipped:` lines added in lot 7 make that visible in the job summary instead of looking like a pass | None |

## Validation gate

```
$ npm run build
Output location: dist/meal-planner
(3 component-style budget warnings, no error)
$ npm test
TOTAL: 1 SUCCESS
Lines 100% (1/1)   — see the Architecture note
$ grep -rlF "localhost:8080" dist/meal-planner/browser
(no match)
```

`npm test` needs a Chrome binary, which this workstation did not have; one was
fetched with `npx puppeteer browsers install chrome` and pointed at through
`CHROME_BIN`. Nothing was added to the repository. GitHub's runner image ships
Chrome, so CI needs no equivalent step.

Harness invariants were replayed locally with the same shell the workflow runs
(mirror, conventions copy, marketplace ref, no `skill/`, 11 gate parameters,
census including the retroactive audit, lots status table at line 7, no calendar
commitment): all pass.

## Left open

- **mpf lot 11** now carries five items this audit refuses to pull forward:
  `fileReplacements`, registering the interceptor, the `/login` route and
  `authGuard`, the interceptor's URL filter, and a single in-flight `refresh()`.
- **mpf lot 16** (test suite) is new and unscheduled; the threshold stays at 0
  until it lands.
- Component stylesheet budgets, see Performance.
- The two owner actions of `docs/audits/lot-7.md` apply here identically: the
  harness `develop` → `main` promotion (without it this PR's run fails at load,
  since `enforce` does not exist on `frontend-dist.yml@main`), then a
  `HARNESS_READ_TOKEN` that can read the harness repository.
