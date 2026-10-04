# Lot Audit — Lot 24 — feat/lot-24-harness-freeze

**Harness ref:** 1.2.0 (`98cddbd`, as the installed copy's `plugin-currency.py --installed-sha` reports it)
**Scope:** 46 modified files | **Verdict:** Fix warnings

Audited at `f46663b`, against `origin/develop` (`d06edac`), fetched. The review
report (`docs/audits/lot-24-review.md`, **Reviewed at** `6486d03`) covers the
head: the only commit after it is the review report and its census line, and
`CLAUDE.md` = `AGENTS.md` are unchanged outside `## Project documents`. The
installed skill (1.2.0) ran this audit: it reports and does not fix, so the
fix-in-audit behaviour of deliverable 4 is not applied here.

## Summary
| Dimension    | Critical | Warning | Info |
|--------------|----------|---------|------|
| Security     | 0        | 1       | 2    |
| Performance  | 0        | 0       | 2    |
| Architecture | 0        | 0       | 3    |

## Security

`Skill(security-review)` ran, with its discovery and false-positive phases
**inline** (no sub-agents): the code part of the diff (hooks, the card
generator, three workflows, the CI caller template) fits in this session. The
rest of the diff is Markdown and tests, which the skill excludes. One finding
was confirmed by running the hook against a fake `gh` that logs its calls and
environment.

| Severity | Location | Finding | Action |
|----------|----------|---------|--------|
| Warning | `plugins/claude-harness/hooks/git-guard.py:525` | The merge guard checks a different pull request from the one gh merges when the command sets `GH_REPO` (or `GH_HOST`) as a prefix. `strip_wrappers` drops `GH_REPO=o/other` and `env GH_REPO=o/other`, and `pull_request_state` runs `gh pr view 12` with the hook's own environment, so it reads PR 12 of the session repository. The real `gh pr merge 12` honours `GH_REPO`, so it merges PR 12 of `o/other`, whatever its base (even `main`) and whatever its checks. Reproduced: both forms exit 0 when the local PR 12 is a green lot PR, and the fake `gh` logged `GH_REPO=` empty. The `security-review` filter drops it (precedent: environment variables are trusted), but here the actor the guard constrains is the agent, which writes the prefix itself. Since the repositories have no branch protection, this hook is the only agent-side stop on a red or `main` merge (GIT-5). | open, owner decision: deny `gh pr merge` when the segment assigns `GH_REPO` or `GH_HOST`, or forward those assignments to `gh pr view`. About 15 minutes with a test in `tests/git-guard.test.sh`. Under the installed 1.2.0 audit, code after **Reviewed at** means re-running `lot-review` |
| Info | `plugins/claude-harness/hooks/git-guard.py:583` | `gh api -X PUT repos/<o>/<r>/pulls/<n>/merge` (or the GraphQL `mergePullRequest`) bypasses every `gh pr merge` check: `guard_gh` only looks at `gh pr`. This was already true before the lot, when `gh pr merge` was denied outright. | no action: no skill uses `gh api` to merge; noted for the next change the freeze allows |
| Info | `plugins/claude-harness/hooks/git-guard.py:545` | The guard requires every check that is *reported* to be green, but it cannot know the full set the CI will report. A merge run just after a push, before every workflow has registered its checks, passes on a partial set. | no action: `lot-ship` step 5 runs `gh pr checks --watch` first and pins `--match-head-commit`; review finding 7 already rejected requiring the pin in the guard |

Also checked, nothing to report: the lock binding (`lot-confirm.sh` matches
`feat/lot-<N>-` with the trailing hyphen, so lot 3 cannot unlock
`feat/lot-30-*`, and the lock is still written only from a user prompt);
`lot-lock-guard.py` still denies tool writes to the lock and to `.git`;
`plugin-currency.py` now reads only local JSON files, with no subprocess and
nothing from the network, and its warning text comes from the cache path and
the manifests; `deepseek-card.py` reads and writes only repository files; the
removed `friction_from_lot` step took the only workflow input it dropped with
it; `commit-format.yml` only narrows its default list.

## Performance
| Severity | Location | Finding | Action |
|----------|----------|---------|--------|
| Info | `plugins/claude-harness/hooks/git-guard.py:480` | The merge guard adds one `gh pr view` network call (10 s timeout, `stdin` closed) to every `gh pr merge`. Nothing else pays for it. | no action |
| Info | `plugins/claude-harness/hooks/plugin-currency.py`, `session-context.sh`, `lotfile.py` | Startup now does less: no `git ls-remote`, `git diff` or `git log -200` walk at every `SessionStart`. | no action |

## Architecture
| Severity | Location | Finding | Action |
|----------|----------|---------|--------|
| Info | `plugins/claude-harness/hooks/session-context.sh:92` | `room=$((CAP - ${#card_section}))` turns negative if the card ever grows past `CAP`, and `${out:0:-N}` then fails or cuts from the end. Today `deepseek-card.py --check` caps the card at `CAP - TABLE_CAP - 2000`, so this cannot happen. | no action: the generator's budget check is the guard |
| Info | `CONVENTIONS.md` | Plan deliverables checked against the tree: 14167 bytes (cap 15000, finding 11 of the review); §1 to §15 numbering kept; rule identifiers in use; ASK-2 and PLUG-1 pre-authorise `claude plugin update`; C1, C13 and C17 are gone from skills, hooks and workflows; `lot-review` step 0 reads only `ANTHROPIC_BASE_URL` (C3); one commit type list (test-covered). | no action |
| Info | `.github/workflows/lot-deliverables.yml:137` | `lot-ship` step 3 marks the row ✅ on the branch, in a `docs(N)` commit. The "changed outside its status lines" check filters status lines by emoji, so a ✅ row passes; a heading carrying the status passes too. It is a `::warning`, never a failure. | no action |

## Coverage exclusions
| Exclusion | Business code? | Proposed action |
|-----------|----------------|-----------------|
| (none) | n/a | none: `Coverage tool` is none, a shell test suite |

## Migrations
n/a (`Migrations directory` is `n/a`).

## Lot-specific notes
- The lot changes the gate itself, while the installed plugin (1.2.0) runs the
  gate until the promotion. This audit followed the installed `lot-audit`:
  step 0 compared against **Reviewed at**, and it does not fix findings. The
  2.0.0 version on the branch (step 0 is an existence check, step 7 fixes) was
  reviewed as code, not executed.
- The merge guard and the `lot-ship` merge step are active only after the
  `develop` → `main` promotion. So the pull request of this lot is merged by
  the user, as the plan says.
- `./tests/run.sh`: 14/14 suites green. `shellcheck` is not installed here, so
  the shell lint of `workflows.test.sh` was skipped locally and runs in CI only
  (friction `lot-test / 3.1`). The review ran it through Docker (finding 18).

## Recommended next steps
1. Owner decision on the `GH_REPO` finding: fix it in this lot (a `fix(24)`
   commit, then `lot-review` again under the installed 1.2.0 rule), or record
   it for the next change the freeze allows. It falls under freeze clause (a), a
   security flaw.
2. Then `lot-ship`. The `Validation command` must be green before the PR.
