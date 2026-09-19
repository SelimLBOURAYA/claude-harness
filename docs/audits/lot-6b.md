# Lot Audit — Lot 6b — GitHub settings

**Harness ref:** `chore/pre-promotion-fixes`, after `add10d7`
**Scope:** the repository settings lot 6b makes the user responsible for, verified
from the GitHub API rather than from the interface
**Verdict:** ⚠️ 3 of 5 deliverables done. The two that remain both block lot 7.

Findings **P5-#3**, P5-#11, P5-#10 ; *(P6)* **A7**, A8, B1.

## Summary

| Dimension | Critical | Warning | Info |
|---|---|---|---|
| Security | 0 | 1 | 1 |
| Harness | 0 | 1 | 1 |
| Architecture | 0 | 0 | 0 |

## Verified on 2026-09-19

```
gh api repos/SelimLBOURAYA/<repo> --jq '.default_branch, .visibility'
```

| Repo | Default branch | Visibility |
|---|---|---|
| `claude-harness` | `develop` | private |
| `kreadevis` | `develop` | private |
| `kreadevis-frontend` | `develop` | private |
| `meal-planner-backend` | `develop` | private |
| `meal-planner-frontend` | `develop` | private |
| `elya` | `develop` | private |
| `elya-frontend` | `develop` | private |
| `summerize-youtube` | `develop` | private |
| `deployment` | `develop` | private |

Deliverable 1 (default branch `develop` ×9) and deliverable 2 (P6-D1, `kreadevis`
and `meal-planner-frontend` made private) are **done**, and deliverable 3 is this
table. `quarkus-startup` and `test_alten` still default to `main`; neither is part
of the portfolio and neither is harnessed, so they are out of scope.

## What is still open

| # | Setting | State on the API | Why it blocks lot 7 |
|---|---|---|---|
| 4 | Reusable workflow access | `gh api repos/SelimLBOURAYA/claude-harness/actions/permissions/access` returns `{"access_level":"none"}` | A private repository shares its `workflow_call` workflows only above `none`. Every `ci.yml` written by the adoption checklist fails to resolve `SelimLBOURAYA/claude-harness/.github/workflows/*.yml@main` on its first push. This is V4 of lot 0, and the API has now answered it: **negative until the setting changes** |
| 5 | `HARNESS_READ_TOKEN` | `gh secret list` empty on `claude-harness` and on `kreadevis` | `harness-invariants.yml` checks out the private harness to compare `CONVENTIONS.md`; `github.token` is scoped to the calling repository. The job fails on a checkout error, which reads nothing like the conventions drift it is meant to report |

Both are owner actions with a security dimension (§4): widening who may call a
private repository's workflows, and issuing a cross-repository read token. The
commands are in [`README.md`](../../README.md#making-the-harness-consumable);
`add10d7` makes the caller template pass the secret unconditionally, so a repo
adopted before the token exists is red rather than silently unchecked.

## Security

| Severity | Location | Finding | Action |
|---|---|---|---|
| Warning | `HARNESS_READ_TOKEN` | A fine-grained token scoped to `claude-harness` with `Contents: Read-only` is the least privilege that works; a classic PAT would carry the whole account. Its expiry is a scheduled outage across 8 repos | Issue it fine-grained, record the expiry outside the repos |
| Info | Portfolio visibility | No portfolio repo is public, so no public repo can attempt to call a private reusable workflow | None |

## Harness

| Severity | Location | Finding | Action |
|---|---|---|---|
| Warning | `dev-plan.md` lot 6b item 4 | The line to add to `deployment/CLAUDE.md` is a change in another repository, which this lot cannot make from here | Moved to lot 13, the adoption lot of `deployment`, where that file is edited anyway |
| Info | V1, V2, V3, V6 | Still not executed. `docs/audits/lot-0.md` requires them closed before lot 7; the promotion `develop` → `main` is what makes V1 executable at all, since `main` only then carries `.claude-plugin/marketplace.json` | Run V1, V2, V3 in one session on a throwaway private repo, right after the promotion |

## Validation criteria

- [x] Default branch `develop` on the 9 repos, read from the API
- [x] No portfolio repo is `PUBLIC`
- [x] This report
- [ ] `access_level` of `claude-harness` reads `user`
- [ ] `HARNESS_READ_TOKEN` present on the 8 consuming repos

## Recommended next steps

1. Merge this PR, then promote `develop` → `main` (PR #8).
2. Run the two commands in `README.md` § "Making the harness consumable" and tick
   the last two criteria here.
3. Run V1, V2, V3 on a throwaway private repo.
4. Only then start lot 7.
