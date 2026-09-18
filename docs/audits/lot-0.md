# Lot Audit — Lot 0 — feat/lot-0-6-harness-foundation

**Harness ref:** `feat/lot-0-6-harness-foundation` (branched from `develop` at `a1f7adf`)
**Scope:** repo bootstrap, plugin manifests, documentation set, test runner
**Verdict:** ⚠️ Fix warnings — V1 to V7 documented, **not executed** (user decision, 2026-09-18)

## Summary

| Dimension | Critical | Warning | Info |
|---|---|---|---|
| Security | 0 | 0 | 1 |
| Harness | 0 | 7 | 1 |
| Architecture | 0 | 0 | 2 |

## Technical verifications V1 to V7

The user decided on 2026-09-18 to **document** these verifications rather than execute
them: each one needs a live throwaway private GitHub repo, an IDE session or a
model-routing test, none of which can be settled from inside this session. The code of
lots 1 to 6 is therefore written against **plan A** of each row. Every plan B stays
documented here and in `dev-plan.md` so a failed verification is a localized change,
not a rewrite.

| # | Question | Status | Plan applied | What to run to close it |
|---|---|---|---|---|
| V1 | Marketplace/plugin syntax, user **and** project activation, `ref: main` followed | ⚠️ Not executed | **A** — manifests written to the documented schema (`.claude-plugin/marketplace.json` with a `plugins[]` entry whose `source` is a repo-relative path; `plugins/claude-harness/.claude-plugin/plugin.json`). `tests/manifests.test.sh` checks the schema and that the declared source resolves | On a throwaway **private** repo whose default branch is `develop`: (a) add the marketplace with `@main` while `main` lacks `.claude-plugin/marketplace.json` → expect an explicit failure; (b) create `main`, `/plugin marketplace update`, verify only `main` commits arrive; (c) confirm the git credential helper serves the private clone in background auto-update, IntelliJ and Cursor |
| V2 | Skill names (`claude-harness:lot-test`) and discovery in project **and** root sessions | ⚠️ Not executed | **A** — the Skills tables of `CLAUDE.md`, `README.md` and `templates/project/CLAUDE.md` announce `claude-harness:<name>` | Open a session on a repo with the plugin enabled, list the skills, and record the exact announced name. If it differs, the three Skills tables are the only files to edit |
| V3 | A plugin `PreToolUse` hook can return **deny** and **ask** even with `Bash(git *)` allowed | ⚠️ Not executed | **A** — `git-guard.py` emits `permissionDecision` `deny`/`ask` on `hookSpecificOutput`, which the documented contract states takes precedence over the allow list | Enable the plugin, keep `Bash(git *)` in allow, run `git push --force` → expect a deny. If the allow list wins, plan B: drop `Bash(git *)`, `git push *`, `gh pr *` from the allow lists (user and projects) and keep the hook for denials only |
| V4 | Reusable workflows of a **private** repo callable from other private repos on a **free personal** account | ⚠️ Not executed | **A** — workflows written as `workflow_call`, called via `SelimLBOURAYA/claude-harness/.github/workflows/<f>.yml@main` | Set **Settings → Actions → General → Access → "Accessible from repositories owned by the user"** on this repo, then call one workflow from a throwaway private repo. If refused, plan B: the caller template inlines the workflow bodies and `harness-sync` checks the drift by `cmp` |
| V5 | Preventing rtk from rewriting `git log` and memory-file reads | ⚠️ Not executed | **A** — documented, **not implemented in this PR**: the rtk hook lives in `~/.claude/settings.json`, outside this repo. The skills work around it by calling `rtk proxy git log` explicitly (P5-#14), which is correct whatever V5 concludes | Read `rtk config` / the rtk docs for an exclusion list. If none exists, plan B: a wrapper hook that only calls `rtk hook claude` outside the excluded patterns. Belongs to the user-level half of lot 5 |
| V6 | IDE sessions (IntelliJ, Cursor) and DeepClaude: plugin loaded, `rtk` and `python3` on `PATH`, model routing | ⚠️ Not executed | **A** — `git-guard.py` is invoked as `python3 "$CLAUDE_PLUGIN_ROOT/hooks/git-guard.py"` and uses only the standard library, so it does not depend on a project virtualenv. `README.md` documents `gh auth setup-git` as a prerequisite | From each IDE: run a diagnostic hook printing `$PATH`, confirm the plugin is loaded, then attempt `gh pr create` from a `feat/lot-N-*` branch without an audit report — **only the CI** is expected to stop a non-Claude agent |
| V7 | `@coding-conventions.md` in `~/.claude/CLAUDE.md` follows a **symlink** to `claude-harness/CONVENTIONS.md` | ⚠️ Not executed | **A** — `CONVENTIONS.md` is versioned here and lot 5 makes it the master. The symlink itself is a user-level action, listed in the PR body as post-merge work | Point the symlink at a copy of `~/.claude`, open a session, confirm the conventions text is present in context. If the import does not follow symlinks, plan B: import the clone path directly (`@/home/selim/ENV/projets/claude-harness/CONVENTIONS.md`) |

**Consequence for the gate**: none of these warnings blocks the PR, because every one
of them has a written plan B whose cost is bounded to a manifest, a settings block or
a Skills table. They must be closed before lot 7 (first adoption), since a failed V1 or
V4 changes how the 8 repos consume the harness.

## Security

| Severity | Location | Finding | Action |
|---|---|---|---|
| Info | `README.md` | The documented fallback for a failing V1(c) is a `url.<...>.insteadOf` git config carrying a PAT. Documented as a **last resort**, token kept outside the repo | Keep it out of any committed file; prefer `gh auth setup-git` |

No secret, credential or absolute user path is committed by this lot. `.gitignore`
already carries `.env` and `*.local.md` (§5, §8).

## Architecture

| Severity | Location | Finding | Action |
|---|---|---|---|
| Info | `tests/run.sh` | The runner discovers `tests/*.test.sh` rather than listing suites, so a new suite is picked up without editing the runner | None |
| Info | `tests/lib.sh` | Assertions are a local 60-line helper instead of a framework (bats), to honour the "no new dependency" rule of the lightened gate | Revisit only with §4 approval |

## Validation criteria

- [x] V1 to V7 arbitrated, result and retained plan recorded in this report
- [x] `cmp CLAUDE.md AGENTS.md` silent (checked by `tests/manifests.test.sh`)
- [x] `CONVENTIONS.md` identical to the master (lot 5 makes this file the master)
- [ ] Empty plugin installable locally — **needs V1**, deferred to the user
- [x] `README.md` documents the install command **with** the ref, the
      `extraKnownMarketplaces` block with `"ref": "main"`, and the `gh auth login`
      prerequisite

## Recommended next steps

1. Run V1, V2, V3 in one throwaway private session — they share the same setup.
2. Run V4 before starting lot 7: a negative answer changes the adoption checklist.
3. After the merge of this PR, promote `develop` → `main` so consuming repos can
   declare the marketplace with `ref: main` against a branch that actually holds the
   plugin.
