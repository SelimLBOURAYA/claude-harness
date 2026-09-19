# Lot Review — Lots 0 to 6 — `feat/lot-0-6-harness-foundation`

**Harness ref:** `035271e` (this repository is the harness)
**Model:** `claude-opus-5`, `claude` profile (`ANTHROPIC_BASE_URL` empty)
**Target:** PR #5 — https://github.com/SelimLBOURAYA/claude-harness/pull/5
**Reviewed at:** `035271e`
**Fix commit:** `5414fd4`
**Verdict:** Fixed — 8 findings fixed, 1 deferred to the user

## Scope note

`dev-plan.md` delivers lots 0 to 6 on a single branch and a single PR: the harness
has no promoted `main` yet, so no plugin is installable and the gate
`lot-test → lot-review → lot-audit → lot-ship` is not executable in session. The
review was therefore one pass over the whole `develop...HEAD` diff, and it produces
**one** report for the range rather than seven near-identical ones. The per-lot
shape resumes at lot 7, where one lot is one branch is one PR.

This repository's own `ci.yml` deliberately does not call `lot-deliverables.yml` on
itself, so nothing in CI requires `lot-0-review.md` … `lot-6-review.md` here, and
the hook does not require them either: see the note on finding 7 below.

## Findings

| # | Severity | Location | Finding | Outcome |
|---|----------|----------|---------|---------|
| 1 | Critical | `plugins/claude-harness/hooks/git-guard.py:489` | Any command wrapper (`rtk`, `sudo`, `env`, `command`, `time`, `timeout`, `nice`, `nohup`) made the guard see the wrapper instead of `git`, so it stayed silent. RTK rewrites every git call in this portfolio and `Bash(rtk *)` is allowlisted, so `rtk git push origin main` reached `main` with no prompt at all | fixed in `5414fd4` |
| 2 | High | `plugins/claude-harness/skills/lot-ship/SKILL.md:79` | No gate skill added the freshly written audit report to the `## Project documents` census, so `harness-invariants.yml` fails on every lot PR in the 8 consuming repos. This repo's own 4 portfolio reports were covered only by a directory row, which the invariant does not accept | fixed in `5414fd4` |
| 3 | High | `plugins/claude-harness/skills/bootstrap-project/SKILL.md:48` | `CONVENTIONS.md` was seeded with `cp` from the clone's checked-out branch while `harness-invariants.yml` compares against ref `main`; bootstrapping from a clone on `develop` or on a lot branch produced a copy CI rejects on the new repo's first push. The step-5 verification had the same flaw: comparing the copy to the file it was copied from is green by construction | fixed in `5414fd4` |
| 4 | Medium | `plugins/claude-harness/hooks/mirror-sync.sh:16` | The three fields were read space-separated from one line, so any repository path containing a space split across `$file` and `$cwd`; the hook exited silently while `CLAUDE.md` and `AGENTS.md` diverged | fixed in `5414fd4` |
| 5 | Medium | `.github/workflows/branch-naming.yml:34` | No `dependabot/*` case, so every weekly Dependabot PR fails branch-naming on a name the bot owns. `templates/dependabot.yml` claimed `commit-message.prefix` exempted it, which is false: that prefix only rewrites the commit subject | fixed in `5414fd4` |
| 6 | Medium | `.github/workflows/lot-deliverables.yml:60` | `seq` expands a range to plain integers only, so `docs/audits/lot-2b.md` on `feat/lot-0-6-*` was rejected as a lot the branch does not declare. Second defect in the same loop: `lot-0-integration.md` does not match the `lot-N(-review)?` pattern, so a frontend branch adding it was flagged as belonging to a lot named `lot-0-integration` | fixed in `5414fd4` |
| 7 | Medium | `plugins/claude-harness/hooks/git-guard.py:34` | `LOT_BRANCH` captured only the first lot of a range and never checked `lot-N-review.md`, so the guard passed PRs that `lot-deliverables.yml` then rejects. A guard that is laxer than the CI it mirrors is noise | fixed in `5414fd4`, then **superseded**: see below |
| 8 | Medium | `.github/workflows/lint.yml:64` | `setup-node` with `cache: npm` and no `cache-dependency-path`; `defaults.run.working-directory` does not reach an action's inputs, so the job fails looking for a root lockfile in any repo whose frontend is not at the root. Same at `lint.yml:108` and `frontend-dist.yml:45` | fixed in `5414fd4` |
| 9 | High | `CONVENTIONS.md:6` | States that `~/.claude/coding-conventions.md` is a symlink to this master. It is a stale regular file: 13 sections against the master's 15, missing §2.5 "What an integration test is" and §14 "LLM profile routing". §9 tells agents not to re-read the master because of that claim, so every session since lot 5 has been running on the stale copy — including this one | **deferred**, see below |

## Finding 9 — why it is deferred

The fix is an `ln -sfn` **outside the repository**, which §4 "ask before doing"
puts behind an explicit confirmation. The question was asked and left unanswered,
and an unanswered §4 question is not an authorization. Fixing it the other way,
by making `CONVENTIONS.md` §9 describe the real state, is not free either:
`tests/conventions.test.sh:15-16` pins the symlink sentence, so the suite would
have to change with it.

Left to the user. The command, for the record, after backing up the current file:

```bash
cp ~/.claude/coding-conventions.md ~/.claude/coding-conventions.md.bak
ln -sfn ~/ENV/projets/claude-harness/CONVENTIONS.md ~/.claude/coding-conventions.md
```

Until it is done, any session reading `~/.claude/coding-conventions.md` is missing
two sections of the conventions it is supposed to enforce.

## Finding 7 — the fix was reverted, and why

`5414fd4` taught the hook to expand a lot range and to require both reports
before `gh pr create`. That made the hook a second, independent definition of the
deliverable rule — one in Python, one in the workflow's `sed`/`seq` — and finding
6 exists precisely because two such definitions drifted. Keeping them in step is
work with no payoff: the hook does not run under Cursor, DeepClaude or any agent
that loads no plugin, so it can never be the rule's enforcement point. CI can.

So the deliverable checks come back out of `git-guard.py`. The guard keeps what
only it can do at the moment of the command: refuse a push to `main`, a force
push, `--no-verify`, a destructive reset, a remote branch deletion, a PR whose
base is not `develop`. `lot-deliverables.yml` owns audit reports, review reports,
the frontend integration report and unresolved Critical rows, alone.

The related question — whether `feat/lot-N-M-*` range branches stay legal at all
— is **not** settled here. Banning them would fail this very branch's own
`branch-naming` job, and the branch is already pushed, so renaming it means
deleting a remote branch (§4). It stays on the deferred list for lot 15.

## Inline comments posted

PR #5: 9 comments, discussion ids `r4047104642` to `r4047108696` —
https://github.com/SelimLBOURAYA/claude-harness/pull/5

`mcp__github_inline_comment__create_inline_comment` was unavailable in the review
session, so the comments went through the documented fallback
(`gh api repos/SelimLBOURAYA/claude-harness/pulls/5/comments`).

## Validation

```
./tests/run.sh    7/7 suites, 507 assertions
```

Tests were extended, never relaxed: `tests/git-guard.test.sh` (wrapper block, range
and suffixed-lot fixtures, review-report ordering), `tests/mirror-sync.test.sh`
(spaced-path section), `tests/skeleton.test.sh` (ref-`main` assertion plus a negative
on the old `cp`), `tests/workflows.test.sh` (dependabot exemption, lot-membership
helper). All 12 workflow and template YAML files parse; `CLAUDE.md`/`AGENTS.md` and
`templates/project/CLAUDE.md`/`AGENTS.md` are byte-identical.

## Candidate lots

| Candidate | Why it is not this lot's business |
|---|---|
| Aligning the guard and `lot-deliverables.yml` on one shared lot-expansion definition | The expansion rule now lives twice, once in Python and once in `sed`/`seq`, and finding 7 exists precisely because the two drifted. Unifying them means shipping a helper the workflow can call, which is a design change, not a review fix |
| A review deliverable per lot for range branches | Findings 6 and 7 both stem from range branches being a shape the deliverable rules did not anticipate. Either the gate accepts one report per range, or `feat/lot-N-M-*` stops being allowed. To settle at lot 15 |
