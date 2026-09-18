# Lot Audit — Lot 1 — feat/lot-0-6-harness-foundation

**Harness ref:** `feat/lot-0-6-harness-foundation` (lot 0 at `2b551e0`)
**Scope:** `plugins/claude-harness/hooks/` (3 files) + 2 test suites (77 assertions)
**Verdict:** ✅ Ready for PR

Findings **#2** (no guard on git), #5 (rtk masks merges), #18 (mirror limited to
Edit/Write), and P5-#2 (direct pushes to `main` as the norm: 37 on kb, 23 on kf,
25 on mpb, 17 on mpf).

## Summary

| Dimension | Critical | Warning | Info |
|---|---|---|---|
| Security | 0 | 1 | 2 |
| Harness | 0 | 1 | 1 |
| Architecture | 0 | 0 | 2 |

## Deliverables

| File | Role |
|---|---|
| `hooks/git-guard.py` | `PreToolUse` guard on `Bash`, standard library only |
| `hooks/mirror-sync.sh` | `PostToolUse` mirror, matcher extended to `Bash` |
| `hooks/hooks.json` | Plugin wiring, both hooks with a 15 s timeout |
| `tests/git-guard.test.sh` | 60 assertions on real git fixtures |
| `tests/mirror-sync.test.sh` | 17 assertions |

## Security

| Severity | Location | Finding | Action |
|---|---|---|---|
| Warning | `git-guard.py` | The guard is **defence in depth, not a lock**: it only sees commands routed through the `Bash` tool of a session where the plugin is loaded. A terminal outside Claude Code, or an agent that does not load plugins, is unaffected | Accepted and already in `dev-plan.md` risks. The second curtain is the CI (lot 3), which is agent-agnostic |
| Info | `git-guard.py` | No shell is spawned to analyse the command: `shlex` lexes it and `subprocess.run` is called with an argument list, never a string. A crafted command cannot make the guard execute anything | None |
| Info | `git-guard.py` | The guard reads `docs/audits/lot-N.md` and `CLAUDE.md` from the working tree, so a branch that deletes its own report is caught (the file is simply absent) | None |

**Injection review of the hooks** (checklist of the lightened gate):

- `git-guard.py` never interpolates command text into a shell. `run_git` passes a
  list to `subprocess.run` with a 5 s timeout and no `shell=True`.
- `mirror-sync.sh` runs under `set -uo pipefail`, quotes every expansion, and
  passes the payload to `python3` on stdin rather than embedding it in a command.
- Neither hook logs the command it inspected, so a `git push` carrying a token in a
  URL is not echoed into the transcript.

## Harness

| Severity | Location | Finding | Action |
|---|---|---|---|
| Warning | out of repo | The **rtk exclusion (V5)** is not delivered by this lot: the rtk hook lives in `~/.claude/settings.json`, outside this repository. The skills work around it by calling `rtk proxy git log` explicitly (P5-#14) | Listed as post-merge user work in the PR body; belongs to the user-level half of lot 5 |
| Info | `hooks.json` | `${CLAUDE_PLUGIN_ROOT}` is used for both hook paths, so no absolute user path is committed (§3 forbidden patterns) | None |

## Architecture

| Severity | Location | Finding | Action |
|---|---|---|---|
| Info | `git-guard.py` | The guard answers `deny` or `ask` but **never** `allow`: it can only narrow permissions, never widen them. An unparseable command yields `ask` | None |
| Info | `git-guard.py` | `-n` is treated as `--no-verify` on `commit` but **not** on `push`, where git defines it as `--dry-run`. A test pins this distinction | None |

## Trapped cases

All the cases named in `dev-plan.md` ("Gate allege des lots de remediation", rule 1)
are covered by `tests/git-guard.test.sh`, plus the ones found while writing it:

| Case | Verdict |
|---|---|
| `git -C <dir> push` and `git -C<dir> push` on a repo sitting on `main` | deny |
| `cd x && git push` (the guard tracks `cd` across segments) | deny |
| `git push origin HEAD:main`, `origin main`, `HEAD:refs/heads/main`, `branch:main` | deny |
| `git push` / `git push origin` from `main` | deny |
| `git push -f`, `--force`, `--force-with-lease`, `--force-if-includes`, `-fu`, `+refspec` | deny |
| `git push --no-verify`, `git commit --no-verify`, `git commit -n` | deny |
| `git -c core.hooksPath=/dev/null commit`, `-ccore.hooksPath=...`, and on `push` | deny |
| `git reset --hard` | deny |
| `git push origin --delete <b>`, `git push origin :<b>`, `git branch -D origin/<b>`, `-rd` | deny |
| `bash -c "cd <main repo> && git push"`, `sh -c 'git push origin HEAD:main'` | deny |
| `echo start && git push origin main`, `git status; git push origin main` | deny |
| `B=main; git push origin $B`, `git push origin $(git branch --show-current)` | ask |
| `git push origin 'unbalanced` (unlexable) | ask |
| `git push -n origin <branch>` (dry run, not a bypass) | ask |
| `gh pr create` without `--base`, `-B main`, `--base=main` | deny |
| `gh pr merge` | deny |
| `gh pr create --base develop` from `feat/lot-N-*` without `docs/audits/lot-N.md` | deny |
| Same with an unresolved `Critical` row in the report | deny |
| Frontend repo without `docs/audits/lot-0-integration.md` | deny |
| `git status`, `git log`, `git commit -m`, `git switch -c`, `gh pr view`, `gh pr checks` | pass |

## Validation criteria

- [x] Every trapped case produces the expected decision (77 assertions green)
- [x] `rtk proxy git log --first-parent main` on kb shows `f0189fe` and `b00c534`
      (the merges of PR #30 and #29) — the P5-#14 workaround is effective, so the
      skills can read history reliably even before V5 is settled
- [ ] Old hook `~/.claude/hooks/sync-claude-agents.sh` removed from `settings.json`
      — deliberately **not now**: removing it before the plugin is installed would
      open a coverage gap. Listed as post-merge user work

## Recommended next steps

1. After V3, confirm the guard's `deny` wins over an `allow` entry for `Bash(git *)`.
2. Settle V5 with the rtk documentation; until then the skills keep calling
   `rtk proxy git log`.
