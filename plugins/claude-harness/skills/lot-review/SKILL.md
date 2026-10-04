---
name: lot-review
description: >-
  Reviews the code of the current lot, applies the retained fixes and asks the
  owner about the findings that need a decision, then writes
  docs/audits/lot-N-review.md. Runs only under the claude profile, in a new
  session. Use after lot-test and before lot-audit, or when the user asks for a
  code review of the lot.
metadata:
  version: "2.0"
---

# Lot Review — Code review before the audit

Reviews the lot's own code, applies the fixes, and records what happened. No PR
exists yet (`lot-ship` opens it), so nothing is posted on GitHub.

```
lot-test  →  [lot-review]  →  lot-audit  →  lot-ship
```

## Step 0 — Profile guard, before anything else

```bash
printenv ANTHROPIC_BASE_URL
```

Not empty → the session runs under the `deepseek` profile (LOT-7). Do not
review, do not touch the working tree; print exactly this, then end the turn:

> Code review needs the `claude` profile, in a new session.
>
> 1. End this session.
> 2. Run `/home/selim/.local/bin/claude-profile claude`.
> 3. Open a **new** session.
> 4. Re-run `lot-review`.

Never attempt the switch yourself (PROF-1).

## Step 0b — The reviewed repository is the session's repository

```bash
REVIEW_REPO=$(git rev-parse --show-toplevel)
git -C "$REVIEW_REPO" branch --show-current
```

The current branch must match `^(feat|fix|chore)/lot-`, and that lot's section
must exist in this repository's `Lots file`; otherwise **stop** and tell the
user to reopen the session in the repository holding the lot branch.
`Skill(code-review)` reads the working directory and `--fix` writes to it, so a
session in the wrong repository edits the wrong files. Every `git` command
below carries `-C "$REVIEW_REPO"`, and the deliverable is written inside it.

## Step 1 — Identify the target

The target is the local diff against the fetched `origin/develop`, never the
local `develop`:

```bash
git -C "$REVIEW_REPO" fetch -q origin develop
# gh resolves the repository from the current directory, and follows the
# branch's upstream unless the branch is named.
(cd "$REVIEW_REPO" && gh pr view "$(git branch --show-current)" --json number,url,headRefName) 2>/dev/null
rtk proxy git -C "$REVIEW_REPO" log --first-parent origin/develop..HEAD --oneline
```

A PR already open (a lot re-reviewed after `lot-ship`) is said in the report;
the review is still of the local diff. Read the lot's section in the
`Lots file`: the review is against the lot's stated scope.

## Step 2 — Run the review

```
Skill(code-review) with arguments: --fix feat/lot-N-<slug> (diff against origin/develop)
```

Name the branch and the base: a lot branch has no upstream before `lot-ship`
pushes it, and without a target `code-review` falls back to `main`.

`--fix` applies the retained findings to the working tree, without committing.
It may run as a forked agent writing the tree while this session reads it:

- **Edit nothing until it has returned.**
- **Keep its fixes inside the lot's source diff.** Revert a change to any other
  file (`git -C "$REVIEW_REPO" restore <path>`) and record its finding as
  deferred. The lot's status line in the `Lots file` is the one exception.
- **Findings that need a decision** (an authorization model, a deviation from
  the lot's specification, a schema change): ask the owner, all in one batch,
  then apply the answers before Step 3.

A finding about code the lot did not touch becomes a candidate lot in Step 4.

## Step 3 — Commit the fixes

Read what `--fix` changed before committing it.

```bash
<Validation command>          # from Gate parameters, green before committing
git -C "$REVIEW_REPO" diff --stat
git -C "$REVIEW_REPO" commit -m "fix(N): apply the lot review findings"
```

`fix(N)` for a defect, `refactor(N)` for a cleanup with no behaviour change; two
commits when the lot produced both. A rejected finding gets its reason in the
report.

## Step 4 — Write the deliverable

Write **`docs/audits/lot-N-review.md`**:

```markdown
# Lot Review — Lot N — [branch name]

**Harness ref:** [version of the installed harness, see below]
**Model:** [the model that ran this review]
**Target:** local diff origin/develop...HEAD
**Reviewed at:** [short SHA of HEAD once the fixes are committed]
**Verdict:** Clean / Fixed / Findings deferred

## Findings
| # | Severity | Location | Finding | Outcome |
|---|----------|----------|---------|---------|
| 1 | …        | `path:line` | …    | fixed in <sha> / rejected: <reason> / deferred to <lot> |

## Candidate lots
[cross-cutting findings outside this lot's scope, or "none"]
```

The **Harness ref** is the installed copy of the plugin that ran:

```bash
python3 <this skill's base directory>/../../hooks/plugin-currency.py --installed-version
```

Empty output (an agent that loads no plugin) → the version `main` declares:
`git -C ~/ENV/projets/claude-harness fetch -q origin main` then
`git -C ~/ENV/projets/claude-harness show origin/main:plugins/claude-harness/.claude-plugin/plugin.json | jq -r .version`.

## Step 5 — Commit the deliverable

1. `<Validation command>` green.
2. A new report enters the `## Project documents` census of `CLAUDE.md`, copied
   to `AGENTS.md` (DOC-1).
3. Commit the report and the census, nothing else (GATE-8):

   ```
   docs(N): add the lot review report
   ```

4. Do not push: the push belongs to `lot-ship`.

## Step 6 — Hand over

Report the verdict and the deliverable path, then hand over to `lot-audit`. Do
not run the audit from this skill (GATE-7).

## Rules

- Only under the `claude` profile, in a new session (LOT-7).
- Review the lot's diff, not the repository.
- Every finding ends fixed, rejected with a reason, or deferred to a named lot.
- Do not open, merge or close a PR here.
- History reads through `rtk proxy git log`.
- Every repository read or write is scoped to `$REVIEW_REPO`.
