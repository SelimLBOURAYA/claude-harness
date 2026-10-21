# Lot Audit — Lot 26 — feat/lot-26-project-memory

**Harness ref:** 2.0.1
**Scope:** 18 modified files | **Fix commit:** none needed | **Verdict:** Ready for PR

## Summary
| Dimension    | Critical | Warning | Info |
|--------------|----------|---------|------|
| Security     | 0        | 0       | 1    |
| Performance  | 0        | 0       | 1    |
| Architecture | 0        | 0       | 3    |

## Security

The `security-review` discovery and false-positive phases ran inline, without
sub-agents: the diff fits in the session's context. The lot changes Markdown
(skills, conventions, memory, plan), JSON (version bumps, regenerated card) and
test-only shell assertions; no hook, workflow or runtime script.

| Severity | Location | Finding | Action |
|----------|----------|---------|--------|
| Info | `plugins/claude-harness/skills/lot-start/SKILL.md:193` | B3 writes the memory template with a `Bash` redirection, which the write guard does not see. The lock is already open at B3 (the user confirmed the lot), `$LOT_REPO` is quoted and comes from `git rev-parse --show-toplevel`, and the source is a fixed path of the harness `origin/main`: no lock bypass, no untrusted input. | none needed |

`docs/memory.md` is committed agent-read text with the same trust as the
`CLAUDE.md` agents already read; its header makes it non-normative (MEM-1). No
secret, credential or new absolute path is added.

## Performance
| Severity | Location | Finding | Action |
|----------|----------|---------|--------|
| Info | `plugins/claude-harness/skills/lot-review/SKILL.md:105` | The `lot-test` boundary command now prints the full patch of every `test(N)` commit (`-p`, review finding #2), so its output grows with the tests `lot-test` adds. Needed to see a weakened assertion; one `test(N)` commit per `lot-test` run keeps it small. | none needed |

The memory is read at most three times per lot (`lot-start` A2, `lot-test`,
`lot-review`), within 6000 characters (≈ 1 500 tokens) each, and never injected
at `SessionStart`, as the lot's specification decided.

## Architecture
| Severity | Location | Finding | Action |
|----------|----------|---------|--------|
| Info | `dev-plan.md` | The lots file changes beyond status lines, through three `docs:` planning commits on the branch (fa46181 status sync, 51fecb4 lot 27 plan, 1deea06 lot 26 amendment). No `feat`, `fix` or `test` commit of the lot touches it. | none needed: planning commits of the user's sessions, not lot code |
| Info | `CONVENTIONS.md` | The master changes (MEM-1 added, GATE-7 and LOT-7 rewritten). This repository holds the master, so the change is a harness pull request as DOC-7 requires; `sync-projects` carries it to the 8 copies after the `develop` → `main` promotion. 14832 of 15000 bytes; deepseek card 4486 of 4500 characters, in line with the master (`--check` silent). | none needed |
| Info | `plugins/claude-harness/skills/lot-start/SKILL.md:193` | B3 fetches the memory template from the harness `origin/main`: in the 8 repos the step works only once the lot is promoted, which is also when the skill itself reaches them (the installed plugin follows `main`). | none needed |

Checklist results: `CLAUDE.md`/`AGENTS.md` and the skeleton pair
byte-identical; both new documents (`docs/memory.md`,
`templates/project/docs/memory.md`) and `docs/audits/lot-26-review.md` entered
the census in their own commits; `## Gate parameters` unchanged and accurate;
commit titles Conventional Commits, English, no U+2014; no commented-out code;
no skipped or disabled test; the only `docs/audits/` file added is the lot's
review report; the `test(26)` commit touches `tests/skills.test.sh` only.

## Coverage exclusions
| Exclusion | Business code? | Proposed action |
|-----------|----------------|-----------------|
| (none) | n/a | none: `Coverage tool` is `none` |

## Migrations
n/a (`Migrations directory` is `n/a`).

## Lot-specific notes

- Deliverables 1 to 8 of the specification are present; the review applied 10
  of its 11 findings and the owner rejected the eleventh
  (`docs/audits/lot-26-review.md`).
- The session ran the installed plugin 2.0.1, not the branch's 2.1.0: this
  lot's own `lot-review` changes (memory check, `lot-test` boundary) were
  applied by hand from the branch's skill, not by the installed copy.
- The deferred control (5th lot shipped after this one) stays open in the lots
  file.

## Recommended next steps
1. `lot-ship` in this or a new session, under any profile.
2. After the merge, the user promotes `develop` → `main`; the 8 repos then get
   the skills by plugin update and `CONVENTIONS.md` by the sync pull request.
