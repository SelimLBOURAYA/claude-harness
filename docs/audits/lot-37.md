# Lot Audit — Lot 37 — feat/lot-37-gate-cost

**Harness ref:** 2.10.0
**Scope:** 28 modified files | **Fix commit:** none needed | **Verdict:** Ready for PR

Run under the autopilot (`HARNESS_AUTOPILOT=1`). The `security-review`
discovery and false-positive phases ran inline, without sub-agents: the code
part of the diff (`autopilot.py`, `tests/run.sh`) fits in the session's context;
the rest is Markdown, the regenerated card and test suites.

## Summary
| Dimension    | Critical | Warning | Info |
|--------------|----------|---------|------|
| Security     | 0        | 0       | 2    |
| Performance  | 0        | 0       | 2    |
| Architecture | 0        | 0       | 1    |

## Security
| Severity | Location | Finding | Action |
|----------|----------|---------|--------|
| Info | `plugins/claude-harness/autopilot/autopilot.py:166` | The `backend` and `frontend` targeted entries (`./mvnw test -Dtest=*`, `npm test -- *`) let the session pass any further argument to Maven or the test runner, which can execute arbitrary code. Same level as the `<Validation command> *` entry already granted, as the lot's specification states, and the session already writes the tests it runs; Claude Code matches each part of a compound command separately, so no chaining | rejected: minor (autopilot) |
| Info | `plugins/claude-harness/autopilot/autopilot.py:172` | The `harness` entries are exact paths, listed at the step's launch, no wildcard: a suite created during the step is not runnable alone and falls back to the `Validation command`. Correct by design | rejected: minor (autopilot) |

No secret, credential, network endpoint or user-controlled path enters the
diff. `tests/run.sh` writes only into its own `mktemp -d`, removed on `EXIT`.
The parallel suites share no state: every write outside a payload string goes
to the suite's own `mktemp` directory (`$WORK`, `$REPO`, `$FAKEHOME`), checked
over `tests/`.

## Performance
| Severity | Location | Finding | Action |
|----------|----------|---------|--------|
| Info | `tests/run.sh:46` | All suites start at once, with no concurrency cap; on a 2-core CI runner the fixed waits of some suites may turn flaky. Already a candidate lot of the review | rejected: minor (autopilot); to watch on the lot's CI |
| Info | `tests/run.sh:42` | The INT/TERM trap kills the suite shells, not their children, which also ignore SIGINT as background jobs; they finish their short work into the unlinked buffer | rejected: minor (autopilot); no state outside the buffers directory, no measurable effect |

The lot's own aim, fewer and faster gate runs, is met: the suites run in
parallel and the conventions now ask one run per tree.

## Architecture
| Severity | Location | Finding | Action |
|----------|----------|---------|--------|
| Info | `CONVENTIONS.md:96` | GATE-2 and GATE-8 now let a documentary commit (report, memory, status row, census row) skip the gate; in this repository some suites read those documents, so such a commit can leave the tree red until `lot-ship`'s final run or the PR's CI. Accepted by the lot's specification, which names the final run and the CI as the proof of the lot | rejected: minor (autopilot) |

`TARGETED_TESTS` sits next to `TEST_FILES` and feeds both the allowlist and the
command hint, as deliverables 4 and 5 ask: one table, no drift between what is
told and what is allowed. No new dependency (`&` and `wait` only), no new
top-level module. `CLAUDE.md` and `AGENTS.md` are identical.

## Coverage exclusions
| Exclusion | Business code? | Proposed action |
|-----------|----------------|-----------------|
| (none) | n/a | none |

## Migrations
n/a (`Migrations directory` is `n/a`).

## Lot-specific notes
- The conventions trims (card budget) were reviewed in `lot-37-review.md`:
  the three that turned a user action into an agent action (CODE-4, LOT-7) or
  dropped a parameter name (GATE-7) were fixed in 6d9f0c9. No remaining trim
  grants an agent a new permission.
- The `harness` Stack's command hint and allowlist agree: `bash tests/<suite>.test.sh`,
  relative and absolute, for the suites present at launch.

## Recommended next steps
1. `lot-ship`: one `./tests/run.sh` on the final tree, then watch the parallel
   gate on the PR's CI; a cap on parallel suites only if it flakes.
2. The deepseek card has 9 characters of budget left: the next carded rule
   needs a budget decision first (candidate lot of the review).
