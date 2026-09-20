# Lot Audit — Lot 13 — deployment adoption

**Harness ref:** `chore/sync-lot-12-status`, from `8c6a7df`
**Workflows actually executed:** `@main`, i.e. `a0de7d1` — the first adoption to
run **after** the promotion that carries lot 17
**Target repo:** `deployment`, branch `chore/harness-adoption`, PR #9
**Commits:** `d926051`, `8108f4d`, `11e3ac5`
**Scope:** 8 files, +511 −61 | **Verdict:** ✅ Ready for PR — checklist complete,
validation gate green, 10 checks green on the PR, no Critical.

`deployment` was the least tooled repository of the portfolio and the only one
that touches production: no CI at all, no `.claude/`, an empty `stacks/`, and a
validation gate that was green by construction (audit P5-#17). This lot gives it
the same guards as the seven application repositories, and replaces the vacuous
gate with one that declares what it does not yet measure.

## Summary

| Dimension | Critical | Warning | Info |
|---|---|---|---|
| Security | 0 | 0 | 4 |
| Performance | 0 | 0 | 1 |
| Architecture | 0 | 2 | 2 |
| Harness | 0 | 2 | 1 |

## The decision this lot had to make

**A gate with nothing to measure.** The declared validation command was

```
find stacks -name 'docker-compose*.yml' -exec docker compose -f {} config -q \;
```

`stacks/` is an empty directory until LOT 1 creates `stacks/core`. `find` matches
nothing, `-exec` never fires, the command exits 0. For the length of thirteen
lots this repository has reported a green gate that looked at zero bytes — the
exact shape lot 17 refused for coverage thresholds, in the one repository whose
output is applied to production with `up -d`.

Three options were put to the user at the start of the lot, as `dev-plan.md`
asked: a `test -d stacks/core` guard that would fail until LOT 1, an explicitly
declared no-op, or pulling a minimal `stacks/core` forward from LOT 1. The user
chose the **declared no-op**, which is the same answer lot 17 accepts for a
coverage threshold of `0`: a repository with nothing to measure says so, and
ratchets up when there is something.

`scripts/validate-stacks.sh` therefore:

1. Collects every `stacks/*/docker-compose*.yml`.
2. With none, prints `no-op until LOT 1: stacks/ holds no docker-compose file
   yet (audit P5-#17)`, names the lot that ends it, and exits 0.
3. With any, requires `docker`, substitutes each stack's committed
   `.env.example` through `--env-file`, and runs `docker compose config -q` on
   each file, failing on the first that does not parse.

The day LOT 1 lands, the gate becomes real with no edit to `CLAUDE.md`, to
`ci.yml`, or to the script. That is the property the `test -d` variant did not
have: it would have shipped a red PR, and a red gate on the branch that installs
the gate teaches the reader to merge red.

## Common checklist, item by item

| # | Item | State |
|---|---|---|
| 1 | Branch `chore/harness-adoption` from `develop` | ✅ from `c2fdf03` |
| 2 | `.claude/settings.json`, marketplace + plugin, `"ref": "main"` | ✅ new file; `jq -e` on the ref and on `enabledPlugins` passes |
| 3 | Local skills removed, none project-specific kept | ✅ no `skill/` and no `.claude/skills/` ever existed here; nothing to remove or keep |
| 4 | `CLAUDE.md`: gate parameters, plugin skill names, no sprint chaining, census, `AGENTS.md` mirror | ✅ `cmp` silent; no "Sprint chaining" paragraph was present; ⛔ LOTD block: this repo never carried one, the `Skills` section now states the gate instead |
| 5 | `CONVENTIONS.md` = lot 5 master | ✅ was stale from byte 83; re-copied, `cmp` against `origin/main:CONVENTIONS.md` silent |
| 6 | `ci.yml` calls the lot 3 workflows, `branches: ["**"]`, SHA-pinned actions, `permissions: contents: read`, `concurrency`; `dependabot.yml` | ✅ one action, `actions/checkout`, pinned by SHA with a `# v7.0.1` comment; dependabot reduced to `github-actions` |
| 7 | `.claude/settings.local.json`: `git push *`, `gh pr *`, `git *` removed | ✅ no such file; `.claude/` did not exist before this lot |
| 8 | `.gitignore`: `.env`, `*.local.md` | ✅ both already present; verified that `stacks/*/.env` is ignored and `stacks/*/.env.example` is not, which the gate depends on |
| 9 | Branch naming documented | ✅ `CLAUDE.md` § Branch naming, enforced by the `branch-naming` job |
| 10 | Image / frontend workflows | n/a — this repository publishes no image and has no bundle |
| 11 | Gate green + this report | ✅ |
| 12 | Lots file opens with a `\| Lot \| Branche \| Statut \|` table | ✅ was `\| Lot \| Objectif \| Statut \|`; restructured to `\| Lot \| Branche \| Statut \| Objectif \|`, line 13, 15 rows, legend added |
| 13 | `CLAUDE.md` § Skills: pointer to the local harness clone for non-Claude agents | ✅ |
| 14 | Image repo: the image lot calls `image-publish.yml` | n/a |

Two items needed a judgement the checklist does not cover:

- **`paths-ignore` was deliberately dropped.** Every other adopted repository
  carries `paths-ignore: ["**.md"]`, on the reasoning that a documentation-only
  push does not change what the image contains. This repository produces no
  image, and what it does produce is documentation and compose files:
  `harness-invariants` checks `CLAUDE.md`, `AGENTS.md`, `CONVENTIONS.md` and
  `LOTS.md`, and with `paths-ignore` in place a push that broke the mirror would
  not have run a single job. The comment in `ci.yml` says so.
- **Two jobs of the template were not called.** `migrations-immutable` with
  `n/a` (the workflow's own `if:` would skip it, but the template says to delete
  the job rather than call it into a no-op), and `lint`, see Harness below.

## Security

| Severity | Location | Finding | Action |
|---|---|---|---|
| Info | `.github/workflows/ci.yml` | `HARNESS_READ_TOKEN` is passed through `secrets:` to the reusable workflow only — never echoed, never interpolated into a `run:` block, never written to a job summary. `permissions: contents: read` is declared at file level and no job raises it | None |
| Info | whole diff | No secret, credential, token or absolute user path (`/home/selim/…`) is introduced. The only path the new script builds is `$(dirname "$0")/..` | None |
| Info | `scripts/validate-stacks.sh` | `set -euo pipefail`; file list read through `mapfile` from `find`, so a path with a space cannot split; every expansion quoted; no `eval`, no unquoted command substitution, nothing read from the network | None |
| Info | `.gitignore` / `--env-file` | The gate substitutes each stack's committed `.env.example`, so the file is by design in git: a real value pasted into one would be published. Verified that `.env` is ignored (`*.env`) while `.env.example` is not (`!*.env.example`), which is what makes the two distinguishable at all | Watched by LOT 2, which owns the hardened `.env` files on the host |

## Performance

| Severity | Finding | Action |
|---|---|---|
| Info | Nothing runtime is touched. The whole CI run is 12 s at its longest job; the gate itself is 4 s and does no work today. When `stacks/` fills, `docker compose config` is a parse, not a pull | None |

## Architecture

| Severity | Location | Finding | Action |
|---|---|---|---|
| Warning | `scripts/validate-stacks.sh` / Gate parameters | The repository still has **no executable guarantee** about its own output until LOT 1. The no-op is declared rather than hidden, which is the improvement this lot delivers, but a declared zero is still a zero | LOT 1 ends it: `stacks/core` makes the same command real. Tracked in the `LOTS.md` status table and in the § Validation gate of `CLAUDE.md` |
| Warning | `.github/dependabot.yml` | No `docker` ecosystem. Dependabot reads `FROM` lines in a Dockerfile; it does not read the `image:` keys of a compose file, which is the only place this repository will ever pin an image. So the `postgres:17` and Caddy pins of LOT 1 will age unwatched | Noted in the file itself; LOT 1 decides the refresh mechanism when it writes the first pin |
| Info | `LOTS.md` | The status table was restructured into four columns. PR #8 (`chore/shrink-v1-scope`, open) edits the lot 5b row of the old three-column table, so whichever of the two merges second needs a one-line conflict resolution | Flagged in the PR body; the user chooses the merge order |
| Info | `CLAUDE.md` header | The banner still pointed at `~/.claude/coding-conventions.md` as the master, which lot 5 replaced with `claude-harness/CONVENTIONS.md`; the local copy had in fact drifted from byte 83 | Fixed in the same commit as the re-copy |

## Harness

| Severity | Location | Finding | Action |
|---|---|---|---|
| Warning | `.github/workflows/lint.yml` | The workflow has a `backend` branch (spotless, dependency-check) and a `frontend` branch (prettier, eslint, npm audit), and nothing else. Called with `stack: "other"` it produces two green checks that executed no step — the vacuous-green pattern P5-#17 raised against this very repository. The job was therefore **not** called here. An infra repository does have something to lint: `shellcheck` on `scripts/*.sh` and a YAML parse on the workflows and composes | Proposed for lot 15: an `other` branch in `lint.yml`. `shellcheck` is not installed locally and §4 of the conventions requires agreement before adding a dependency, so this is a proposal, not a change |
| Warning | gate allégé vs `lot-audit` Step 0 | `lot-audit` stops when `docs/audits/lot-N-review.md` is missing. No adoption lot from 7 to 13 has one: the `Gate allégé des lots de remédiation` of `dev-plan.md` defines three items (tests, audit, validation gate) and no review step. The skill and the plan disagree, and the plan won here, as it did for the six preceding lots | Recorded rather than silently skipped. Lot 15 should either exempt the adoption lots inside the skill or add the review deliverable to the gate allégé |
| Info | `@main` now carries lot 17 | Lot 12 could not exercise the lot 17 invariants because `main` was still `e87839c`. `main` is now `a0de7d1` and this PR ran them for real. Both are no-ops here — `Coverage threshold` is `n/a` and no exclusion is declared — but the steps executed instead of being replayed by hand | None; lot 15 re-runs them across all repos |

## Coverage exclusions

| Exclusion | Business code? | Proposed action |
|---|---|---|
| (none) | – | None. `Coverage tool` is `none` and `Coverage threshold` is `n/a`: this repository holds no application code, so there is nothing to measure and nothing to hide. `harness-invariants` skips both lot 17 steps on a non-numeric threshold |

## Migrations

`Migrations directory` is `n/a` and the `migrations-immutable` job is not called.
This repository owns the runtime, not a schema — each backend owns its own
changesets, and the expand/contract rule applies there.

## Validation gate

```
$ ./scripts/validate-stacks.sh
no-op until LOT 1: stacks/ holds no docker-compose file yet (audit P5-#17).
This gate validates every stacks/*/docker-compose*.yml and has nothing to
validate today. LOT 1 adds stacks/core and this command becomes real.
$ echo $?
0
```

PR #9: **10 checks, 10 pass, 0 fail** — 5 distinct checks run twice, once on the
`push` event and once on `pull_request`: `branch-naming`, `commit-format`,
`harness-invariants / invariants`, `lot-deliverables / deliverables`, `validate`.
Longest job 12 s.

Invariants also replayed against the working tree before the push:

| Check | Result |
|---|---|
| `cmp CLAUDE.md AGENTS.md` | silent |
| `CONVENTIONS.md` vs `origin/main` master | silent after the re-copy |
| `jq -e '…source.ref == "main"'` and plugin enabled | true |
| no `skill/` directory | ok |
| 11 gate parameter rows present | ok |
| coverage threshold has a subject (lot 17) | `n/a`, skipped |
| no exclusion covers a business package (lot 17) | no exclusion declared |
| census covers every skill and report | ok, 3 audit reports referenced |
| lots file opens with a status table | line 13, header `\| Lot \| Branche \| Statut \| Objectif \|` |
| no calendar commitment | ok |
| `ci.yml`, `dependabot.yml` parse as YAML; `settings.json` as JSON | ok |

## Left open

1. **`lint.yml` has no `other` branch.** Two infra-shaped repositories are now
   under the harness (`deployment`, and `claude-harness` itself) and neither gets
   a lint. See Harness.
2. **The gate is honest but still empty.** LOT 1 is what makes it a guard. Until
   then `deployment` is protected by `harness-invariants`, `commit-format` and
   `branch-naming` — document guards, not compose guards.
3. **Compose image pins have no watcher.** See the Architecture warning on
   dependabot; LOT 1 decides.
4. **PR #8 and this PR both edit `LOTS.md`.** One conflicted line, whichever
   merges second.

## Recommended next steps

1. Merge PR #9 (or PR #8 first, then resolve the one `LOTS.md` line here).
2. Lot 14 — `summerize-youtube`, the last adoption.
3. Lot 15 takes the two harness findings above: an `other` branch in `lint.yml`,
   and the `lot-audit` / gate allégé contradiction about the review deliverable.
