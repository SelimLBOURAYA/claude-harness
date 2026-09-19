# Lot Audit — Lot 8 — kreadevis-frontend adoption

**Harness ref:** `chore/harness-adoption-reports`, from `23aa7be`
**Target repo:** `kreadevis-frontend`, branch `chore/harness-adoption`
**Commits:** `496860d` (adoption); harness `acfd9b9` (`frontend-dist` report mode)
**Verdict:** ✅ checklist complete, validation gate green, no Critical.

Scope: the common adoption checklist (items 1 to 14 of `dev-plan.md`) plus the
kf-specific items. No functional change.

## Summary

| Dimension | Critical | Warning | Info |
|---|---|---|---|
| Security | 0 | 1 | 1 |
| Performance | 0 | 1 | 0 |
| Architecture | 0 | 0 | 2 |
| Harness | 0 | 1 | 1 |

## The finding this lot actually uncovered

The plan's answer for a repository joining the harness with a known violation
was `continue-on-error: true` on the caller side. Lot 7 had just shown that a
job-level `continue-on-error` still publishes the check run with conclusion
`failure`: the pull request reads red for a signal the plan declared
informative, and §7 says a red pull request is never merged. Taken literally,
the plan produced a repository whose CI is permanently red by design - the
fastest way to teach a reader to stop looking at red.

`frontend-dist.yml` therefore gained an `enforce` input (default `true`). Set
to `false` it prints the same evidence at `::warning::` level and writes a
`report-only` line to the job summary, so the exemption is visible in the run
rather than hidden in a caller comment nobody opens.

## Common checklist, item by item

| # | Item | State |
|---|---|---|
| 1 | Branch `chore/harness-adoption` from `develop` | ✅ |
| 2 | `.claude/settings.json`, marketplace + plugin, `"ref": "main"` | ✅ new file |
| 3 | Local skills removed, none project-specific kept | ✅ 8 files deleted, including `sprint` |
| 4 | `CLAUDE.md`: gate parameters, plugin skill names, no sprint chaining, ⛔ LOTD kept, census, `AGENTS.md` mirror | ✅ |
| 5 | `CONVENTIONS.md` = lot 5 master | ✅ `cmp` silent |
| 6 | `ci.yml` calls the lot 3 workflows, `branches: ["**"]`, SHA-pinned actions, `permissions: contents: read`, `concurrency`; `dependabot.yml` | ✅ |
| 7 | `.claude/settings.local.json`: `gh pr *` removed | ✅ (no `git push *` or blanket `git *` was present) |
| 8 | `.gitignore`: `.env`, `*.local.md` | ✅ `.env` added, `*.local.md` already there |
| 9 | Branch naming documented | ✅ `CLAUDE.md` § Branch naming |
| 10 | Front: `ci.yml` calls `frontend-dist.yml` with the Gate-parameters pattern | ✅ report-only, see above |
| 11 | Gate green + this report | ✅ |
| 12 | Lots file opens with a `\| Lot \| Branche \| Statut \|` table | ✅ table created, 19 rows, statuses read from the section headings |
| 13 | Skills section points non-Claude agents at the local clone | ✅ |
| 14 | No build/push steps written in the repo | ✅ image jobs commented, to be uncommented by kf lot 13 |

kf-specific items: `.claude/CLAUDE.md` reduced to a pointer,
`claude-md-context.txt` moved to `docs/archive/` and re-censused, the
signals/RxJS memory promoted into `CLAUDE.md`.

## Security

| Severity | Location | Finding | Action |
|---|---|---|---|
| Warning | `src/environments/environment.ts` | The production bundle ships `http://localhost:8080`. Verified on the real build: `dist/kreadevis-frontend/browser/main-QPMF2NMU.js` matches. A production client would call its own machine | Out of this lot's scope (kf lot 13, same-origin). `frontend-dist` now reports it on every run instead of nobody noticing, and lot 13 carries an explicit deliverable to flip `enforce` to `true` |
| Info | `.claude/settings.local.json` | `gh pr *` removed. The file is globally gitignored, so the change is local-only and no other agent inherits it | None |

## Performance

| Severity | Finding | Action |
|---|---|---|
| Warning | `npm run build` warns: initial bundle 617.95 kB against a 500 kB budget, 117.95 kB over. Pre-existing, unrelated to this lot | Raised for kf lot 11 (UX polish) or a dedicated bundle lot; not fixed here |

## Architecture

| Severity | Finding | Action |
|---|---|---|
| Info | The Angular rules from `.claude/CLAUDE.md` (`input()`/`output()`, no `@HostBinding`, no `ngClass`/`ngStyle`, `NgOptimizedImage`, AXE/WCAG AA, `inject()`) were merged into the root `CLAUDE.md` rather than deleted. Two instruction files meant one of them drifting unnoticed | None |
| Info | The signals rule is now stated with its nuance - shared state is `BehaviorSubject`, strictly local state may be a signal, existing local signals are never back-ported - because the flat "no signals" wording had already produced a wrong generalisation once | None |

## Harness

| Severity | Finding | Action |
|---|---|---|
| Warning | `dev-plan.md` lot 8 prescribed `continue-on-error: true` for `frontend-dist`. That instruction is now wrong; the `enforce` input replaces it | `dev-plan.md` updated in this lot |
| Info | `frontend-dist.yml` defaults `dist_dir` to `dist`, while Angular 21 emits to `dist/<project>/browser/`. The `index.html` and pattern checks both recurse, so the default works unchanged | None |

## Validation gate

```
$ npm run build
Application bundle generation complete. [3.868 seconds]
$ npm test
Statements 82.74%  Branches 79.69%  Functions 68.12%  Lines 86.44%
exit 0
```

Lines 86.44 % against the `angular.json` threshold of 79. Harness invariants
were replayed locally with the same shell the workflow runs (mirror, conventions
copy, marketplace ref, no `skill/`, 11 gate parameters, census, lots status
table, no calendar commitment): all pass.

## Left open

- **kf lot 0** (`integration-check`) is still ⬜, so the next *functional* kf pull
  request is blocked at `gh pr create` until `docs/audits/lot-0-integration.md`
  exists. This adoption lot is a `chore/` branch and is not subject to it.
- **kf lot 13**: flip `enforce: true` and uncomment the two image jobs.
- Initial bundle over budget, see Performance.
- The two owner actions of `docs/audits/lot-7.md` apply here identically:
  `HARNESS_READ_TOKEN` cannot read the harness (403), and the `lint.yml` and
  `frontend-dist.yml` fixes only reach this repo once `develop` is promoted to
  `main`.
