# Lot Audit — Lot 20 — feat/lot-20-plugin-currency

**Harness ref:** 9f4d747
**Scope:** 28 modified files | **Verdict:** Fix warnings

## Summary
| Dimension    | Critical | Warning | Info |
|--------------|----------|---------|------|
| Security     | 0        | 0       | 1    |
| Performance  | 0        | 0       | 1    |
| Architecture | 0        | 1       | 2    |

Review prerequisite: `docs/audits/lot-20-review.md` records `Reviewed at: 2dda298`;
the only commits after it are its two listed fix commits (`4346ebd`, `6f586f2`)
and the report commit (`9f4d747`). No unreviewed code.

## Security

`Skill(security-review)` ran on `develop...HEAD` in this repository, with the
lot's risk areas as custom instructions: the `git ls-remote` subprocess of
`plugin-currency.py`, the prompt parsing of `lot-confirm.sh`, the `N.M`
acceptance in `lotfile.py` / `lot-lock-guard.py`, and the new version-bump step
of `harness-invariants.yml`. Nothing held above the confidence threshold.

| Severity | Location | Finding | Action |
|----------|----------|---------|--------|
| Info | `plugins/claude-harness/hooks/plugin-currency.py:136` | `ref` (from `known_marketplaces.json`) is passed to `git ls-remote origin <ref>` without `--`: a value starting with `-` would be read as an option (e.g. `--upload-pack=`). Not exploitable — the file is Claude Code's own state in the user's config directory, and whoever can write it can already run code as the user through `settings.json` hooks. List argv, no shell; prompts disabled (`GIT_TERMINAL_PROMPT=0`, SSH `BatchMode`, stdin closed), timeout bounded. | Optional hardening: skip a ref starting with `-`. |

Checked and clean: `lot-confirm.sh` matches the whole trimmed prompt against a
digits-only id, so no newline or metacharacter reaches the lock file; the lock
guard's decision logic is unchanged (messages only), and a `3.3` lock opens
writes only on the exact branch confirmed; the workflow step's only expression
(`github.event.pull_request.base.sha`) goes through `env:`, and version strings
are only compared and echoed.

## Performance
| Severity | Location | Finding | Action |
|----------|----------|---------|--------|
| Info | `plugins/claude-harness/hooks/session-context.sh:34` | The currency check makes a network call on every `SessionStart` trigger (`startup`, `resume`, `clear`, `compact`), bounded by `DEFAULT_TIMEOUT = 5` s, inside the hook's 15 s timeout. Offline, the call fails fast; on a black-holed network, a compaction can take up to 5 s longer. | Accepted: re-checking after compaction is the point (the state re-injection is re-read then). |

## Architecture
| Severity | Location | Finding | Action |
|----------|----------|---------|--------|
| Warning | `README.md` — "After a promotion: the owner's runbook" | The lot edits the conventions master (`CONVENTIONS.md` §9, §13). Once promoted to `main`, every consuming repository's copy differs from the master, and `harness-invariants.yml` fails there on the next push to `develop`/`main` (outside a pull request, the absence of a match is a hard failure). The new runbook lists the plugin refresh and the session restart, not the `cp CONVENTIONS.md` into the 8 repositories (§12, master propagation, item 3). Same pattern on lot 19. | Add a runbook step (propagate the master into each repository's adoption lot, or expect their CI red until then), in this lot or tracked. |
| Info | `.github/workflows/harness-invariants.yml:282` | The bump check is skipped with a warning when there is no base SHA (push events). Consistent with §7 (no direct push to `develop`/`main`), so the pull request run is the one that counts. Two open PRs bumping to the same number both pass against their own base; the second merge carries the collision. | Accepted; single-maintainer, PRs merged one at a time. |
| Info | `plugins/claude-harness/hooks/plugin-currency.py` | New module stays standard-library only (V6), never blocks (always exit 0, silent on any doubt), reads the plugin identity from its own path (no hard-coded name). `CLAUDE.md` = `AGENTS.md`; census updated (repository layout lists `plugin-currency.py`, review report added with its commit); commit titles English, Conventional Commits, no U+2014; no commented-out code; `dev-plan.md` touched only by the planning and status commits. | none |

Lot scope: P1 (currency warning), P2 (version `1.0.0` + bump job), P3 (stop on
`Unknown skill`), P6/P7 (runbook, troubleshooting), minor findings 1–3 — all
within the arbitrations of 2026-09-22. P4 stays out, as decided.

## Coverage exclusions
| Exclusion | Business code? | Proposed action |
|-----------|----------------|-----------------|
| (none — `Coverage tool` is none for this repository) | n/a | none |

## Migrations
n/a (`Migrations directory` is `n/a`).

## Lot-specific notes
- The review raised four defects in `plugin-currency.py` and the bump job
  (wrong install record on a shared cache directory, cross-version fallback,
  suffix match on `ls-remote`, version decrease accepted); all fixed with tests
  before this audit.
- The validation criterion "README troubleshooting replayed on the installed
  copy" is a manual owner check after promotion; it cannot be exercised from
  this branch, whose plugin is not installed yet.

## Recommended next steps
1. Decide on the Warning: add the `CONVENTIONS.md` propagation step to the runbook in this lot, or track it.
2. `./tests/run.sh` green before the PR, then `lot-ship`.
