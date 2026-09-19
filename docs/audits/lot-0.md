# Lot Audit — Lot 0 — feat/lot-0-6-harness-foundation

**Harness ref:** `feat/lot-0-6-harness-foundation` (branched from `develop` at `a1f7adf`)
**Scope:** repo bootstrap, plugin manifests, documentation set, test runner
**Verdict:** ⚠️ Fix warnings — V1 to V4 executed and confirmed 2026-09-19 (see below);
V5 to V7 still documented, **not executed** (user decision, 2026-09-18)

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
| V1 | Marketplace/plugin syntax, user **and** project activation, `ref: main` followed | ✅ Executed 2026-09-19 | **A confirmed** — `claude-harness` is itself a **private** repo (`gh repo view` → `isPrivate: true`, default branch `develop`), so it already is the "throwaway private repo" case for (a)/(b): `~/.claude/plugins/known_marketplaces.json` resolves `ref: main`, `installed_plugins.json` / `claude plugin list` show the plugin `✔ enabled` at user scope, and the installed marketplace checkout's HEAD (`d67c004`) matches `origin/main` HEAD exactly — no `develop`-only commit leaked through. (a)'s failure case (adding `@main` while `main` lacked the manifest) is now moot: `main` has carried `.claude-plugin/marketplace.json` since the lot 0-6 promotion, so it can no longer be provoked. (c) partially confirmed: the same private-repo clone succeeding proves the credential helper serves background auto-update; the IntelliJ/Cursor sub-checks still need those IDEs open, which a terminal session cannot do | IntelliJ/Cursor still open plugin-loaded sessions manually to confirm `rtk`/`python3` on `PATH` there too (overlaps V6) |
| V2 | Skill names (`claude-harness:lot-test`) and discovery in project **and** root sessions | ✅ Executed 2026-09-19 | **A confirmed** — `claude plugin details claude-harness` lists all 9 skills with the exact names in `CLAUDE.md`'s table, `claude plugin validate` passes, and a real interactive session's system-reminder (captured via `claude -p --verbose "output the exact literal text of the skills system-reminder..."`) shows `claude-harness:bootstrap-project`, `:dep-update`, `:harness-sync`, `:integration-check`, `:lot-audit`, `:lot-review`, `:lot-ship`, `:lot-test` verbatim. Note: a *plain* `claude -p` answer paraphrases and silently drops them — only `--verbose` (or an actual TUI session) surfaces the real list; don't mistake the paraphrase for absence | None — matches documented plan A exactly |
| V3 | A plugin `PreToolUse` hook can return **deny** and **ask** even with `Bash(git *)` allowed | ✅ Executed 2026-09-19 | **A confirmed** — with `Bash(git *)` present in `~/.claude/settings.json`'s allow list, asking a session (in a disposable local repo with a local bare "fake remote", no GitHub involved) to run `git -c core.hooksPath=/tmp status` — a command with no dedicated CONVENTIONS.md rule, so the model attempted it rather than self-refusing on prose grounds — got the literal reply *"The hook blocked it: overriding `core.hooksPath`..."`. The hook's `deny` overrode the allow list exactly as documented. (Direct `git push --force` attempts couldn't isolate the hook cleanly: the model's own instruction-following refused the command in every framing tried, including a `--system-prompt` override, before ever reaching the Bash tool call — a stronger-than-expected result, not a failure of the test) | None — matches documented plan A exactly |
| V4 | Reusable workflows of a **private** repo callable from other private repos on a **free personal** account | ✅ Executed 2026-09-19 | **A confirmed** — a throwaway private repo `SelimLBOURAYA/claude-harness-v4-probe` called `branch-naming.yml@main` from this private `claude-harness` repo via `workflow_call`; run `35438748457` completed with `conclusion: success`. `access_level=user` (lot 6b) was the prerequisite, already verified; this closes the remaining runtime call | None — matches documented plan A exactly. The probe repo (private, secret-free) is left at `SelimLBOURAYA/claude-harness-v4-probe`; delete manually or grant `delete_repo` scope to `gh` |
| V5 | Preventing rtk from rewriting `git log` and memory-file reads | ⚠️ Not executed | **A** — documented, **not implemented in this PR**: the rtk hook lives in `~/.claude/settings.json`, outside this repo. The skills work around it by calling `rtk proxy git log` explicitly (P5-#14), which is correct whatever V5 concludes | Read `rtk config` / the rtk docs for an exclusion list. If none exists, plan B: a wrapper hook that only calls `rtk hook claude` outside the excluded patterns. Belongs to the user-level half of lot 5 |
| V6 | IDE sessions (IntelliJ, Cursor) and DeepClaude: plugin loaded, `rtk` and `python3` on `PATH`, model routing | ⚠️ Not executed | **A** — `git-guard.py` is invoked as `python3 "$CLAUDE_PLUGIN_ROOT/hooks/git-guard.py"` and uses only the standard library, so it does not depend on a project virtualenv. `README.md` documents `gh auth setup-git` as a prerequisite | From each IDE: run a diagnostic hook printing `$PATH`, confirm the plugin is loaded, then attempt `gh pr create` from a `feat/lot-N-*` branch without an audit report — **only the CI** is expected to stop a non-Claude agent |
| V7 | `@coding-conventions.md` in `~/.claude/CLAUDE.md` follows a **symlink** to `claude-harness/CONVENTIONS.md` | ⚠️ Not executed | **A** — `CONVENTIONS.md` is versioned here and lot 5 makes it the master. The symlink itself is a user-level action, listed in the PR body as post-merge work | Point the symlink at a copy of `~/.claude`, open a session, confirm the conventions text is present in context. If the import does not follow symlinks, plan B: import the clone path directly (`@/home/selim/ENV/projets/claude-harness/CONVENTIONS.md`) |

**Consequence for the gate**: none of these warnings blocks the PR, because every one
of them has a written plan B whose cost is bounded to a manifest, a settings block or
a Skills table. V1 to V4 are now closed (plan A confirmed). V5 to V7 stay open but do not
gate lot 7 — only V4 changed how the 8 repos consume the harness, and it is now resolved.

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
- [x] Empty plugin installable locally — confirmed by V1 (`claude plugin list` → enabled)
- [x] `README.md` documents the install command **with** the ref, the
      `extraKnownMarketplaces` block with `"ref": "main"`, and the `gh auth login`
      prerequisite

## Recommended next steps

1. ~~Run V1, V2, V3 in one throwaway private session — they share the same setup.~~
   Done 2026-09-19 — see the V1–V3 rows above.
2. ~~Run V4 before starting lot 7: a negative answer changes the adoption checklist.~~
   Done 2026-09-19 — see the V4 row above. Lot 7 can start.
3. ~~After the merge of this PR, promote `develop` → `main`~~ Done (lot 6b).
