# Lot Audit — Lot 2 — feat/lot-0-6-harness-foundation

**Harness ref:** `feat/lot-0-6-harness-foundation` (lot 1 at `64081d4`)
**Scope:** 7 skills + 1 checklist file + 1 test suite (80 assertions)
**Verdict:** ✅ Ready for PR

Findings **#1** (skills in `skill/`, never discovered), #6 (non-existent
`security-review` subagent), #16 (threshold contradiction in `sprint`), #17
(skills written in French), #3 and #7 in part; P5-#11, P5-#14, P5-#16;
P6-D10, P6-D14.

## Summary

| Dimension | Critical | Warning | Info |
|---|---|---|---|
| Security | 0 | 0 | 1 |
| Harness | 0 | 2 | 2 |
| Architecture | 0 | 0 | 1 |

## Deliverables

| Skill | Origin | Corrections applied |
|---|---|---|
| `lot-test` | kb + kf, merged | One skill for both stacks. Command, threshold, coverage tool and exclusions read from `Gate parameters`. Unified business-rule matrix. Integration tests require a **real database** with migrations active (§2.5, P5-#1, P5-#7) |
| `lot-audit` + `checklists.md` | kb | Step 0 requires `lot-review` first. Step 2 calls `Skill(security-review)` instead of the non-existent subagent (#6). Checklist link resolves. Coverage exclusions reviewed (#7). Migrations status `A` + expand/contract (#9, P5-#8). Report header carries the harness ref |
| `lot-ship` | kb + kf, merged | Stop after PR, no chaining. `--base develop` mandatory. Requires `lot-N.md` without unresolved Critical, and `lot-0-integration.md` on a frontend (#3). `gh pr checks --watch`, no green light on a red check (P5-#11). History through `rtk proxy git log` (P5-#14) |
| `harness-sync` | kb | 14 numbered invariants instead of prose. Marketplace ref `main` required. Gate order and `lot-N-review.md` presence checked. Lots file status table (P6-D10). Memory freshness at 60 days (P6-D14). No dates in the lots file (P6-D5) |
| `dep-update` | kb + kf, merged | Toolchain selected by `Stack`. Actions SHAs and base images added as a third toolchain. Adding a dependency explicitly out of scope (§4) |
| `integration-check` | new | Manual front ↔ real backend procedure and the `lot-0-integration.md` template (#3, P5-#4) |
| `i-have-adhd` | identical everywhere | Copied verbatim; `disable-model-invocation: true` preserved |

`sprint` is **not** shipped (decision "stop after PR"), which closes #16 with it.

## Harness

| Severity | Location | Finding | Action |
|---|---|---|---|
| Warning | all skills | Skill **discovery and naming** (`claude-harness:lot-test`) rests on V2, which was not executed. If the announced name differs, three Skills tables need editing — `CLAUDE.md`, `README.md` and the lot 4 template | Close V2 before lot 7 |
| Warning | `lot-audit` | `Skill(security-review)` assumes a `security-review` skill is reachable in the session. It is available in this harness, but the skill documents a fallback to the manual checklist **and records the fallback in the report**, so a missing skill degrades loudly instead of silently — which is exactly how #6 went unnoticed | None |
| Info | `lot-test` | The two stack variants live in one file with `Stack`-marked sections rather than two skills. A frontend session still reads the backend paragraphs, at a small context cost, but the shared rules stay written once | None |
| Info | `dep-update`, `i-have-adhd` | Both are excluded from the "no hard-coded command" check, for stated reasons: `dep-update`'s job **is** to drive a package manager, and `i-have-adhd` uses `npm test` only as an illustration of output formatting. The exclusion is in the test file, not implicit | None |

## Security

| Severity | Location | Finding | Action |
|---|---|---|---|
| Info | all skills | No secret, credential or absolute user path in any skill. The only absolute path is `~/ENV/projets/claude-harness`, the documented clone location for non-Claude agents, and a test asserts nothing else appears | None |

## Architecture

| Severity | Location | Finding | Action |
|---|---|---|---|
| Info | `tests/skills.test.sh` | The suite asserts the **content** of the corrections, not just file presence: each row of the lot 2 table has at least one assertion pinning it. A future edit that drops `rtk proxy git log` or `--base develop` turns the suite red | None |

## Coverage exclusions

n/a — this repository has no coverage instrumentation (`Coverage tool` = none).

## Migrations

n/a — `Migrations directory` = n/a.

## Validation criteria

- [x] No `skill/` path, no hard-coded command and no hard-coded threshold in the
      gate skills (asserted, 80 assertions green)
- [ ] Skills discovered in a session on a test repo — **needs V2**, deferred
- [x] Report `docs/audits/lot-2.md`

## Recommended next steps

1. Close V2, then confirm the three Skills tables carry the real announced name.
2. `lot-review` (lot 2b) completes the gate this lot documents.
