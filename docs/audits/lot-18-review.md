# Lot Review — Lot 18 — feat/lot-18-reaudit-fixes

**Harness ref:** 6a87935
**Model:** Claude Opus 5 (`claude` profile, `ANTHROPIC_BASE_URL` empty)
**Target:** local diff `develop...HEAD` — no PR open at review time
**Reviewed at:** 9f1f871
**Fix commit:** 6a87935
**Verdict:** Fixed

## Findings

| # | Severity | Location | Finding | Outcome |
|---|----------|----------|---------|---------|
| 1 | Medium | `.github/workflows/lint.yml:124` | The dedup test compared a space-joined string with an unquoted `case` pattern. With `./a b.sh` already found, the entry point `./a` matched `*" ./a "*` and was silently dropped from the lint — the "check that checks nothing" this step exists to prevent. Glob metacharacters in a filename behaved the same way. | fixed in 6a87935 (`declare -A seen` index) |
| 2 | Medium | `.github/workflows/lint.yml:116,126` | `find . -path ./.git -prune` pruned nothing else. On the `other` stack a checked-in or generated `node_modules` / `vendor` / `dist` tree would be handed to `shellcheck --severity=warning`, reddening the job on third-party code the repository does not own. | fixed in 6a87935 (shared prune list on all three finds) |
| 3 | Medium | `.github/workflows/lint.yml:155` | `python3 -m pip install pyyaml` had no failure path, contradicting the workflow's stated contract that every check degrades to an explicit skip. On a runner without pip or an externally-managed interpreter (PEP 668 — reproducible on this machine) a missing linter reads as a YAML error. | fixed in 6a87935 (explicit skip, exit 0; the `skipped:` count assertion moves 7 → 8) |
| 4 | Medium | `plugins/claude-harness/skills/lot-review/SKILL.md:86` | Step 0b declared that every `git` and `gh` command carries `-C "$REVIEW_REPO"`, and the next command was an unscoped `gh pr view`. `gh` resolves the repository from the current directory and ignores a sibling `git -C`, so the one command the invariant was written for was the one that ignored it. | fixed in 6a87935 (`(cd "$REVIEW_REPO" && gh pr view …)`) |
| 5 | Medium | `lot-audit/SKILL.md:42`, `lot-review/SKILL.md:58` | `AUDIT_REPO=$(git rev-parse --show-toplevel)` derives from the session's own cwd, so the stop condition was a tautology with no mechanical trigger. An agent in the harness clone gets `AUDIT_REPO=<harness>`, every `-C` scoping succeeds, and the audit confidently describes the wrong repository — the lot 7–13 defect, unchanged. | fixed in 6a87935 (second independent signal: lot branch pattern, plus that lot's section in this repository's `Lots file`) |
| 6 | Medium | `lot-audit/SKILL.md` | Found while reviewing the fix for #5: the documented matcher `grep -q "lot $N\b\|Lot $N\b"` does not match `## LOT 18`, the form `dev-plan.md` uses. The guard would have stopped on the **correct** repository. | fixed in 6a87935 (case-insensitive `grep -qiE`, asserted against this repo's own heading) |

## Rejected and deferred

| Item | Decision |
|---|---|
| The "no shell script" check ordering before the "not installed" check | Rejected: intended behaviour, a repository with nothing to lint is a skip whatever the runner has installed |
| `\b(bash\|sh\|dash\|ksh)\b` matching a shebang path that merely contains `sh` | Rejected: contrived, and a false positive only sends one extra file to shellcheck |
| The `other` stack getting no eslint (`summerize-youtube`) | Rejected: explicitly arbitrated, and written in the step's own comment |
| `shellcheck --severity=warning` never run on this repository's 10 scripts | **Deferred to the PR run** — see below. `shellcheck` is not in the dependency budget and is absent locally, so `tests/workflows.test.sh` skips its three real-binary assertions. Discovery and exit behaviour were verified through a stub instead, and `bash -n` passes on all 10 files. The PR run is the first real shellcheck; a finding there is fixed before merge, never merged red (§7) |

## Inline comments posted

No PR open at review time — findings recorded here only.

## Candidate lots

None. Two follow-ups belong to other repositories and are already written in
`dev-plan.md`: `deployment` and `summerize-youtube` must uncomment their own
`lint` job for this branch to run there.
