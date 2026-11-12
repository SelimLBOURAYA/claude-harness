# Lot Review — Lot 33 — feat/lot-33-ponytail-guards

**Harness ref:** 2.6.0
**Model:** Claude Opus 5.5 (claude-opus-5-5)
**Target:** local diff origin/develop...HEAD
**Reviewed at:** 921933a
**Verdict:** Fixed

Profile guard: `ANTHROPIC_BASE_URL` is `https://api.anthropic.com`, set by the
desktop app. The installed 2.6.0 guard reads any non-empty value as `deepseek`;
the review ran under the lot's own definition (`lotfile.py profile`, host
`api.anthropic.com` → `claude`). No PR open. No `test(33)` commit on the branch:
`lot-test` added nothing, so the `lot-test` boundary check had nothing to read.
`docs/memory.md` checked against the code: no stale note.

## Findings
| # | Severity | Location | Finding | Outcome |
|---|----------|----------|---------|---------|
| 1 | High | `plugins/claude-harness/hooks/git-guard.py:845` | `gh api -X PUT "$U"`: a write whose endpoint is a variable passed in silence, against the guard's rule that what it cannot resolve is asked | fixed in 921933a |
| 2 | High | `plugins/claude-harness/hooks/git-guard.py:295` | `gh api repos/o/r/merges -f base=main` merges a branch into main; neither the guard nor the permission rules covered it | fixed in 921933a (guard, template `ask`, autopilot `DENIED_TOOLS`) |
| 3 | Medium | `plugins/claude-harness/hooks/git-guard.py:627` | `option_value` ignored an attached short value: `gh pr edit 12 -Bmain` and `gh pr create -Bmain` were not read as a base of `main` | fixed in 921933a |
| 4 | Medium | `.github/scripts/sync-projects.sh:139` | A zero-byte `.claude/settings.json` is no input to `jq`, which writes an empty file back: the rules are never set | fixed in 921933a |
| 5 | Medium | `plugins/claude-harness/hooks/git-guard.py:845` | `gh api graphql` with a `mergePullRequest` mutation merges a PR with no guard and no permission rule | deferred to a candidate lot: needs the query body parsed, outside the shell forms the lot lists |

## Candidate lots
- `gh api graphql` mutations that merge a pull request or move a ref
  (`mergePullRequest`, `updateRef`, `deleteRef`): guard rule and permission rule.
