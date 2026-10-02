---
name: lot-review
description: >-
  Reviews the code of the current lot, applies the retained fixes and asks the
  owner about the findings that need a decision, then writes
  docs/audits/lot-N-review.md. Runs only under the claude profile. Use after lot-test and before lot-audit, or
  when the user asks for a code review of the lot.
metadata:
  version: "1.1"
---

# Lot Review — Code review before the audit

Reviews the lot's own code, applies the fixes, and records what happened. The
report is the trail: no PR exists yet when the review runs (`lot-ship` opens it
afterwards), so nothing is posted on GitHub. It runs **before** `lot-audit`: auditing code that has
not been reviewed produces a report about a version nobody looked at.

Gate position:

```
lot-test  →  [lot-review]  →  lot-audit  →  lot-ship
```

## Step 0 — Profile guard, before anything else

**This skill runs under the `claude` profile only.** Check first, and stop if the
check fails — do not review, do not comment, do not touch the working tree.

Two signals, both must hold:

1. `printenv ANTHROPIC_BASE_URL` is **empty**. The `deepseek` profile sets it to
   `https://api.deepseek.com/anthropic`; the `claude` profile sets no base URL.
2. The model this session announces for itself is a **Claude** model, not a
   `deepseek-*` one.

If either fails, stop and print exactly this, then end the turn:

> Code review needs the `claude` profile; this session is running under
> `deepseek`. Switching the profile mid-session does **not** change the model of
> the running session — only `settings.json`, which the *next* session reads.
>
> 1. End this session.
> 2. Run `/home/selim/.local/bin/claude-profile claude`.
> 3. Open a **new** session.
> 4. Re-run `lot-review`.

This is not a preference. It was verified on 2026-09-18: after
`claude-profile deepseek` then `claude-profile claude`, the running session
stayed on `deepseek-v4-pro[1m]` while `settings.json` already read
`claude-fable-5-1[1m]`. An agent that "switches and continues" is reviewing its
own output with the model that wrote it.

**Never attempt the switch yourself.** The stop is the deliverable of this step.

## Step 0b — The reviewed repository is the session's repository

```bash
REVIEW_REPO=$(git rev-parse --show-toplevel)
git -C "$REVIEW_REPO" branch --show-current
```

`$REVIEW_REPO` must be the repository holding the lot branch. If the session runs
elsewhere — typically in the harness clone while the lot lives in an adopted
repository — **stop**, and tell the user to reopen the session in that
repository.

`REVIEW_REPO` comes from the session's own directory, so it cannot detect the
mismatch on its own. Assert the independent signal too — the current branch
matches `^(feat|fix|chore)/lot-` and that lot's section exists in this
repository's `Lots file` — and stop if either fails.

`Skill(code-review)` takes no repository argument: it reads the working
directory, and `--fix` **writes** to it. A session pointed at the wrong
repository does not produce an empty review, it produces a review of another
repository's diff and edits that repository's files. Same root cause as the
`lot-audit` defect of lot 18 (C3), where the security step silently audited the
harness clone for seven lots.

Every `git` and `gh` command below therefore carries `-C "$REVIEW_REPO"` /
`--repo`, and the deliverable is written inside `$REVIEW_REPO`.

## Step 1 — Identify the target

The target is the local diff `origin/develop...HEAD`. In the gate order the PR
does not exist yet; if one is open anyway (a lot re-reviewed after `lot-ship`),
say so in the report and still review the local diff.

The base is `origin/develop`, fetched first, never the local `develop`: the
local branch only moves on a `git pull` made on it, and a stale one puts every
lot merged since into the diff as if this lot had written it.

```bash
git -C "$REVIEW_REPO" rev-parse --show-toplevel   # confirms the target repo
git -C "$REVIEW_REPO" fetch -q origin develop
# `gh` resolves the repository from the *current* directory, never from a `git
# -C`: run it inside $REVIEW_REPO, or it answers about another repository's PR.
# Name the branch: without it, `gh` follows the branch's upstream, which is
# `develop` for a branch started from origin/develop without --no-track, and
# answers about the PR whose head is develop: the promotion PR when one is open.
(cd "$REVIEW_REPO" && gh pr view "$(git branch --show-current)" --json number,url,headRefName) 2>/dev/null
rtk proxy git -C "$REVIEW_REPO" log --first-parent origin/develop..HEAD --oneline
```

Read the lot's section in the `Lots file` so the review is against the lot's
stated scope, not against a general sense of taste.

## Step 2 — Run the review

Invoke the harness-provided review skill on the target:

```
Skill(code-review) with arguments: --fix feat/lot-N-<slug> (diff against origin/develop)
```

Name the branch and the base. Without a target, `code-review` diffs against the
branch's upstream, and a lot branch has none until `lot-ship` pushes it
(`lot-start` creates it with `--no-track`): the fallback base is then `main`,
and every unpromoted commit of `develop` lands in the review as if this lot had
written it.

`--fix` applies the retained findings to the **working tree**. It does not
commit; committing is Step 3. No `--comment`: there is no PR to comment on
before `lot-ship`, and the option did nothing in every lot that ran it (lot 22).

`code-review` may run as a forked agent that writes the working tree while this
session is still reading it:

- **Edit nothing until it has returned.** A parallel edit races its `--fix`.
- **Keep its fixes inside the lot's source diff.** A change it made to any other
  file is reverted (`git -C "$REVIEW_REPO" restore <path>`), and the finding
  that prompted it is recorded as deferred. The one exception is the status line
  of the lot in the `Lots file`.
- **Findings that need a decision** (an authorization model, a deviation from
  the lot's specification, a schema change) are not left half-applied: ask the
  owner, all of them in **one** batch, then apply the answers yourself before
  Step 3.

Scope the review to the lot's diff. A finding about code the lot did not touch
is not this lot's business: record it as a candidate lot in Step 4 rather than
widening the diff.

## Step 3 — Commit the fixes

Review what `--fix` changed before committing — an applied fix is still your
change, not the tool's.

```bash
<Validation command>          # from Gate parameters, green before committing
git -C "$REVIEW_REPO" diff --stat
git -C "$REVIEW_REPO" commit -m "fix(N): apply the lot review findings"
```

Use `fix(N)` for a defect and `refactor(N)` for a cleanup with no behaviour
change; split into two commits when the lot produced both. The commit message
follows §7 like any other: English, Conventional Commits, no em dash.

If a finding is **rejected**, say why in the deliverable. A rejected finding with
a written reason is a decision; a silently dropped one is a gap.

## Step 4 — Write the deliverable

Write **`docs/audits/lot-N-review.md`**:

```markdown
# Lot Review — Lot N — [branch name]

**Harness ref:** [short SHA of the installed harness, see below]
**Model:** [the model that ran this review]
**Target:** local diff origin/develop...HEAD
**Read at:** [short SHA of HEAD when the review read the diff]
**Fix commit:** [short SHA, or "none needed"]
**Reviewed at:** [short SHA of HEAD once the fixes are committed: the fix commit, or the Read at SHA when none was needed]
**Verdict:** Clean / Fixed / Findings deferred

## Findings
| # | Severity | Location | Finding | Outcome |
|---|----------|----------|---------|---------|
| 1 | …        | `path:line` | …    | fixed in <sha> / rejected: <reason> / deferred to <lot> |

## Candidate lots
[cross-cutting findings outside this lot's scope, or "none"]
```

**Read at** is the code the review looked at; **Reviewed at** is the code the
audit will see, reviewed and fixed. `lot-audit` (step 0) refuses to run when a
commit after **Reviewed at** touches anything but `docs/audits/` and the census
(`CLAUDE.md`, `AGENTS.md`): that is code nobody reviewed. The report's own
commit, which comes after, touches nothing else.

The **Harness ref** is the harness that actually ran, the installed copy of the
plugin, not the checkout of the local clone, which may sit on a working branch:

```bash
python3 <this skill's base directory>/../../hooks/plugin-currency.py --installed-sha
```

Empty output (an agent that loads no plugin) → the `main` of the clone, fetched
first: `git -C ~/ENV/projets/claude-harness fetch -q origin main` then
`git -C ~/ENV/projets/claude-harness rev-parse --short origin/main`.

## Step 5 — Commit the deliverable

The report is the **proof** that this skill ran (section 13). Left in the working
tree it does not exist: `lot-deliverables.yml` reads the repository, not the file
system, and `lot-audit` (step 0) checks what landed after the **Reviewed at** SHA.

1. Run the `<Validation command>` of the project `CLAUDE.md` — green, or the
   commit does not happen.
2. If `docs/audits/lot-N-review.md` is new, or its role changed, add it to the
   `## Project documents` census of `CLAUDE.md`, and copy `CLAUDE.md` to
   `AGENTS.md` byte for byte (section 12).
3. Append the `## lot-review` section to `docs/audits/lot-N-friction.md`, in the
   format of `CONVENTIONS.md` §13 (« Friction »): what, in running **this
   skill**, failed, came back empty, was ambiguous or cost for nothing. Each
   entry opens with its key, `` `lot-review / <step>` ``. Nothing to record →
   `None.` Findings about the lot's code stay in the report, not here.
4. Commit the report with that section and nothing else, in the lot's scope:

   ```
   docs(N): add the lot review report
   ```

5. Do not push: the push belongs to `lot-ship`.

A deliverable left uncommitted is how a reviewed lot reaches its PR with no trace
of the review, and how the audit after it compares a SHA to a file that is not in
the history.

## Step 6 — Hand over

Report the verdict and the deliverable path, then hand over to `lot-audit`.
Do not run the audit from this skill — each gate step is invoked explicitly, so
that skipping one is visible.

## Rules

- Never run under a profile other than `claude`, and never switch profile
  mid-session to get there.
- Review the lot's diff, not the repository.
- The report is committed before this skill reports back, never left in the
  working tree.
- Every finding ends as fixed, rejected with a reason, or deferred to a named
  lot. None disappears.
- `<Validation command>` green before the fix commit.
- Do not open, merge or close a PR here — that belongs to `lot-ship`.
- History reads through `rtk proxy git log` (P5-#14).
- Every repository read or write is scoped to `$REVIEW_REPO` (step 0b).
