# Lot Audit — Lot 22 — feat/lot-22-friction-fixes

**Harness ref:** 30b4930 (installed copy 1.1.1, `plugin-currency.py --installed-sha`; equals the fetched `origin/main`)
**Scope:** 23 modified files | **Verdict:** Ready for PR

Audited at d0ab2e5 against the fetched `origin/develop`. Step 0: **Reviewed at**
5d662c6; the only commit after it, d0ab2e5, touches `docs/audits/` and the
census (`CLAUDE.md`, `AGENTS.md`), which this lot's step 0 accepts.

## Summary
| Dimension    | Critical | Warning | Info |
|--------------|----------|---------|------|
| Security     | 0        | 0       | 1    |
| Performance  | 0        | 0       | 1    |
| Architecture | 0        | 2       | 3    |

## Security
`Skill(security-review)` ran on the branch diff, with its discovery and
false-positive phases **inline**, without sub-agents (deliverable 8): the code
diff, about 600 lines, fits in the session's context. No vulnerability at
confidence ≥ 8.

| Severity | Location | Finding | Action |
|----------|----------|---------|--------|
| Info | `plugins/claude-harness/hooks/lotfile.py:240` | `lock_merged` takes merge evidence from commit subjects on `develop`: whoever can push a crafted subject there can make the hook remove a lock. Removing a lock withdraws a right and grants none (the next write still needs the user's `lot-start confirm N`), the path removed is fixed (`$root/.claude/current-lot`), and git is called with an argument list, no shell | None: fail-safe by design (arbitrage 7) |

## Performance
| Severity | Location | Finding | Action |
|----------|----------|---------|--------|
| Info | `plugins/claude-harness/hooks/session-context.sh:52` | One more `python3` and one `git log --first-parent -200` per session start, only when a lock exists | None: a few tens of milliseconds, no network, and review finding 5 already removed the duplicate calls |

## Architecture
| Severity | Location | Finding | Action |
|----------|----------|---------|--------|
| Warning | `plugins/claude-harness/skills/lot-audit/SKILL.md:38` | Step 0 accepts any change to `CLAUDE.md` / `AGENTS.md` after **Reviewed at**, not only census rows: a post-review change to the `Validation command` or the `Coverage threshold` reaches the audit unreviewed (review finding 6) | Tracked: candidate lot in `lot-22-review.md`, accept only hunks inside `## Project documents` |
| Warning | `plugins/claude-harness/hooks/lotfile.py:264` | The merge evidence of a sub-lot lock is the flat branch shared by every sub-lot: a sibling sub-lot's merge removes the current sub-lot's lock (review finding 4) | Tracked: candidate lot in `lot-22-review.md`; fail-safe meanwhile (the user re-confirms) |
| Info | `plugins/claude-harness/skills/lot-review/SKILL.md:113` | `Skill(code-review) --fix feat/lot-N-<slug> (diff against origin/develop)`: the base is prose next to the argument, and that `code-review` honours it with a branch target was only observed in this lot's own review run | Watch at the next lot's review; record as `lot-review / 2` friction if the base is wrong |
| Info | `plugins/claude-harness/skills/lot-review/SKILL.md:4` | The rewritten `description` and introduction were not rewrapped (lines over 100 characters) | Cosmetic, no action |
| Info | `plugins/claude-harness/skills/lot-review/SKILL.md:9` | `metadata.version` stays `1.1` (and `lot-audit` `2.1`) while their contracts changed (`--comment` removed, **Read at** / **Reviewed at**) | No action in the lot: the plugin version is bumped at promotion (lot 20) |

Checklist (harness and documentation, lot scope):
- `CLAUDE.md` and `AGENTS.md` byte-identical; `## Gate parameters` unchanged and accurate.
- `CONVENTIONS.md`: this repository holds the master; the lot does not modify it.
- Commits in English, Conventional Commits, no U+2014 in messages or added lines.
- `dev-plan.md` changed on status lines only (lot 21 ✅ with its merge, lot 22 🔄).
- `docs/audits/` additions: `lot-22-friction.md`, `lot-22-review.md`, `lot-22.md` only.
- Every deliverable of the lot section has a fixture test or a skill-content
  assertion (`tests/lot-start-sync.test.sh`, `session-context.test.sh`,
  `plugin-currency.test.sh`, `skills.test.sh`); no test skipped.
- No change outside the lot's scope.

## Coverage exclusions
| Exclusion | Business code? | Proposed action |
|-----------|----------------|-----------------|
| (none: `Coverage tool` is `none`) | n/a | n/a |

## Migrations
n/a (`Migrations directory` is `n/a`).

## Lot-specific notes
- Validation criterion "no harness text asks for a hand re-copy of
  `CONVENTIONS.md`": verified by grep outside `docs/audits/` and `dev-plan.md`;
  the only remaining "Re-copies" is the body of the sync pull request itself
  (`.github/scripts/sync-projects.sh:56`), which describes what the workflow does.
- The lot changes `lot-audit` itself; this audit ran the installed 1.1.1 copy,
  except for step 0, read as this lot's version (see the friction file).

## Recommended next steps
1. `lot-ship`: push and open the PR to `develop`.
2. After merge and promotion, the two candidate lots of `lot-22-review.md`
   (sub-lot lock evidence, census-only exemption in step 0).
