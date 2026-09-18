# Lot Audit — Lot 6 — feat/lot-0-6-harness-foundation

**Harness ref:** `feat/lot-0-6-harness-foundation` (lot 5 at `69c2e34`)
**Scope:** 4 portfolio audit reports moved into `docs/audits/portfolio/` (~129 KB)
**Verdict:** ✅ Ready for PR for its in-repository half. The rest of the lot is
deletions outside this repository and one change in `deployment`; both wait for
the user.

Findings **#11**, #23; P6-A3, A4, D2, D4.

## Summary

| Dimension | Critical | Warning | Info |
|---|---|---|---|
| Security | 0 | 0 | 1 |
| Harness | 0 | 1 | 2 |
| Architecture | 0 | 0 | 1 |

## What the lot delivers here

P6-D4 reverses the original decision: the cross-cutting audits live with the
harness they audit, not at the root of `~/ENV/projets` and not in `deployment`.

| File | Content |
|---|---|
| `docs/audits/portfolio/p4-meta-harness-2026-09-17.md` | P4 v1, the first harness audit |
| `docs/audits/portfolio/p4-meta-harness-2026-09-17-v2.md` | P4 v2, the 25 findings this plan is built on |
| `docs/audits/portfolio/p5-harness-cicd-2026-09-17.md` | P5, the 23 CI/CD and GitHub findings |
| `docs/audits/portfolio/p6-meta-portfolio-2026-09-17.md` | P6, the portfolio audit and decisions D1 to D14 |

Copied, then `cmp`-verified against their sources — all four identical. The
sources are **not** deleted by this commit: a deletion outside the repository is
the user's (§4), and it costs nothing to leave it until the branch has merged.

`CLAUDE.md`'s census already carries the `docs/audits/portfolio/` row, added when
the census was written; the directory now exists to match it. That is the right
way round only by luck, and lot 15 should read the census against reality once
rather than trusting the two stayed in step.

## The one judgement call

**The four files are in French, and stay in French.** §11 puts instruction
documents in English, and these are not instruction documents: they are dated
findings, already written, read by the user, cited by `dev-plan.md` which is
itself French. Translating 129 KB of archive would change no behaviour, cost a
long session, and risk rewording a finding the plan quotes by number.

Reports produced *from now on* by `lot-audit` are English, as lot 0 to 6 here
already are. The distinction is the audience: `docs/audits/lot-N.md` is read by
the next agent, `docs/audits/portfolio/*` is read by the user.

## Security

| Severity | Location | Finding | Action |
|---|---|---|---|
| Info | `docs/audits/portfolio/*` | The four reports describe the portfolio's security posture — missing branch protection, the `GITHUB_TOKEN` permissions, the repositories that were public. That is exactly the content P6-D1 made private repositories mandatory for. This repository is private; the same files must never land in a public one | None. Checked: they contain no credential, only postures and paths |

## Harness

| Severity | Location | Finding | Action |
|---|---|---|---|
| Warning | `deployment/docs/audits/` | Still holds copies of P4 v1 and P5 alongside P3. Until they are removed, P6-D4 is half-applied and there are two copies of each audit, the kind of duplication this lot exists to end. The change belongs to `deployment`, on its own branch and its own PR | Listed below for the user; `deployment`'s census needs the same edit |
| Info | `docs/audits/portfolio/` | No index file. The census row names the directory, and an index would be a fifth thing to keep in step with four files that will never change again | None |
| Info | copy vs move | `cp` then a deferred delete, rather than `git mv` across repositories (which is not a thing). The `cmp` is what makes the delete safe, and it passed for all four | None |

## Architecture

| Severity | Location | Finding | Action |
|---|---|---|---|
| Info | ownership | After this lot, the split P6-D2 defines holds: `claude-harness` owns conventions, skills, hooks, skeleton, workflows and the cross-cutting audits; `deployment` owns statuses, the runbook, the stacks and the host. The root `~/ENV/projets` owns nothing, which is the point of #11 | None |

## Coverage exclusions

n/a — `Coverage tool` = none.

## Migrations

n/a — `Migrations directory` = n/a.

## Validation criteria

- [x] `./tests/run.sh` green — 7/7 suites, 513 assertions
- [x] The four portfolio audits are versioned here and byte-identical to their
      sources
- [ ] `ls ~/ENV/projets/audit` empty or absent — **deferred**, see below
- [ ] The claude.ai export regenerated and `EXPORT-INFO.txt` coherent —
      **deferred**, it depends on the `ROADMAP.md` deletion
- [ ] `systemctl --user list-timers` shows the backup timer — **deferred**, a
      user-level unit

## Out of repo, for the user

Everything else in lot 6 happens outside this repository. None of it is done
here, and the three deletions are `rm`s on files this branch has not yet merged:

1. **`~/ENV/projets/audit/`** — delete after this branch merges. The `cmp` above
   is the evidence the copies are complete.
2. **`~/ENV/projets/ROADMAP.md`** — delete; `deployment/ROADMAP.md` is the only
   master (#11). Then `~/ENV/claude-backup/export-claude-project.sh` must read
   the repository's copy directly, and the export be regenerated.
3. **`~/ENV/projets/claude-project-instructions.md`** — add the header "Not for
   coding agents – claude.ai project instructions" and the pointer to
   `deployment/ROADMAP.md`.
4. **`~/ENV/projets/prompt-harness.md`** — the lot 4 deletion, still pending,
   superseded by `bootstrap-project`.
5. **`deployment`**, own branch and own PR: remove P4 v1 and P5 from
   `docs/audits/`, keep P3, point the census at
   `claude-harness/docs/audits/portfolio/`, and fix the census rows P6 flagged
   (P4 v2, "8 repos").
6. **Weekly systemd user timer** on `~/ENV/claude-backup/backup-md.sh` (P6-D2),
   covering the memories and the user-level settings.

## Recommended next steps

1. Open the PR for lots 0 to 6, merge, and promote `develop` → `main`. That
   promotion is what makes the plugin installable and unblocks lots 5's settings
   items and lot 7.
2. Do the deletions above after the merge, in the order listed.
3. Lot 6b is manual, short, and independent — it can be done at any time.
