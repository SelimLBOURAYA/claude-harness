# Lot Review — Lot 19 — feat/lot-19-lot-start-guard

**Harness ref:** c3e00bf
**Model:** claude-opus-5
**Target:** local diff develop...HEAD
**Reviewed at:** c3e00bf
**Fix commit:** 5c9bc88
**Verdict:** Fixed

## Findings
| # | Severity | Location | Finding | Outcome |
|---|----------|----------|---------|---------|
| 1 | high | `plugins/claude-harness/skills/lot-start/sync-status.py:196` | An `ambiguous` or `scope-already-merged` stop could not be answered: the script had no way to record the user's answer, and the skill forbade editing the table to clear it. So a merge of a shared sub-lot branch (`2.1 ✅` / `2.2 ⬜` on `feat/lot-2-quotes`) raised the same stop on every run, and `--apply --start 2.2` always exited 3. The next sub-lot could never start. | fixed in 5c9bc88: a merge or scoped commit whose SHA the lots file cites in backticks now counts as reconciled. The skill says to record the answer that way, and fixture 7b covers the round trip |

Reviewed with no finding: `lot-lock-guard.py`, `lot-confirm.sh`,
`session-context.sh`, `lotfile.py`, `hooks.json`, the `lot-deliverables.yml`
grep change, and the documentation hunks.

## Inline comments posted
There was no PR open when the review ran, so the findings are recorded here only.

## Candidate lots
None.
