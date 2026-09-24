---
name: lot-start
description: >-
  Starts a lot: resolves the repository, re-reads the project references,
  synchronises the lots file status table with develop, computes the candidate
  lot, asks every ambiguity in one batch and creates the lot branch, then waits
  for the user to type `lot-start confirm N`. Use before any lot development,
  when the user says "develop the next lot" or names a lot, and after the user
  confirms with `lot-start confirm N`.
metadata:
  version: "1.0"
---

# Lot Start — Frame the lot before the first write

The first link of the gate. The end of a lot is locked mechanically (gate skills,
git guard, CI); this skill does the same for its start, which used to rest on
prose that a weak model or a compacted context does not follow.

```
[lot-start]  →  development  →  lot-test  →  lot-review  →  lot-audit  →  lot-ship
```

Two hooks back it up, so skipping it does not work:

- `lot-lock-guard.py` **denies** every `Edit`/`Write` on a `feat/lot-N-*` branch
  until `.claude/current-lot` names that lot and that branch.
- `lot-confirm.sh` writes that lock **only** when the *user* submits
  `lot-start confirm N` (or `/claude-harness:lot-start confirm N`) as the whole
  prompt. The model cannot forge a user prompt: the lock is a real confirmation.
  You never write the lock yourself, and the guard denies it if you try.

This skill has two entry points: **Part A** when a lot is to be started, **Part B**
when the user has just confirmed (`lot-start confirm N` in the prompt, or this
skill invoked with the arguments `confirm N`).

## Part A — Before the confirmation

### Step A1 — Resolve the repository

```bash
LOT_REPO=$(git rev-parse --show-toplevel)
git -C "$LOT_REPO" branch --show-current
```

Same rule as `AUDIT_REPO` in `lot-audit` (lot 18, C3): never assume the session
directory is the right repository. `$LOT_REPO/CLAUDE.md` must carry a
`## Gate parameters` section; if it does not, or if the user named a lot of
another repository, **stop** and tell the user to reopen the session there.
Every command below is scoped with `-C "$LOT_REPO"`.

### Step A2 — Re-read the references, by extracts, in this order

1. `CLAUDE.md` (= `AGENTS.md`): the `Gate parameters`, `Skills` and
   `Project documents` sections only.
2. `CONVENTIONS.md`: **only** if this agent does not load it already. Under Claude
   Code it is in context through `~/.claude/coding-conventions.md`; re-reading it
   costs the whole file for nothing (§9).
3. The `Lots file`: the status table, then **only** the section of the candidate
   lot, once Step A4 has named it. Never the whole file.
4. `README.md`: the quick start section.
5. The project's own skills listed in the `Skills` table of `CLAUDE.md`
   (`.claude/skills/<name>/SKILL.md`), if any.

Targeted reads (grep, offset/limit), each file once.

### Step A3 — Synchronise the status table with git (§2.1), before any choice

```bash
git -C "$LOT_REPO" fetch --quiet origin
rtk proxy git -C "$LOT_REPO" log --first-parent --oneline -15 origin/develop
python3 <this skill's base directory>/sync-status.py "$LOT_REPO"
```

The script ships next to this file. Agents that do not load plugins run it from
the harness clone:
`~/ENV/projets/claude-harness/plugins/claude-harness/skills/lot-start/sync-status.py`.

It maps every merge on develop to its lot by branch name, and prints JSON.
A lot merged **without** a merge commit (rebase or squash, the usual GitHub
setting) leaves no branch name on develop; its audit commit
`docs(N): add the lot audit report`, which `lot-ship` requires before any push,
is taken as the proof instead. So a row left 🔄 by the previous lot is closed
here as soon as its pull request is merged. A row that lists its sub-lots
(`3.1 ✅, 3.3 🔄`) has each landed sub-lot marked, and turns ✅ once the last one
landed.

| Field | Meaning |
|---|---|
| `updates` | Lots merged on develop whose row is not ✅ yet: the table is stale |
| `sub_updates` | Sub-lots listed in a 🔄 row whose audit commit is on develop |
| `stops` | What you must **ask**, never decide |
| `in_progress` | Rows marked 🔄 |
| `candidate` | First ⬜ row in file order, ⏸️ and ❄️ skipped, **after** the updates |
| `changed` | Whether `--apply` modified the lots file |

A merge is mapped automatically only when it designates **exactly one** lot.
Every other case is in `stops` and exits 3:

| `kind` | Situation | What you do |
|---|---|---|
| `ambiguous` | Sub-lots (`2.1`, `2.2`) on one flat `feat/lot-2-*` branch, a branch shared by several open rows, or a sub-lot audit landed while the lots file names a sub-lot the row does not list | Ask which lots the merge completes |
| `done-without-merge` | A row is ✅ but develop has neither its merge nor a commit scoped to it | Ask whether the status is wrong or the lot shipped another way |
| `merge-without-lot` | A lot-shaped branch was merged but no row maps to it | Ask which row it belongs to |
| `scope-already-merged` | The candidate is ⬜ but develop already carries commits scoped to it | Ask whether it is done, partly done, or mislabelled |

**Any stop ends the turn** with the questions, in one batch. Do not create a
branch, do not pick a lot, do not edit the table to make the stop go away. This
is the exact failure of the 2026-09-21 incident: the table said « Lot 2 ⬜ »,
LOT-2.1 was merged, and the agent decided alone and redid it.

Once the user has answered, record the answer in the lots file (the rows the
merge completed, and a note citing the merge or commit SHA in backticks, e.g.
merge `abc1234`), and commit it with the sync in Part B. A cited SHA is reconciled:
the script no longer raises a stop on it, so the same question is never asked
twice. Recording the user's answer is not arbitrating; editing the table without
asking is.

Exit 2 means the repository is not harnessed, has no status table, or has no
develop: report the error and stop.

Do **not** run `--apply` in Part A. The working tree stays clean until the user
confirms; the updates are applied and committed in Part B, together with the
🔄 of the confirmed lot, as one commit.

### Step A4 — The candidate lot

- If the user named a lot, that is the candidate; say so if it differs from the
  script's `candidate`.
- Otherwise the candidate is the script's `candidate`. Never infer "the next
  lot" from memory, a summary or the conversation.
- If `in_progress` is not empty, a lot is still open (PR not merged): say so. A
  new lot does not start on top of an unmerged one (§2, no lot chaining) unless
  the user says otherwise.
- `candidate` is `null` → nothing is left to do; report and stop.

Read the candidate's section of the `Lots file`, and nothing else of it.

### Step A5 — Criteria and questions, in one batch

List the lot's acceptance criteria, restated in your own words. Then:

- If any criterion is ambiguous, ask **all** the questions in **one** batch now,
  before any write. The lot's own "points to settle" section, when it has one,
  is part of that batch.
- If there is none, write it explicitly: « no ambiguity », followed by the
  restated criteria.

### Step A6 — Create the branch, then hand the confirmation to the user

```bash
git -C "$LOT_REPO" switch -c feat/lot-N-<slug> origin/develop
```

`N` is the lot ID without any sub-version (flat branches, §7): lot `2.1` works on
`feat/lot-2-<slug>`. If the lots file names the branch in its `Branche` column,
use that name.

End the turn with exactly:

> Lot candidat : N — confirmer avec `lot-start confirm N`

(in the user's language). Then stop. Do not write anything; the guard would deny
it anyway.

## Part B — After the confirmation

The hook has written `.claude/current-lot` and told you so in the context. If
instead it blocked the prompt (unknown lot ID, wrong branch checked out), repeat
Step A6 and stop.

### Step B1 — Apply the synchronisation and mark the lot in progress

```bash
python3 <this skill's base directory>/sync-status.py "$LOT_REPO" --apply --start N
git -C "$LOT_REPO" status --short
```

- Exit 3 → something changed on develop since Part A: go back to Step A3.
- `changed: true` → commit the lots file **alone**, as the **first commit** of
  the lot branch, with nothing else staged:

  ```bash
  git -C "$LOT_REPO" add <Lots file>
  git -C "$LOT_REPO" commit -m "docs: sync lots file status"
  ```

- `changed: false` → the table was already right and the lot was already 🔄:
  no commit. Never create an empty one.

### Step B2 — Hand over to development

Report in three lines: lot confirmed, what the sync changed (or « table already
up to date »), the first development step. Development then follows §2 steps 4
to 8, and `lot-test` is the next gate skill.

## Rules

- Never write `.claude/current-lot`. Only the user's prompt creates it.
- Never arbitrate a stop of `sync-status.py`: ask.
- The sync commit is alone and first on the branch; no empty commit.
- One lot per session. `lot-start` never chains onto the next lot.
- History reads go through `rtk proxy git log` (P5-#14).
- Every repository read or write is scoped to `$LOT_REPO` (Step A1).
- Known limit: the write guard sees `Edit`, `Write`, `MultiEdit` and
  `NotebookEdit`, not a write made through `Bash`. Using `Bash` to get around
  the lock is a violation of this skill, not a workaround.
