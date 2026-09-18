# Lot Audit — Lot 3 — feat/lot-0-6-harness-foundation

**Harness ref:** `feat/lot-0-6-harness-foundation` (lot 2b at `37edab3`)
**Scope:** 9 reusable workflows + 1 self-CI workflow + 2 templates + 1 test suite (159 assertions)
**Verdict:** ⚠️ Fix warnings — the workflows are complete and asserted statically,
but none has yet run on a real GitHub runner

Findings **#9**, #8, #18, #19, #25, #3; P5-#6, P5-#8, P5-#9, P5-#13, P5-#15,
P5-#18, P5-#21, P5-#22; P6-D2, P6-D5, P6-D9, P6-D10, P6-D12.

## Summary

| Dimension | Critical | Warning | Info |
|---|---|---|---|
| Security | 0 | 1 | 2 |
| Harness | 0 | 2 | 2 |
| Architecture | 0 | 1 | 1 |

## What the lot delivers

| Workflow | What it refuses | Origin |
|---|---|---|
| `harness-invariants.yml` | `CLAUDE.md` ≠ `AGENTS.md`; `CONVENTIONS.md` ≠ the harness master at `main`; marketplace declared without `"ref": "main"` or not enabled; a `skill/` directory; a missing `Gate parameters` row; a skill or report outside the census; a lots file whose first table is not `\| Lot \| Branche \| Statut \|` with a known status on every row; a calendar commitment in it | #1, #8, P6-D2, P6-D5, P6-D10 |
| `commit-format.yml` | A subject that is not Conventional Commits, longer than 100 characters, capitalised, ending in a period, carrying U+2014, or written in French | §7, §10 |
| `branch-naming.yml` | A branch outside `feat/lot-N[-M]-slug` and `chore\|docs\|fix\|refactor\|test/slug`; a PR to `main` from anything but `develop` or `fix/*` | §7 |
| `migrations-immutable.yml` | Any status but `A` under the migrations directory; a destructive change with no `contract` marker; a marked contract migration with no `schema-contract` label on the PR | #9, P5-#8 |
| `lot-deliverables.yml` | A lot branch with no `docs/audits/lot-N.md`, or no `lot-N-review.md` before it; an unresolved `Critical` row; a report for a lot the branch does not declare; a frontend PR with no `lot-0-integration.md` carrying both SHAs | #3, #13, P5-#13, §13 |
| `image-smoke.yml` | An image that does not answer 200 on its health path, started from the exact bytes the merge would publish | P5-#6, P5-#18 |
| `frontend-dist.yml` | A bundle matching the repo's forbidden pattern, or with no `index.html` | P5-#15 |
| `image-publish.yml` | Publishing from anywhere but `main` and `develop`; pushing anything on a pull request | P6-D9, P6-D12 |
| `lint.yml` | A formatting violation where the tool is configured; reports dependency advisories without gating on them | P5-#21, P6-D12 |
| `ci.yml` (this repo only) | A red `./tests/run.sh`, a diverged mirror, a dependency outside `bash python3 jq git` | §4 |

Plus `templates/ci-caller.yml` (#19, P5-#22) and `templates/dependabot.yml` (P5-#9).

## The one decision worth stating

**The image is built once.** The plan asked for a build on PR without push and a
publish on `main`/`develop`; the obvious reading gives two builds of the same
Dockerfile, and a smoke test that validates a *different* image from the one that
ships. Instead, `image-publish.yml` builds, then either pushes (on a branch that
publishes) or `docker save`s the image into an artifact that `image-smoke.yml`
loads. What boots in CI is byte-identical to what a merge would publish, which is
what P5-#18 actually asks for.

The tested **artefact** follows the same path one level down: the validation job
uploads the jar the test suite ran on, and the build downloads it into the build
context rather than recompiling.

## Security

| Severity | Location | Finding | Action |
|---|---|---|---|
| Warning | `image-publish.yml` | The trivy scan is **non-blocking** (`exit-code: "0"`). A CRITICAL CVE in a published base image is reported in the run log and nowhere else, and nothing stops the tag from being deployed | Accepted per P6-D12, for now. Flip to `exit-code: "1"` on CRITICAL at the first go-live; the value is a single line so the change is one edit |
| Info | all workflows | `permissions: contents: read` at the top of every file. `packages: write` exists only on the `publish` job of `image-publish.yml`, and a test asserts it is absent above `jobs:` — a workflow-level write scope would hand that token to every third-party action in every job | None |
| Info | `lint.yml`, `frontend-dist.yml`, `image-smoke.yml` | Every caller-supplied string reaches the shell through the **environment**, never interpolated into the `run:` script. An expression expanded inline is a shell injection point, and the callers are files a future lot will generate | None |

Every action is pinned to a 40-hex commit with its `# vX.Y.Z` comment, resolved
from the release tag at authoring time (annotated tags dereferenced to the commit
they point at). A test rejects any `uses:` line that does not match, in the
workflows, in the caller template, and in the commented-out lines of the caller
template — a pin that decays while commented out comes back unpinned.

## Harness

| Severity | Location | Finding | Action |
|---|---|---|---|
| Warning | all workflows | **Nothing here has run on a GitHub runner.** The suite asserts structure and the two regexes that encode a documented rule; it does not assert that `docker compose` starts, that `metadata-action` emits the tags expected, or that a reusable workflow accepts the inputs the template passes. The plan's first validation criterion — one green case and one red case on a throwaway private repo — is **not met** | Deferred with V1 to V7. It is the first thing to run after the PR merges and the harness is pushed |
| Warning | `harness-invariants.yml` | It checks out `SelimLBOURAYA/claude-harness` at `main` to compare `CONVENTIONS.md`. While the harness repo is **private**, `github.token` from a consuming repo cannot read it, and the job fails with a checkout error rather than a conventions diff. An optional `harness_token` secret is declared and documented in the template, commented out | Close when V1 establishes whether the repo is public. If it stays private, uncomment the secret in all 8 callers |
| Info | `ci.yml` | The harness does **not** call `harness-invariants.yml` on itself: at ref `main` this repo does not yet carry `CONVENTIONS.md`, so the comparison would be against a ref that has nothing to compare, and `lot-deliverables.yml` expects a consuming project's layout. Both are exercised by the 8 repos from lot 7 onward. The reason is written in the file, not left to be rediscovered | None |
| Info | `commit-format.yml` | The subject-length rule **warns** above 72 and **fails** above 100. 72 is the git wrapping convention rather than a rule of §7, and 100 is where GitHub truncates the subject. Lot 0's own subject is 73 characters, which is how the distinction got noticed | None |

## Architecture

| Severity | Location | Finding | Action |
|---|---|---|---|
| Warning | `templates/ci-caller.yml` | The validation gate is an **inline job**, not a reusable workflow. The command, the toolchain, the java/node version and the artefact the build consumes are the most project-specific things in the file, and a reusable wrapper around them would be five inputs deep. The cost is real: 8 repos each maintain ~30 lines of setup, and a change to that shape is 8 edits | Accepted. `harness-sync` is the mechanism for propagating such a change; if it happens twice, promote it to `validate.yml` |
| Info | `lint.yml` | Each optional tool degrades to a **visible skip** written to the step summary, never to a silent `exit 0`. A test asserts there are exactly three such skips and that the file contains no `\|\| true`: a check that swallows its own failure is a green badge on an unchecked repository | None |

## Coverage exclusions

n/a — `Coverage tool` = none.

## Migrations

n/a — `Migrations directory` = n/a.

## Defect found and fixed in an earlier lot

Writing `lot-deliverables.yml` surfaced a real bug in the lot 1 hook. Its
`CRITICAL_LINE` regex matched the substring `critical` anywhere in a table row,
so the **summary table header** of every audit report — `| Dimension | Critical |
Warning | Info |` — was read as an unresolved Critical finding and would have
denied `gh pr create` on every lot, including this one. The severity is now
anchored to the row's first cell, in the hook and in the workflow alike, and two
assertions pin both halves of the distinction.

This is the first case of the CI layer and the hook layer being written against
the same rule and disagreeing. The disagreement is the point: one guard checked
the other.

## Validation criteria

- [ ] Each workflow tested on a throwaway **private** repo, one green case and
      one red case — **not executed**, deferred with V1 to V7. Structure,
      permissions, pins and the two encoded regexes are asserted statically (159
      assertions)
- [ ] `image-publish.yml`: no image pushed on a PR; `dev` + SHA tags on
      `develop`; `revision` label = the commit SHA — **not executed**. The three
      conditions are asserted as configuration
- [x] Report `docs/audits/lot-3.md`

## Recommended next steps

1. Run the first criterion on a throwaway private repo, before lot 7 wires any
   real project to these workflows.
2. Settle the harness repository's visibility; it decides whether
   `harness_token` is required in all 8 callers.
3. At the first go-live, make the trivy scan blocking on CRITICAL.
