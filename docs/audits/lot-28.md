# Lot Audit — Lot 28 — feat/lot-28-autopilot-lot-answers

**Harness ref:** 2.2.0
**Scope:** 10 modified files | **Fix commit:** none needed | **Verdict:** Ready for PR

The security discovery and false-positive phases ran inline, without sub-agents:
the diff (`origin/develop...HEAD`, +484 −55) fits in the session's context.
Interactive session, `HARNESS_AUTOPILOT` unset.

## Summary
| Dimension    | Critical | Warning | Info |
|--------------|----------|---------|------|
| Security     | 0        | 0       | 0    |
| Performance  | 0        | 0       | 0    |
| Architecture | 0        | 0       | 2    |

## Security
| Severity | Location | Finding | Action |
|----------|----------|---------|--------|

Checked, nothing found:

- `--answer TEXT` and the positional lot reach `claude -p` on stdin
  (`autopilot.py:309`), the command is an argv list, no shell: no command
  injection. The lot is validated by `LOT_ID.fullmatch` before it enters the
  `lot-start` prompt.
- Confirmation bypass: `lot-confirm.sh:32` anchors its pattern on the whole
  trimmed prompt (`^…$`), and the answered prompt always opens with the fixed
  `Owner answers to your questions:` line (`answer_prompt`), so an answer can
  never write the lot lock. The `CONFIRMATION` refusal in `main` is a second,
  explicit guard; the confirmation stays the script's, after `check_start`.
- `--answer` reaches only a recorded `blocked` stop at `start` or `dev`
  (`answerable`), and only with a recorded `session_id`; a lot mismatch, a dirty
  tree or a timeout outside an answered session record no `blocked` status and
  are not answerable.
- Allowlist: the two `printenv` entries (`autopilot.py:220`) are exact commands,
  no wildcard; they print the base URL and the autopilot flag, no key. The
  `python3` restriction to the plugin cache is unchanged.
- No secret, token or absolute user path added; `notify-send` takes the message
  as an argv element.

## Performance
| Severity | Location | Finding | Action |
|----------|----------|---------|--------|

Checked, nothing found: the lot adds argument checks, one string comparison
after `lot-start` and two state keys; no new process, loop or file read.

## Architecture
| Severity | Location | Finding | Action |
|----------|----------|---------|--------|
| Info | `dev-plan.md:2342` | The `Lots file` changes beyond status lines: four arbitrage rows added at the review | accepted: owner decisions of 2026-10-22, recorded in the lot's arbitrages by `lot-review` |
| Info | `dev-plan.md:57`, `dev-plan.md:2293` | The status row, Livrables 1, 2, 4 and 5 and the validation criteria still say `--lot N`; the code, `README.md`, tests and memory use the positional `autopilot.py N` | open: superseded by the arbitrage row "Lot nommé (revue, 2026-10-22)"; the `Lots file` changes only on the owner's approval |

Checked: `CLAUDE.md` and `AGENTS.md` byte-identical; `CONVENTIONS.md` identical
to `origin/main`; census carries `lot-28-review.md` (this report added below);
commit titles Conventional Commits, no U+2014; no commented-out code; plugin
version 2.3.0 in both `plugin.json` and `marketplace.json`; `docs/memory.md`
5872 characters (≤ 6000); the only `docs/audits/` files added are the lot's own
deliverables. Every deliverable of the lot section has a test in
`tests/autopilot.test.sh`; `./tests/run.sh` 15/15 suites green.

## Coverage exclusions
| Exclusion | Business code? | Proposed action |
|-----------|----------------|-----------------|
| (none) | n/a | none |

## Migrations
n/a (`Migrations directory` is `n/a`).

## Lot-specific notes

- `77b271e` (the `printenv` allowlist) lies outside the lot's Livrables; kept by
  owner decision at the review, to be stated in the PR description (LOT-5).
- The "to check at lot start" item of the lot section (the `UserPromptSubmit`
  hook firing on a `claude -p --resume` prompt) is not provable by the fake
  `claude` of the tests; the first real `--resume --answer` run confirms it.

## Recommended next steps
1. `lot-ship`, with the `printenv` change and the `--lot N` wording of the
   `Lots file` stated in the PR description.
