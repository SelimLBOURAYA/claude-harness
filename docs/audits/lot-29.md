# Lot Audit — Lot 29 — feat/lot-29-autopilot-confirm-handoff

**Harness ref:** 2.3.0
**Scope:** 14 modified files | **Fix commit:** none needed | **Verdict:** Ready for PR

## Summary
| Dimension    | Critical | Warning | Info |
|--------------|----------|---------|------|
| Security     | 0        | 0       | 0    |
| Performance  | 0        | 0       | 0    |
| Architecture | 0        | 0       | 1    |

## Security
| Severity | Location | Finding | Action |
|----------|----------|---------|--------|
| — | — | No finding | — |

`Skill(security-review)` ran on the diff against `origin/develop`; the diff fit in
the session, so its discovery and false-positive phases ran inline, without
sub-agents. Paths examined:

- **Confirmation without the owner** (`autopilot.py`, `drop_confirmations`): the
  model's structured answer is untrusted. Dropping the hand-off only turns a
  `blocked` into the `ok` the session could have answered directly; it adds no
  power. The confirmation sent is built from the checked lot, after
  `sync-status.py`, the lot ID check, the named lot (`autopilot.py N`) and the
  `feat/lot-N-*` branch check. Since the review fix `7ab6b63`, a question whose
  confirmations name another lot (a choice between lots) stays a question and
  stops the run.
- **Questions printed and notified** (`answer_hint`, `notify`): `notify-send`
  receives the text as one argv entry, no shell. The terminal output is the
  owner's own session's text, already printed before this lot.
- **Environment** (`tests/run.sh`, `tests/lib.sh`): the `unset` of
  `HARNESS_AUTOPILOT` and `ANTHROPIC_BASE_URL` is scoped to the test processes;
  `git-guard.py` still reads `HARNESS_AUTOPILOT` in real sessions, and the
  `git-guard` suite sets it itself where it tests the deny.

## Performance
| Severity | Location | Finding | Action |
|----------|----------|---------|--------|
| — | — | No finding: one regex pass over a handful of questions per `start` answer | — |

## Architecture
| Severity | Location | Finding | Action |
|----------|----------|---------|--------|
| Info | `tests/run.sh:13`, `tests/lib.sh:10` | The same `unset` in two places | kept: `run.sh` covers its own process and the `run-gate` probe, which sources no `lib.sh`; `lib.sh` covers a suite run alone (GATE-1) |

Harness checklist: `CLAUDE.md` and `AGENTS.md` byte-identical; `CONVENTIONS.md`
identical to `origin/main`; `## Gate parameters` unchanged and accurate; the
review report entered the census with its commit; commit titles Conventional,
English, no U+2014; plugin bumped to 2.4.0 in `plugin.json` and both
`marketplace.json` fields; no skipped or loosened test.

## Coverage exclusions
| Exclusion | Business code? | Proposed action |
|-----------|----------------|-----------------|
| (none) | — | — |

## Migrations
n/a (`Migrations directory` is `n/a`).

## Lot-specific notes
- The gate was rerun from `lot-review` after the amendment of 2026-10-22; the
  review report covers the whole diff, including the deferred findings the owner
  then asked to fix (`7ab6b63`, decision recorded in `dev-plan.md`, `cf022b2`).
- The fixes reach the 8 repos only after the user promotes `develop` → `main`;
  the stopped kreadevis-backend run resumes with `autopilot --resume --answer`
  after that promotion (out of the lot's scope).

## Recommended next steps
1. `lot-ship`.
2. After the merge, the owner promotes `develop` → `main`, then
   `claude plugin update claude-harness@claude-harness` in each scope.
