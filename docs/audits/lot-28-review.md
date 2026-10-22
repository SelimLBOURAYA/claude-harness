# Lot Review — Lot 28 — feat/lot-28-autopilot-lot-answers

**Harness ref:** 2.2.0
**Model:** claude-opus-5-5
**Target:** local diff origin/develop...HEAD
**Reviewed at:** baa9f10
**Verdict:** Fixed

No pull request open. The review followed the autopilot run stopped at its
`review` step: the headless `lot-review` session could not run its Step 0
`printenv` (not in the per-process allowlist). That defect was fixed first, in
this lot by owner decision (`77b271e`), then this review ran in an interactive
session under the `claude` profile.

## Findings
| # | Severity | Location | Finding | Outcome |
|---|----------|----------|---------|---------|
| 1 | Medium | `plugins/claude-harness/autopilot/autopilot.py:322` | A session answering `ok` with questions stopped the run with status `ok`: `--answer` refused, no answer command printed | fixed in 39d3a76 (owner decision: recorded `blocked`) |
| 2 | Medium | `plugins/claude-harness/autopilot/autopilot.py:606` | After `--resume --answer`, a timeout, Ctrl-C or missing structured answer overwrote `blocked`: the same answers could not be sent again | fixed in 39d3a76 (owner decision: the stop stays `blocked` with its questions) |
| 3 | Low | `plugins/claude-harness/autopilot/autopilot.py:546` | A blank `--answer` was accepted; `--lot ""` passed the truthiness checks and was ignored | fixed in 39d3a76 |
| 4 | Low | `plugins/claude-harness/autopilot/autopilot.py:68` | `CONFIRMATION` repeated the lot ID pattern instead of building on `LOT_ID` | fixed in 39d3a76 |
| 5 | Low | `plugins/claude-harness/autopilot/autopilot.py:506` | The `--answer` applicability rule was written twice (`answer_hint`, `main`) | fixed in 39d3a76 (`answerable()`) |
| 6 | Low | `plugins/claude-harness/autopilot/autopilot.py:600` | `expected_lot` derived from two sources | fixed in 39d3a76 (state only) |
| 7 | Low | `plugins/claude-harness/autopilot/autopilot.py:220` | The `printenv` allowlist fix (`77b271e`) lies outside the lot 28 deliverables (LOT-5) | rejected: owner decision 2026-10-22, recorded in the lot's arbitrages, to state in the PR |
| 8 | Low | `plugins/claude-harness/autopilot/autopilot.py:570` | `--dry-run --resume --answer` prints the fresh-run commands, not the resume | rejected: `--dry-run` previews a run's step commands; a resume preview is not a deliverable |

Owner request taken at the decision batch: the lot is a positional argument
(`autopilot.py N`) instead of `--lot N`, for short commands (39d3a76, README,
tests and arbitrages updated).

`lot-test` boundary: `3f9c505` touches `tests/autopilot.test.sh` only; its one
removed line is generalised to the `answer` step, no assertion weakened.

Project memory: amended in baa9f10 (positional lot, a permission ask in `-p` is
a deny); 5870 characters.

## Candidate lots
none
