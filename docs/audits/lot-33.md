# Lot Audit — Lot 33 — feat/lot-33-ponytail-guards

**Harness ref:** 2.6.0
**Scope:** 39 modified files | **Fix commit:** 87d0307 | **Verdict:** Ready for PR

## Summary
| Dimension    | Critical | Warning | Info |
|--------------|----------|---------|------|
| Security     | 0        | 1       | 1    |
| Performance  | 0        | 0       | 1    |
| Architecture | 0        | 0       | 1    |

## Security
| Severity | Location | Finding | Action |
|----------|----------|---------|--------|
| Warning | `templates/project/.claude/settings.json:16` | The `deny` list, the second layer behind the git guard, missed a push to the full ref: `git push origin HEAD:refs/heads/main` matches no rule. The guard denies it, but the list exists for the forms the guard leaves out by decision (`eval`, backticks) | fixed in 87d0307: `*:refs/heads/main` and `*:refs/heads/main *` under the three prefixes, in the template, `DENIED_TOOLS` and `tests/skeleton.test.sh` |
| Info | `plugins/claude-harness/hooks/git-guard.py:845` | `gh api graphql` mutations (`mergePullRequest`, `updateRef`) merge or move a ref with no guard and no rule; already deferred by the lot review | open: candidate lot, see below |

Security review run inline, without sub-agents: the diff fits in this session.
Checked with no finding: `lotfile.profile()` compares the parsed hostname
exactly (`api.anthropic.com.evil`, `https://api.anthropic.com@evil` and an
unparseable URL all read `deepseek`); every new workflow input goes through
`env:` (deliverable 16, `CONVENTIONS_REF`); `ponytail-context.sh` passes the
skill text through `jq --arg`; `sync-projects.sh` takes its paths from
`projects.json` only; no secret, no absolute user path in the diff.

## Performance
| Severity | Location | Finding | Action |
|----------|----------|---------|--------|
| Info | `plugins/claude-harness/hooks/session-context.sh:83` | The profile check starts one `python3` per session start (tens of milliseconds), and `ponytail-context.sh` adds about 1.8K characters of context per session | accepted: one process at session start, the text is the lot's purpose |

## Architecture
| Severity | Location | Finding | Action |
|----------|----------|---------|--------|
| Info | `plugins/claude-harness/autopilot/autopilot.py:51` | `DENIED_TOOLS` restates the template's rules in code; the plugin does not ship `templates/`, so it cannot read them | accepted: `tests/autopilot.test.sh` checks the two lists are equal |

Conventions checked: one profile definition (`lotfile.py`), read by the three
consumers; deviations from the specification (second hook, `printenv` kept in
`lot-review`) are user decisions recorded in the lot's arbitrages.

## Coverage exclusions
| Exclusion | Business code? | Proposed action |
|-----------|----------------|-----------------|
| none (shell suite, no coverage tool) | n/a | none |

## Migrations
n/a

## Lot-specific notes
- The installed plugin is 2.6.0: its `lot-review` guard reads the desktop
  app's `ANTHROPIC_BASE_URL=https://api.anthropic.com` as `deepseek`. The
  review ran under the lot's own definition; the guard is right only after
  promotion and update.
- The 8 repositories' CI fails `harness-invariants` from the promotion until
  each merges its `chore/sync-harness-files` pull request: the step says so.

## Recommended next steps
1. `lot-ship`.
2. Recommended lot: `gh api graphql` merge and ref mutations, guard rule and
   permission rule (reason: the one write path to `main` left by this lot;
   files: `git-guard.py`, `templates/project/.claude/settings.json`,
   `autopilot.py`).
