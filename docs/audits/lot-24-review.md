# Lot Review — Lot 24 — feat/lot-24-harness-freeze

**Harness ref:** 1.2.0 (`caa6c8c`, the installed copy; its `plugins/` is identical to `main` at `98cddbd`)
**Model:** Claude Opus 5.5 (`claude-opus-5-5`), `claude` profile (`ANTHROPIC_BASE_URL` empty), new session
**Target:** local diff origin/develop...HEAD (no PR open)
**Read at:** `9bb749c`
**Fix commit:** `d4b40c6` (code, tests, conventions, skill, README), `6486d03` (plan alignment)
**Reviewed at:** `6486d03`
**Verdict:** Fixed

The owner asked for a meta-analysis beyond the diff: conformity of the whole
repository, and of the eight consuming projects, with the lot 24 section of
`dev-plan.md`. `Skill(code-review) high --fix` reviewed the diff (findings 1 to
10); this session checked C1 to C20, the validation criteria and the transition
to 2.0.0 (findings 11 to 20). Owner decisions taken in this review: the size cap
of `CONVENTIONS.md` raised to 15000 bytes to restore §7 (finding 11), `lot-ship`
removes the lock after the merge (finding 4), the machine actions of deliverable
9 done now (finding 13), one chore pull request per project for the
`CLAUDE.md` alignment (finding 14).

## Findings
| # | Severity | Location | Finding | Outcome |
|---|----------|----------|---------|---------|
| 1 | High | `plugins/claude-harness/hooks/git-guard.py:521` | `gh pr -R o/r merge 12` and `gh pr --repo=o/r merge 12` skipped the merge guard: `args[1]` was taken as the action | fixed in `d4b40c6` (`pr_action()` finds the action after a leading `--repo`) |
| 2 | High | `plugins/claude-harness/hooks/git-guard.py:416` | An attached short value (`-Rother/repo`, `-R=o/r`) was ignored, so the guard read another pull request than the one merged | fixed in `d4b40c6` |
| 3 | Medium | `plugins/claude-harness/hooks/git-guard.py:471` | `--delete-branch=true` passed the deny | fixed in `d4b40c6` (`flag_set()`; `--delete-branch=false` still passes) |
| 4 | Medium | `plugins/claude-harness/hooks/lot-lock-guard.py:127` | The lock is bound to the branch name only and never removed: a sub-lot on the same flat branch, or a branch recreated under the same name, was unlocked without `lot-start confirm` (LOT-1) | fixed in `d4b40c6`: `lot-ship` removes `.claude/current-lot` after the merge (owner decision); the consequence, an absent lock denies, is already covered by `tests/lot-lock-guard.test.sh`; no phrase test, per deliverable 7 |
| 5 | Medium | `plugins/claude-harness/hooks/session-context.sh:82` | The deepseek card came last and the global cap cut its final rules first, OUT-0 among them | fixed in `d4b40c6`: the state is truncated within the room the card leaves; test asserts OUT-1 survives |
| 6 | Low | `plugins/claude-harness/hooks/git-guard.py:471` | `gh pr merge --admin` was allowed although `lot-ship` forbids it | fixed in `d4b40c6` |
| 7 | Low | `plugins/claude-harness/hooks/git-guard.py:484` | The guard does not require `--match-head-commit` | rejected: the window is the gap between the hook and the command; `lot-ship` pins the SHA; the plan lists the denial reasons and this is not one |
| 8 | Low | `plugins/claude-harness/hooks/git-guard.py:503` | Any `feat/lot-*` head is accepted while the message said "only its own lot"; fork PRs not excluded | message fixed in `d4b40c6`; narrowing rejected: beyond the specification, and the repositories are private and single-owner |
| 9 | Low | `README.md:218` | A blank line split the hooks table, so three rewritten rows did not render | fixed in `d4b40c6` |
| 10 | Info | `dev-plan.md` deliverable 9 | The plan said the installed version is read from `installed_plugins.json`; the code reads the cache directory name | fixed in `6486d03`: plan aligned on the code, the directory is the copy that runs |
| 11 | High | `CONVENTIONS.md` §7 | The rewrite dropped the CI and image track rule (`main` → `latest`/`sha-`, `develop` → `dev`, a `dev` tag never in production), against "§1 à §8 inchangés sur le fond"; `deployment/CLAUDE.md` delegates that policy to §7 | fixed in `d4b40c6`: GIT-8; cap raised to 15000 bytes (owner decision), now 14167 |
| 12 | Medium | `dev-plan.md` Décisions, Règles transverses | Rows still contradicted the arbitrations: "Stop après PR (§2.9)", "le seul verrou est ta relecture", symlink to the local clone, reports citing the SHA, `§10.3`, lot 16 "dormant", merge missing from the git guard row | fixed in `6486d03` |
| 13 | Medium | deliverable 9 (machine) | Not executed: `~/.claude/coding-conventions.md` still pointed at the working clone (sessions loaded the lot branch's conventions with 1.2.0 skills, C11), four project installs stale (C12) | done in this review, machine state, no commit: link repointed to the marketplace clone; kreadevis-frontend 0.1.0, elya, elya-frontend, deployment 1.1.1 → 1.2.0 |
| 14 | Medium | the 8 project `CLAUDE.md` | Contradicted 2.0.0 or restated `CONVENTIONS.md`: "PR to `develop`, then stop", the `⛔` claim that push and PR are forbidden without the report, `style` commit type, "the only lock is human review", `section 2 step 9`, no `lot-start` row | fixed outside this repository (owner decision): kreadevis#45, kreadevis-frontend#30, meal-planner-backend#32, meal-planner-frontend#24, elya#37, elya-frontend#22, deployment#12, summerize-youtube#7; to merge after the promotion and the sync PR |
| 15 | Low | `lot-lock-guard.py:120`, `lot-deliverables.yml:143` | Stale `section 2.1` (with a wrong claim: the sync comes after the lock) and `section 2 item 1` | fixed in `d4b40c6` |
| 16 | Info | `plugins/claude-harness/skills/lot-start/sync-status.py:2` | Docstring cites `§2.1` | rejected: the plan keeps `sync-status.py` unchanged, and the docstring has no effect |
| 17 | Info | `plugins/claude-harness/hooks/__pycache__/` | An untracked `plugin-currency.cpython-312.pyc` appeared during the review run (no test imports the module) | removed; not in git |
| 18 | Info | transition to 2.0.0 | Checked: no consumer passes `friction_from_lot` (its removal would break a caller), no open PR carries a dropped commit type, every `Stack` value is valid, every rule identifier cited by skills, hooks, workflows and skeleton exists, the card regenerates identically, `shellcheck --severity=warning` clean on the 20 tracked `.sh` (run through Docker, not installed here) | no action |
| 19 | Info | `CONVENTIONS.md` GIT-1 vs `branch-naming.yml`, `harness-sync` invariant 11 | GIT-1 lists `feat/`, `fix/`, `chore/`; the workflow and the skill also accept `docs/`, `refactor/`, `test/`. Pre-existing, not in this diff | candidate, see below |
| 20 | Info | `CONVENTIONS.md` CODE-1 | "Constructor injection only" is written generically while the Angular projects mandate `inject()`; the project rule wins, the wording is Spring-only in intent. Pre-existing | candidate, see below |

## Candidate lots
Under the freeze, none of these opens a lot by itself; they are recorded for the
next change the freeze allows:

- Findings 19 and 20: scope GIT-1's branch prefixes to what `branch-naming.yml`
  accepts (or the reverse), and scope CODE-1's injection rule to Spring.
- Two project PRs of finding 14 inherit a red `develop`, unrelated to this lot:
  kreadevis (`ci` red since 2026-09-20, `com.lowagie.text.pdf` no longer
  resolves after a dependency bump) and meal-planner-frontend (`npm ci`
  ERESOLVE, TypeScript 5.9.3 against Angular 19.2). Each needs a `fix/` lot of
  its own project before its PR can merge (GIT-5).
- How those bumps reached `develop`: six Dependabot PRs merged from the owner's
  account on 2026-09-20 within two minutes, `validate` red (the tests ran and
  failed), `harness-invariants` red on every Dependabot PR at the time (missing
  Dependabot secret, fixed since). GitHub refuses branch protection and rulesets
  on these private repositories on the free plan (HTTP 403), so no workflow can
  prevent a red merge; the 2.0.0 git guard closes the agent path only. Owner
  decision deferred: branch protection under GitHub Pro, or a CI auto-revert.
