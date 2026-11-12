# Lot 35 — Skill friction

## lot-review
- `lot-review / census` — the autopilot stopped after a successful review
  (73db6a3) with "a commit touches files outside the lot's diff: AGENTS.md,
  CLAUDE.md". Those files got only the census line of the review report, which
  GATE-8 and DOC-1 require; `gate_step` in `autopilot.py` allows the lots file,
  `docs/memory.md` and `docs/audits/` but not the census. Cost: one stop and a
  manual resume at `audit`, the state file's `resume` set by hand to skip a
  second review.
