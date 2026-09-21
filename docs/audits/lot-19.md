# Lot Audit — Lot 19 — feat/lot-19-lot-start-guard

**Harness ref:** 35b2e0a
**Scope:** 26 modified files | **Verdict:** Fix warnings

## Summary
| Dimension    | Critical | Warning | Info |
|--------------|----------|---------|------|
| Security     | 0        | 1       | 0    |
| Performance  | 0        | 0       | 1    |
| Architecture | 0        | 0       | 0    |

## Security

The step ran through the `security-review` skill, with two stages: one analysis sub-task, then one false-positive check per finding. It covered `lot-lock-guard.py`, `lot-confirm.sh`, `session-context.sh`, `lotfile.py`, `sync-status.py`, `hooks.json` and the `lot-deliverables.yml` change. It found no vulnerability at confidence 8 or above. The one reported path was rated a false positive as a *vulnerability*, because the model working around a workflow guard crosses no trust boundary. It remains a concrete gap in what the guard is for, so it is recorded here:

| Severity | Location | Finding | Action |
|----------|----------|---------|--------|
| Warning | `plugins/claude-harness/hooks/lot-lock-guard.py:80` | Writes under `.git/` are never judged. `git rev-parse --show-toplevel` fails inside the git dir, so `repo_root` returns `None` and the guard exits silently. A Write/Edit on `.git/HEAD` (to switch to another branch or detach) or on `.git/config` (to set `core.worktree`) then makes the guard silent on every write, including `.claude/current-lot`. The model could therefore forge a lock with the Write/Edit tools alone. This was reproduced on a scratch repo. Claude Code's own permission prompt for `.git/` probably still applies, but that was not verified. | Pending user decision: deny any tool write whose resolved path has a `.git` component, and add the `.git/HEAD` and `.git/config` cases to `tests/lot-lock-guard.test.sh`. That is about 5 lines plus 3 assertions. Recommended within lot 19 |

Checked with no finding:
- **`lot-lock-guard.py`:** `../`, symlinks and relative paths are normalised by `realpath`. The lots file is exempt only by an exact realpath match. The guard never answers `allow`.
- **`lot-confirm.sh`:** the regex must match the entire prompt, the lot ID is limited to `[0-9a-z.]`, and all JSON goes through `jq --arg`.
- **Python helpers:** all subprocess calls use list arguments, with no `shell=True`.
- **`sync-status.py`:** it writes only the lots file inside the repository root.

## Performance
| Severity | Location | Finding | Action |
|----------|----------|---------|--------|
| Info | `plugins/claude-harness/hooks/lot-lock-guard.py:80-100` | Every Edit or Write in a harnessed repository spawns 2 to 3 short `git` subprocesses and reads `CLAUDE.md`. That is milliseconds per write, well within the hook timeout. | None |

`session-context.sh` stays under its cap: each section has its own budget and the whole output has a global 9,000-character cap, both tested.

## Architecture
| Severity | Location | Finding | Action |
|----------|----------|---------|--------|
| — | — | No finding | — |

- **Documents:**
  - `CLAUDE.md` and `AGENTS.md` are byte-identical.
  - The census is updated in the same commit as each added document: the new hooks, `lot-start` and `lot-19-review.md`.
  - `CONVENTIONS.md` is the master.
- **Commits and code:** commit messages are in English, follow Conventional Commits and contain no U+2014. There is no commented-out code.
- **Stdlib only:** hooks use the standard library only (V6 constraint), and the shared readers are factored into `lotfile.py` rather than duplicated.
- **`dev-plan.md`:** changed only on status lines, apart from the start-of-lot decisions block recorded at confirmation.
- **Scope:**
  - Matches deliverables 1 to 5 of the lot section.
  - The Bash-write limit is written in the hook, the skill and the README, as decided.
  - `chore/*` branches stay silent, as decided.

## Coverage exclusions
| Exclusion | Business code? | Proposed action |
|-----------|----------------|-----------------|
| (none) | — | There is no coverage tool (shell test suite). Every new hook has a dedicated fixture test file. |

## Migrations
n/a — `Migrations directory` is `n/a`.

## Lot-specific notes
- `lot-review` fixed one high finding in 5c9bc88: a lot-start stop the user had already answered came back on every run.
- The validation criteria that need a live session are left to `lot-ship`'s test plan, because the gate cannot exercise them: the first response after `/compact` should contain the re-injected state, and a `deepseek` session should load the rules card while a `claude` session should not.

## Recommended next steps
1. Decide on the Warning. Recommended: fix it in lot 19, which means denying `.git/` writes, adding the test cases and re-running `./tests/run.sh`.
2. `./tests/run.sh` must be green before the PR.
3. `lot-ship`.
