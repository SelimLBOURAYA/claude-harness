# Lot Audit — Lot 5 — feat/lot-0-6-harness-foundation

**Harness ref:** `feat/lot-0-6-harness-foundation` (lot 4 at `4447941`)
**Scope:** the conventions master (`CONVENTIONS.md`, +151/-33) + 1 test suite (79 assertions)
**Verdict:** ✅ Ready for PR — the in-repository half is complete; four user-level
items are listed below and stay out of this commit

Findings **#4**, #5, #13, #15, #21; P5-#1, P5-#3, P5-#7, P5-#8, P5-#14;
P6-A2, A3, A5, A6, B8, D2, D3, D10, D13, D14.

## Summary

| Dimension | Critical | Warning | Info |
|---|---|---|---|
| Security | 0 | 1 | 1 |
| Harness | 0 | 2 | 2 |
| Architecture | 0 | 1 | 2 |

## What the lot delivers

`~/.claude/coding-conventions.md` stops being the master. This file is, and it
says so in its own first paragraph (P6-D2). Everything else in the lot follows
from that move or from a finding the old master contradicted.

| Change | Content |
|---|---|
| Header | `Master: claude-harness/CONVENTIONS.md`; the user-level file becomes a symlink into the clone; propagation flows one way, into the repositories' copies, inside their adoption lots |
| §2 | Step 1 reads history through `rtk proxy git log --first-parent` (P5-#14); step 9 gains **No lot chaining** as a paragraph of its own (#4) |
| §2.5 *(new)* | What an integration test is: a real engine with migrations active, backend and frontend (P5-#1, P5-#7) |
| §4 | The profile-switch exception now points at §14 for why the agent never invokes it on its own |
| §7 | Three additions: the plugin git guard and the CI as the two enforcement layers; **no branch protection** anywhere, so never merge a red PR (P6-D1); **expand/contract** for migrations (P5-#8). `develop` stated as the GitHub default branch (P5-#3) |
| §9 | Do **not** re-read `CONVENTIONS.md` under Claude Code; read the lots file's status table and current section only (P6-D10); `git log` through `rtk proxy` |
| §10 | Item 5 compares against the harness master; item 6 names both gate deliverables; item 1 states that memory is a complement, not the channel a rule lives in (#21) |
| §11 | Scope extended to `SKILL.md` files; the reference skeleton is `claude-harness/templates/project/` (P6-D13) |
| §12 | New `Gate parameters` subsection (the eleven rows, `n/a` never omitted); new `Where skills live` subsection; the mirror hook is the plugin's, not the retired user-level script; master propagation rewritten |
| §13 | The gate, written once as `lot-test → lot-review → lot-audit → lot-ship`, plus the four non-gate skills |
| §14 *(new)* | LLM profile routing: the switch does not move the running session, so the harness stops instead |

## The one thing §14 exists to say

The lot 5 test of `claude-profile` produced a fact worth more than the convention
it was meant to confirm: the switch **does not** move the running session.
`settings.json` read `claude-fable-5-1[1m]` while the session kept answering as
`deepseek-v4-pro[1m]`. A convention that said "switch to `claude` before the
audit" would have been followed to the letter and achieved nothing — the agent
would have run the review under the model that wrote the code, and reported that
it had not.

So §14 is a stop, not a step. And `lot-review` checks `ANTHROPIC_BASE_URL`
rather than asking the model what it is: a model asked to self-report its
identity is the least reliable witness in the room, and it is the witness the
naive version of this rule would have called.

## Security

| Severity | Location | Finding | Action |
|---|---|---|---|
| Warning | `~/.claude/settings.deepseek.json` (out of repo) | Carries `ANTHROPIC_AUTH_TOKEN` — a live DeepSeek API key — in clear. The file is local and unversioned, so nothing leaks today, but it is one `cp` into a repository away from doing so, and it contradicts §5 | **Reported to the user**, correction out of this lot's scope. Move it to an environment variable loaded at launch, or a secret manager |
| Info | `CONVENTIONS.md` §14 | The table names `ANTHROPIC_BASE_URL` and its DeepSeek value. That is an endpoint, not a credential, and the check `lot-review` performs is worthless if the variable it reads is not written down | None |

## Harness

| Severity | Location | Finding | Action |
|---|---|---|---|
| Warning | §9 item 1 | "Do not re-read `CONVENTIONS.md` under Claude Code" is correct only while the symlink exists. Under any agent that does not auto-load it, the same sentence tells the agent to skip the rules entirely — hence the trailing clause. It remains a rule whose correctness depends on the reader knowing which reader it is | Accepted, and stated in the sentence itself. The alternative — two files, one per audience — is the drift this lot removes |
| Warning | user level | The symlink, the `settings.json` plugin activation, the retirement of `sync-claude-agents.sh` and the memory corrections are **not** in this commit. Until they are done by hand, the master is authoritative in the repository and stale at `~/.claude` | Listed under "Out of repo" below; the settings half is additionally gated on the first `develop` → `main` promotion |
| Info | `tests/conventions.test.sh` | 79 assertions, and the shape matters more than the count: every section number a skill or a workflow cites is asserted to exist, and every skill §13 names is asserted to ship a `SKILL.md`. A renumbering or a skill rename breaks the suite instead of leaving a dangling citation | None |
| Info | §12 gate parameters | The eleven labels are asserted here **and** grepped by `harness-invariants.yml`. One assertion pins them together so the prose and the workflow cannot drift apart | None |

## Architecture

| Severity | Location | Finding | Action |
|---|---|---|---|
| Warning | numbering | The new section is `2.5`, between `2` and `3`. Inserting a whole-numbered section would have renumbered §3 to §14 and invalidated every citation in the skills, the workflows and the repositories' copies. `2.5` is the cheap escape, and it is a precedent: a second one makes the numbering a liability | Accepted for one. A third decimal section means the document needs anchors instead of numbers |
| Info | §13 | The gate is now written once, here, and referenced by the skills rather than restated. Previously it lived in three places and lot 2b had to edit all of them | None |
| Info | §2.5 / §7 | The two additions state a rule **and** the failure it prevents (a schema no environment runs; a migration that cannot roll forward). Longer than a rule alone, and the reason survives the compression that a bare imperative does not | None |

## Coverage exclusions

n/a — `Coverage tool` = none.

## Migrations

n/a — `Migrations directory` = n/a.

## Validation criteria

- [x] `./tests/run.sh` green — 7/7 suites, 513 assertions
- [x] No "Sprint chaining" in the master — `grep -n 'Sprint chaining'
      CONVENTIONS.md` returns nothing. The only surviving hits in the repository
      are `harness-sync`'s check **for** the phrase and this plan's record of the
      decision, both of which are supposed to name it
- [x] `cmp CLAUDE.md AGENTS.md` silent
- [ ] `readlink ~/.claude/coding-conventions.md` points into the harness clone —
      **out of repo**, see below (V7's plan B stays available: import the clone
      path directly from `~/.claude/CLAUDE.md`)
- [x] §4 documents the profile-switch exception and §14 the routing; the
      `ANTHROPIC_AUTH_TOKEN` leak is reported below. The two
      `settings.$PROFILE.json` files were checked in the earlier lot 5 session
      (`dev-plan.md`, "Routage revue/code par profil LLM") and **not** re-read
      here: this session's sandbox denies reads under `~/.claude`
- [x] The `lot-dev` → new session → `lot-review` stop is documented (§14) and was
      respected: no profile switch was attempted mid-session

## Out of repo, for the user

Four lot 5 items are user-level and are listed in the PR body rather than
performed here:

1. **The symlink**: `ln -sfn ~/ENV/projets/claude-harness/CONVENTIONS.md
   ~/.claude/coding-conventions.md`, after backing the current file up. Safe to
   do as soon as this lot merges.
2. **`~/.claude/settings.json`**: declare the marketplace with `"ref": "main"`,
   enable the plugin, and remove the `sync-claude-agents.sh` hook entry — the
   plugin's `mirror-sync` replaces it. **Gated on the first `develop` → `main`
   promotion**: until `main` carries the plugin, the declaration installs an
   empty marketplace, and removing the old hook before the new one loads leaves
   the mirror unguarded.
3. **`Bash(git *)` in the allow lists**, user and project: re-examined per V3.
4. **Memories**: kf `feedback_pr_workflow.md` ("PR to `develop`", #15); the root
   `project-portfolio-state.md` stale facts (#13, P6-D14); and a
   `Verified: YYYY-MM-DD` line on every `project_*` memory, which `harness-sync`
   now reports on past 60 days.

## Recommended next steps

1. Merge, promote `develop` → `main`, **then** do items 1 and 2 above in that
   order — the promotion is the prerequisite of the settings change, not the
   other way round.
2. Lot 6 next: the root cleanup, and the portfolio audits moving into
   `docs/audits/portfolio/` where this repository's census already expects them.
