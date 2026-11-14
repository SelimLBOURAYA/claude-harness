# Lot Review — Lot 38 — feat/lot-38-lot-section-pointer

**Harness ref:** 2.10.0
**Model:** claude-opus-5-5
**Target:** local diff origin/develop...HEAD
**Reviewed at:** 4fa6913
**Verdict:** Fixed

No pull request open: the review is of the local diff, run under the autopilot.

## Findings
| # | Severity | Location | Finding | Outcome |
|---|----------|----------|---------|---------|
| 1 | Medium | `plugins/claude-harness/hooks/lotfile.py:256` | A `## ` line inside a fenced code block counted as a heading: a lot section quoting a heading in a code block was cut short, or a fenced `## LOT N` made the lot ambiguous | fixed in c67ef51 |
| 2 | Low | `plugins/claude-harness/hooks/lotfile.py:52` | A level-1 heading after the last lot did not end its section, so the range ran past it to the end of the file | fixed in c67ef51 |
| 3 | Low | `plugins/claude-harness/hooks/lotfile.py:50` | `## LOT 2.1` matched lot `2` (the lookahead let `.1` through), making lot 2 ambiguous or pointing at the dotted sub-lot | fixed in c67ef51 |
| 4 | Medium | `plugins/claude-harness/skills/lot-audit/SKILL.md:74`, `lot-review/SKILL.md:73`, `lot-test/SKILL.md:58` | The fallback named `lotfile.py` with no path: the session runs in the consuming repo, where no `lotfile.py` exists, so the fallback could not run. Now `python3 <this skill's base directory>/../../hooks/lotfile.py`, like `lot-start` | fixed in c67ef51 |
| 5 | Low | `docs/memory.md:64` | The lot-section note said a section ends at the next level-2 heading, which finding 2 made false | fixed in 4fa6913 |

The `lot-test` commit 741b7e2 touches `tests/session-context.test.sh` only. The
one assertion it changes follows the new `## Annex` fixture heading, so no check
was loosened. `lot-ship` has no step that reads the lot section, so it needs no
pointer (deliverable 3: "là où elles disent de lire la section du lot").

## Candidate lots
none
