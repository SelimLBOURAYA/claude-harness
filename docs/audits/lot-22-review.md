# Lot Review — Lot 22 — feat/lot-22-friction-fixes

**Harness ref:** 30b4930 (installed copy 1.1.1, `gitCommitSha`; equals the fetched `origin/main`)
**Model:** claude-opus-5-5
**Target:** local diff origin/develop...HEAD (no PR open)
**Read at:** 3d54233
**Fix commit:** 5d662c6
**Reviewed at:** 5d662c6
**Verdict:** Fixed, 2 findings deferred

Review run with `code-review high --fix`, scoped to the branch against the fetched
`origin/develop`, in a forked agent; the session read the diff in parallel without
editing and added findings 9 and 10. No `--comment`: no PR exists before
`lot-ship` (deliverable 5 of this lot). Every fix stays inside the lot's source
diff; nothing was reverted.

## Findings
| # | Severity | Location | Finding | Outcome |
|---|----------|----------|---------|---------|
| 1 | major | `plugins/claude-harness/skills/lot-start/sync-status.py:303` | A merge of the row's flat branch closed the row while the row still listed an open sub-lot (`5.1 ✅, 5.3 🔄`): following the new `unlisted-subticket` advice closed the lot on the next sync | fixed in 5d662c6 — `ambiguous` stop naming the open sub-lots; test case 14 |
| 2 | major | `plugins/claude-harness/skills/lot-review/SKILL.md:113` | With the branch now created `--no-track`, `code-review --fix` without a target has no upstream and falls back to `main...HEAD`: every unpromoted commit of develop would be reviewed and "fixed" | fixed in 5d662c6 — the call names the branch and `origin/develop` |
| 3 | major | `plugins/claude-harness/hooks/lotfile.py:266` | `lock_merged` matched audit commits on the lot base: the audit of 5.2 (or a `docs(5)` audit) after 5.3's confirmation removed the 5.3 lock mid-development | fixed in 5d662c6 — exact lot ID, as `sync-status.py`; sibling-audit assertion in `session-context.test.sh` |
| 4 | minor | `plugins/claude-harness/hooks/lotfile.py:264` | Merge evidence is the flat branch name shared by every sub-lot: a sibling sub-lot's PR merged after the confirmation removes the current sub-lot's lock | deferred to a candidate lot — fail-safe (removes a right, the user re-confirms), and ignoring merge evidence for sub-lot locks would leave them uncleared under `--no-ff` merges |
| 5 | minor | `plugins/claude-harness/hooks/session-context.sh:53` | The context announced "removed the lock" even when `rm` failed, and the hook ran `lotfile.py lock` twice plus `lock-merged` with no lock present | fixed in 5d662c6 |
| 6 | minor | `plugins/claude-harness/skills/lot-audit/SKILL.md:41` | Step 0 exempts `CLAUDE.md` and `AGENTS.md` wholesale after **Reviewed at**, not only their census rows: a post-review change of the `Validation command` or `Coverage threshold` passes unreviewed | deferred to a candidate lot — narrowing it needs a diff-content check, a design change beyond this lot |
| 7 | minor | `plugins/claude-harness/skills/lot-start/sync-status.py:128` | The `unlisted-subticket` message showed `` `5.3 ✅, …` `` as the example, suggesting to mark the open sub-lot done | fixed in 5d662c6 — `` `<sub> <status>, …` `` |
| 8 | nit | `plugins/claude-harness/skills/lot-start/sync-status.py:146` | `unlisted_sub_lots` scanned the whole lots file for every in-progress row, landed or not | fixed in 5d662c6 — computed only once something landed |
| 9 | minor | `plugins/claude-harness/skills/lot-start/sync-status.py:116` | `unlisted_sub_lots` matched `lot N.M` anywhere in the file, with no word boundary, where deliverable 4 says a **heading** `Ticket LOT-N.M`; lot 22 extended it to rows without sub-lots and to the merge path, so prose citing another repository's lot (`dev-plan.md`: "elya (lot 3.3)") would block a row's closure | fixed in 5d662c6 — headings only, `\blot`; test case 15, which fails without the fix |
| 10 | minor | `plugins/claude-harness/skills/lot-audit/checklists.md:136` | The new list of the `docs/audits/` files a PR may add omits `lot-0-integration.md`, which `lot-deliverables.yml` explicitly allows on every frontend branch | fixed in 5d662c6 |

`./tests/run.sh`: 14/14 suites green before the fix commit.

## Candidate lots
- Lock of a sub-lot on a flat branch (finding 4): tell a sibling sub-lot's merge
  from the locked sub-lot's own, e.g. by requiring the audit commit of the exact
  sub-lot when the lock names one, and keeping the merge evidence for row-level
  locks only.
- `lot-audit` step 0 (finding 6): after **Reviewed at**, accept a `CLAUDE.md` /
  `AGENTS.md` change only when its hunks stay inside `## Project documents`.
