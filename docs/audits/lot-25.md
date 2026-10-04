# Lot Audit — Lot 25 — feat/lot-25-guard-heredoc-report-fields

**Harness ref:** 2.0.0
**Scope:** 11 modified files | **Fix commit:** 03ae5ac | **Verdict:** Ready for PR

## Summary
| Dimension    | Critical | Warning | Info |
|--------------|----------|---------|------|
| Security     | 0        | 3       | 3    |
| Performance  | 0        | 0       | 1    |
| Architecture | 0        | 0       | 0    |

## Security

The `security-review` discovery and false-positive phases ran inline, without
sub-agents: the code diff is about 230 lines. Every probe ran against the
branch guard and the `origin/develop` guard, so a regression and a gap already
on `develop` can be told apart.

| Severity | Location | Finding | Action |
|----------|----------|---------|--------|
| Warning | `plugins/claude-harness/hooks/git-guard.py:164` | A `#` comment swallowed the newline that now separates commands: `git status # l'agent`, newline, `git push --force` passed. | fixed in 03ae5ac: the `;` is emitted after the newline, and a comment ends at the newline |
| Warning | `plugins/claude-harness/hooks/git-guard.py:157` | A line continuation (`git \` then `push --force`) was read as two commands, so the push was not recognised as a git command. | fixed in 03ae5ac: a backslash-newline is removed, as in the shell |
| Warning | `plugins/claude-harness/hooks/git-guard.py:317` | A `bash -c` string did not split on newlines like a bare command: `bash -c "git status` newline `git push --force"` passed. | fixed in 03ae5ac: the `-c` string goes through `shell_text` |
| Info | `plugins/claude-harness/hooks/git-guard.py:67` | `SHELLS` has `bash`, `sh` and `zsh` only: a heredoc read by `dash`, `ksh`, `source /dev/stdin` or `. /dev/stdin` is still treated as data, so a `git push --force` in its body passes. Already on `develop`, which passed every heredoc case. | open: outside the lot's specification (deliverable 2 names those three shells); under the freeze, a fix waits for a real incident |
| Info | `plugins/claude-harness/hooks/git-guard.py:259` | A heredoc run through a command substitution (`bash -c "$(cat <<EOF`, `eval "$(cat <<EOF`) or by an interpreter (`python3 - <<EOF` with `os.system`) is not inspected. Already on `develop`. | open: the substitution case is review finding #5, rejected by the owner; the guard is not a sandbox |
| Info | `plugins/claude-harness/hooks/git-guard.py:269` | An unterminated heredoc now asks where `develop` denied, for example `cat <<EOF`, `x`, `EOF ; git push --force`. The shell reads the last line as body, so the push never runs. | none needed: `ask` is the safe verdict |

No regression found: every probe that `develop` denied is still denied or asked,
and the branch also denies 12 heredoc and newline cases that `develop` passed.

## Performance
| Severity | Location | Finding | Action |
|----------|----------|---------|--------|
| Info | `plugins/claude-harness/hooks/git-guard.py:259` | When a shell reads a heredoc, its body is lexed up to three times (`runs_a_shell`, the unbalanced-quote check, then `main`). A 1.9 MB command takes 5.2 s against 1.2 s on `develop`, still linear and under the 15 s hook timeout. Real commands are a few KB. | open: not worth extra code |

## Architecture
| Severity | Location | Finding | Action |
|----------|----------|---------|--------|

No finding. `SHELLS` replaces the duplicated shell tuple, `split_on_separators`
is extracted for `runs_a_shell` and `segments`, and the new functions are
documented. No dependency was added: `shlex` is standard library. The
`integration-check` template now uses the fields that `lot-deliverables.yml`
greps, and `tests/workflows.test.sh` checks the template against the workflow
rather than against a copied list.

## Coverage exclusions
| Exclusion | Business code? | Proposed action |
|-----------|----------------|-----------------|
| (none) | n/a | none |

## Migrations
n/a (`Migrations directory` is `n/a`).

## Lot-specific notes
- Incident 2 replayed (`git switch -c … && python3 - <<'EOF'`, body with
  `d'erreur`): the guard is silent (`tests/git-guard.test.sh`).
- This report was written in a second `lot-audit` run. The first run committed
  its fixes (03ae5ac) but stopped before steps 8 and 9, so no report was
  written. The fix rows above come from the commit message and tests of
  03ae5ac. This run found nothing new to fix.

## Recommended next steps
1. `lot-ship`.
2. If a heredoc read by `dash`, `ksh` or `source` ever costs time on a project,
   add them to `SHELLS` in a new lot.
