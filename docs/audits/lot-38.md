# Lot Audit — Lot 38 — feat/lot-38-lot-section-pointer

**Harness ref:** 2.10.0
**Scope:** 14 modified files | **Fix commit:** none needed | **Verdict:** Ready for PR

## Summary
| Dimension    | Critical | Warning | Info |
|--------------|----------|---------|------|
| Security     | 0        | 0       | 1    |
| Performance  | 0        | 0       | 1    |
| Architecture | 0        | 0       | 2    |

Run under the autopilot (`HARNESS_AUTOPILOT=1`). The security review's discovery
and false-positive phases ran inline, without sub-agents: the code diff is 88
lines over six files. No Critical or Warning finding, so no fix commit; the Info
rows are left as the autopilot prescribes.

## Security
| Severity | Location | Finding | Action |
|----------|----------|---------|--------|
| Info | `plugins/claude-harness/hooks/lotfile.py:327` | `cli_section` opens the path `lots_file` resolves from the `Lots file` gate parameter, which `os.path.join` does not confine to the repository (an absolute or `../` value). Pre-existing in `lots_file`, used the same way by `table`; the new command only prints a line range, never the file's text, and the parameter is the repository owner's own `CLAUDE.md`. `$section` is plain data in the hook output, never evaluated | rejected: minor (autopilot) |

## Performance
| Severity | Location | Finding | Action |
|----------|----------|---------|--------|
| Info | `plugins/claude-harness/hooks/session-context.sh:69` | One more `python3` start per SessionStart (tens of milliseconds) that re-resolves the gate parameters and the lots file already read by the `table` call. Not measurable against the session start; the lot's point is to save whole-context re-reads | rejected: minor (autopilot) |

## Architecture
| Severity | Location | Finding | Action |
|----------|----------|---------|--------|
| Info | `plugins/claude-harness/hooks/lotfile.py:257` | The fence tracking toggles on any ```` ``` ```` or `~~~` line, so a `~~~` line inside a ```` ``` ```` block (or the reverse) flips it. No lots file of the portfolio nests fences of the two kinds | rejected: minor (autopilot) |
| Info | `plugins/claude-harness/hooks/lotfile.py:45` | The pointer follows `LOT_BRANCH` (`feat/lot-N-*` only): a `fix/lot-*` or `chore/lot-*` branch gets no `Current lot section` line. As the specification states (deliverable 2, "`LOT_BRANCH`"); the skills fall back to `lotfile.py section` with the lot number | rejected: minor (autopilot) |

Checked with no finding: the pure `lot_section` function lives in the shared
reader module with the other lots-file readers; `session-context.sh` keeps its
`CAP` (the new line comes before the truncation, after the separately capped
table); the hook still exits 0 when the command fails (`2>/dev/null || true`);
the skills' fallback paths resolve from the skill's base directory, so they run
in a consuming repository (review finding 4).

## Coverage exclusions
| Exclusion | Business code? | Proposed action |
|-----------|----------------|-----------------|
| (none) | n/a | none |

## Migrations
n/a (`Migrations directory` is `n/a`).

## Lot-specific notes
- `./tests/run.sh`: 24/24 suites green, `session-context` at 104 assertions,
  covering `## LOT N`, `## Lot 0N`, a sub-lot, the last section, a level-1
  heading after the last lot, a fenced heading, a dotted `## LOT 5.1`, a
  duplicated lot, a missing heading
  and a non-lot branch.
- The manual check on the 8 portfolio lots files (validation criterion 2) was
  not run by this audit: it belongs to the PR description, per the lot.
- This session ran the installed plugin 2.10.0, which predates the lot: its
  SessionStart output carried no `Current lot section` line, as expected.

## Recommended next steps
1. `lot-ship`: record the manual `lotfile.py section` check on the 8 repos in
   the PR, as validation criterion 2 requires.
2. After promotion, count the lots-file lookup calls per step on the next
   autopilot run (validation criterion 4).
