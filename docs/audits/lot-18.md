# Lot Audit — Lot 18 — feat/lot-18-reaudit-fixes

**Harness ref:** ac5a470
**Scope:** 10 modified files | **Verdict:** Ready for PR

## Summary
| Dimension    | Critical | Warning | Info |
|--------------|----------|---------|------|
| Security     | 0        | 0       | 1    |
| Performance  | 0        | 0       | 1    |
| Architecture | 0        | 1       | 1    |

## Security

The step ran inline on the lot's diff rather than through a fan-out of
sub-tasks: six of the ten files are Markdown or test scripts, which the filter
list excludes outright, leaving one workflow as the whole attack surface. This
is recorded rather than silently done, per the skill's own rule on a step that
deviates.

| Severity | Location | Finding | Action |
|----------|----------|---------|--------|
| Info | `.github/workflows/lint.yml:165` | `python3 -m pip install --quiet pyyaml` installs an unpinned package from PyPI during the run. The job holds `contents: read` and neither new step references `nvd_api_key`, so a hostile release has no secret to reach for, but it is network-fetched code executing in CI. | Accepted for now. Pinning would mean carrying a version and a hash in the workflow for a library the runner usually already has; revisit if the harness ever grants this job a token. |

Examined and cleared:

- `yaml.safe_load_all`, not `yaml.load` — a hostile YAML document cannot
  construct arbitrary objects. This is the one line in the lot where the wrong
  call would have been remote code execution.
- `shellcheck` **analyses** the discovered scripts, it does not run them;
  `head` reads them and nothing sources them. Adding an executable file to the
  repository gets it parsed, not executed.
- The `prune` array and every `find` predicate are literals — no interpolation
  of anything an outsider supplies.
- `permissions: contents: read` is unchanged, and the workflow's `secrets:`
  block is untouched.

## Performance

| Severity | Location | Finding | Action |
|----------|----------|---------|--------|
| Info | `.github/workflows/lint.yml` | Three `find` passes over the tree per run and one `head` per executable file. On this repository that is 10 scripts; on a repository with a large vendored tree the prune list added by the review is what keeps it bounded. | No action. |

## Architecture

| Severity | Location | Finding | Action |
|----------|----------|---------|--------|
| Warning | `plugins/claude-harness/skills/lot-audit/SKILL.md` (Step 0) | The gate rule "review deliverable present, and stop if its recorded commit is behind HEAD" is unsatisfiable as written: `lot-review` records the SHA it reviewed, then commits its fixes and its own report on top, so the recorded SHA is **always** behind HEAD by the time `lot-audit` runs. The rule's intent is "no *code* landed after the review", which holds here — the two commits after `9f1f871` are the review's own fix and the review report. | Reported, not fixed: outside this lot's stated scope, and it belongs to a skill-wording lot. Recorded here; adding it to `dev-plan.md` awaits the user's approval, as the skill requires for any lots-file enrichment. |
| Info | `.github/workflows/ci.yml:30` | The harness now calls a reusable workflow on itself with `stack: harness`. That is the first self-call in this repository's CI; the file's header comment, which explains why only some workflows apply to a repo that *is* the harness, was updated in the same commit to say why this one does. | No action. |

Checked against `CONVENTIONS.md` and this repository's `CLAUDE.md`:

- §7 — Conventional Commits, English, `<type>(18): <message>`, no em dash. Seven
  commits, all conforming.
- §12 — `cmp CLAUDE.md AGENTS.md` silent; `CONVENTIONS.md` untouched by this lot.
- §12 — census updated in the same commit as each document added
  (`lot-18-review.md`, then this report).
- §2 step 1 — `docs: sync dev-plan.md status` is the branch's first commit,
  before any implementation.
- §3 — no skipped test, no disabled assertion, no commented-out code.

## Coverage exclusions

`Coverage threshold` is `n/a` and `Coverage exclusions` is empty for this
repository: a shell test suite with no coverage instrumentation. Nothing to
review, and nothing this lot changes about it.

## Migrations

n/a — `Migrations directory` is `n/a` for the harness.

## Lot-specific notes

The lot's own subject is a gate defect, so the gate that audits it is the thing
under test. Two consequences worth recording:

1. The plugin cache this session loaded (`0.1.0`, from `main`) predates the fix:
   the `lot-audit` procedure executed here is the **old** one, without Step 0b.
   The corrected skills become active for the portfolio only after the user
   promotes `develop` → `main`.
2. `shellcheck --severity=warning` has never run on this repository's 10 shell
   scripts — it is absent from the dependency budget and from this machine, so
   `tests/workflows.test.sh` skips its three real-binary assertions and verifies
   discovery through a stub instead. `bash -n` passes on all 10 files. The PR
   run is the first real shellcheck, and a finding there is fixed before merge.

## Recommended next steps

1. Watch the `lint` job on the PR run — it is the first real `shellcheck` pass
   over this repository, and the one check in this lot that local tooling cannot
   anticipate.
2. Merge, then promote `develop` → `main`: the skills' repository guard and the
   new lint branch are inert in the 8 repos until that promotion.
3. Follow-ups already written in `dev-plan.md`: `deployment` and
   `summerize-youtube` uncomment their own `lint` job. Awaiting approval before
   it joins them: the Step 0 wording above, for a skill-wording lot.

**Reminder:** `./tests/run.sh` must be green before the PR — it is, 7/7 suites.
