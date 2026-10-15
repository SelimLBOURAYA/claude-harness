# Lot Review — Lot 25 — feat/lot-25-guard-heredoc-report-fields

**Harness ref:** 2.0.0
**Model:** Claude Opus 5.5 (`claude-opus-5-5`)
**Target:** local diff origin/develop...HEAD
**Reviewed at:** f8af538
**Verdict:** Fixed

No pull request was open at review time.

## Findings
| # | Severity | Location | Finding | Outcome |
|---|----------|----------|---------|---------|
| 1 | high | `plugins/claude-harness/hooks/git-guard.py:219` | A heredoc piped to a shell named on a later line (`cat <<EOF \|`, body, `EOF`, then `bash`) let a `git push --force` in its body pass: only the heredoc's own line was searched for a shell. Regression of this lot, `develop` denied it. | fixed in f8af538: every heredoc body is inspected as code when any command of the command line is a shell |
| 2 | high | `plugins/claude-harness/hooks/git-guard.py:123` | A newline outside quotes did not end a command: `git status`, newline, `git push --force` passed. Already on `develop`; this lot made multi-line commands more frequent by stripping heredoc bodies. | fixed in f8af538, scope extended with the owner's agreement (`dev-plan.md`, lot 25 deliverable 4) |
| 3 | medium | `plugins/claude-harness/hooks/git-guard.py:193` | `bash \` then `<<'EOF'` on the next line was not seen as a shell reading the heredoc, so its `git push --force` passed. | fixed in f8af538 (covered by the whole-command check of #1) |
| 4 | low | `plugins/claude-harness/hooks/git-guard.py:163` | The arithmetic shift in `$((1<<2))` was read as an unterminated heredoc and asked; `develop` passes it. | fixed in f8af538: `<<` inside `((...))` opens no heredoc |
| 5 | medium | `plugins/claude-harness/hooks/git-guard.py` | A git command inside `$(...)` or backticks is not inspected, in a heredoc body or elsewhere. Already on `develop`. | rejected: needs a substitution parser, and a coarse rule would ask on `git push origin $(git branch --show-current)`, which the guard passes on purpose |

The integration-check field rename (`Frontend SHA`, `Backend SHA`) and its
consistency test in `tests/workflows.test.sh` are correct: the template carries
every field `lot-deliverables.yml` greps.

## Candidate lots
none (finding #5 is rejected; under the freeze a lot opens only on a real incident)
