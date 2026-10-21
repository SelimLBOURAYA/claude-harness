---
name: lot-start
description: >-
  Starts a lot: resolves the repository, re-reads the project references,
  synchronises the lots file status table with develop, computes the candidate
  lot, asks every ambiguity in one batch and creates the lot branch, then waits
  for the user to type `lot-start confirm N`; closes the development by
  amending the project memory docs/memory.md. Use before any lot development,
  when the user says "develop the next lot" or names a lot, after the user
  confirms with `lot-start confirm N`, and once the lot's code is complete or on
  `lot-start close N`.
metadata:
  version: "2.1"
---

# Lot Start — Frame the lot before the first write

```
[lot-start]  →  development  →  [close]  →  lot-test  →  lot-review  →  lot-audit  →  lot-ship
```

Two hooks back this skill:

- `lot-lock-guard.py` denies every `Edit`/`Write` on a `feat/lot-*` branch until
  `.claude/current-lot` names that branch.
- `lot-confirm.sh` writes that lock only when the *user* submits
  `lot-start confirm N` (or `/claude-harness:lot-start confirm N`) as the whole
  prompt, on a `feat/lot-N-*` branch. You never write the lock; the guard denies
  it.

**Part A** runs when a lot is to be started, **Part B** once the user has
confirmed (`lot-start confirm N` in the prompt, or this skill invoked with
`confirm N`). Its Step B3 closes the development (`lot-start close N`, or on
your own once the code is complete).

## Part A — Before the confirmation

### Step A1 — Resolve the repository

```bash
LOT_REPO=$(git rev-parse --show-toplevel)
git -C "$LOT_REPO" branch --show-current
```

`$LOT_REPO/CLAUDE.md` must carry a `## Gate parameters` section. If it does not,
or the user named a lot of another repository, **stop** and tell the user to
reopen the session there. Every command below is scoped with `-C "$LOT_REPO"`.

### Step A2 — Re-read the references, by extracts

1. `CLAUDE.md`: the `Gate parameters`, `Skills` and `Project documents` sections.
2. `docs/memory.md`, the project memory (MEM-1), once, if it exists: working
   notes, not the truth. Check a note against the code before it guides a
   write.
3. The `Lots file`: the status table, then only the candidate lot's section once
   Step A4 names it.
4. The project's own skills listed in `CLAUDE.md` (`.claude/skills/<name>/SKILL.md`),
   if any.

`CONVENTIONS.md` is read only by an agent that does not load it (START-1).

### Step A3 — Synchronise the status table with git, before any choice

```bash
git -C "$LOT_REPO" fetch --quiet origin
rtk proxy git -C "$LOT_REPO" log --first-parent --oneline -15 origin/develop
python3 <this skill's base directory>/sync-status.py "$LOT_REPO"
```

Agents that load no plugin run the script from the harness clone:
`~/ENV/projets/claude-harness/plugins/claude-harness/skills/lot-start/sync-status.py`.

The script maps every merge on develop to its lot by branch name, or, for a
rebase or squash merge, by its audit commit `docs(N): add the lot audit report`,
and prints JSON. A row that lists its sub-lots (`3.1 ✅, 3.3 🔄`) has each landed
sub-lot marked, and turns ✅ once the last one landed.

| Field | Meaning |
|---|---|
| `updates` | Lots merged on develop whose row is not ✅ yet |
| `sub_updates` | Sub-lots listed in a 🔄 row whose audit commit is on develop |
| `stops` | What you must **ask**, never decide |
| `in_progress` | Rows marked 🔄 |
| `candidate` | First ⬜ row in file order, ⏸️ and ❄️ skipped, after the updates |
| `changed` | Whether `--apply` modified the lots file |

A merge is mapped automatically only when it designates exactly one lot. Every
other case is in `stops`, and the script exits 3:

| `kind` | Situation | What you do |
|---|---|---|
| `ambiguous` | Sub-lots on one flat `feat/lot-2-*` branch, or a branch shared by several open rows | Ask which lots the merge completes |
| `unlisted-subticket` | A row is about to close while the lots file names a sub-lot (`Ticket LOT-5.3`) the row does not list | Ask which sub-lots are done, then list them **in the row** (`5.1 ✅, 5.3 🔄`) |
| `done-without-merge` | A row is ✅ but develop has neither its merge nor a commit scoped to it | Ask whether the status is wrong or the lot shipped another way |
| `merge-without-lot` | A lot-shaped branch was merged but no row maps to it | Ask which row it belongs to |
| `scope-already-merged` | The candidate is ⬜ but develop already carries commits scoped to it | Ask whether it is done, partly done, or mislabelled |

**Any stop ends the turn** with the questions, in one batch (LOT-2): no branch,
no lot picked, no table edit to make the stop go away. Once the user has
answered, record the answer in the lots file (the rows the merge completed, and a
note citing the merge or commit SHA in backticks, e.g. merge `abc1234`) and commit
it with the sync in Part B. A cited SHA no longer raises a stop.

Exit 2: the repository is not harnessed, or has no status table, or no develop.
Report it and stop.

Do not run `--apply` in Part A: the working tree stays clean until the user
confirms.

### Step A4 — The candidate lot

- The lot the user named is the candidate; say so if it differs from the
  script's `candidate`.
- Otherwise the candidate is the script's `candidate` (LOT-1).
- `in_progress` not empty → a lot is still open: say so, and start a new one only
  if the user says to (LOT-6).
- `candidate` is `null` → nothing is left to do; report and stop.

Read the candidate's section of the `Lots file`, and nothing else of it.

### Step A5 — Criteria and questions, in one batch

Restate the lot's acceptance criteria, then ask every ambiguous point in one
batch, the lot's own "points to settle" included, or write « no ambiguity »
(LOT-4).

### Step A6 — Create the branch, then hand the confirmation to the user

```bash
git -C "$LOT_REPO" switch --no-track -c feat/lot-N-<slug> origin/develop
```

`--no-track` is required: a branch tracking `develop` sends a bare `git push`
to `develop`, and a bare `gh pr view` to the pull request whose head is
`develop`. `lot-ship` sets the upstream with its first `git push -u`.

`N` is the lot ID without sub-version: lot `2.1` works on `feat/lot-2-<slug>`.
Use the branch name of the lots file's `Branche` column when it gives one.

End the turn with exactly, in the user's language:

> Lot candidat : N — confirmer avec `lot-start confirm N`

Then stop.

## Part B — After the confirmation

The hook has written `.claude/current-lot` and said so in the context. If it
blocked the prompt instead (wrong branch checked out), repeat Step A6 and stop.

### Step B1 — Apply the synchronisation and mark the lot in progress

```bash
python3 <this skill's base directory>/sync-status.py "$LOT_REPO" --apply --start N
git -C "$LOT_REPO" status --short
```

- Exit 3 → develop changed since Part A: go back to Step A3.
- `changed: true` → commit the lots file alone, as the first commit of the lot
  branch:

  ```bash
  git -C "$LOT_REPO" add <Lots file>
  git -C "$LOT_REPO" commit -m "docs: sync lots file status"
  ```

- `changed: false` → no commit; never an empty one.

### Step B2 — Start the development

Report in three lines: lot confirmed, what the sync changed (or « table already
up to date »), the first development step. Then start that step in the same
turn. Development follows LOT-5, GATE-1 to GATE-3, and ends with Step B3.

The one exception is a question the confirmation did not settle: ask it, and
stop.

### Step B3 — Close the development

Run it on your own as soon as the lot's code and its tests (GATE-3) are complete
and the `Validation command` is green. `lot-start close N` (the prompt, or this
skill invoked with `close N`) is its explicit entry point. This session is the
only one that still holds the lot's reasoning: `lot-test` opens in a new
session, under any profile, and starts from the memory and the lots file.

1. `docs/memory.md` missing → create it from the harness template, header kept
   verbatim, and add it to the `## Project documents` census of `CLAUDE.md`,
   copied to `AGENTS.md` (DOC-1):

   ```bash
   git -C ~/ENV/projets/claude-harness fetch -q origin main
   git -C ~/ENV/projets/claude-harness show origin/main:templates/project/docs/memory.md > "$LOT_REPO/docs/memory.md"
   ```

2. Amend it with what the next session would otherwise pay to rediscover:

   | Section | What goes in |
   |---|---|
   | `## Code map` | Files and modules the lot created or moved: role, entry point |
   | `## Decisions` | Fact, reason, origin lot: a decision without its reason is not kept |
   | `## Pitfalls` | What cost this session time, and how to avoid it |
   | `## Open questions` | What the lot left unsettled |

   Rewrite or delete the notes the lot made wrong or obsolete; never append a
   lot journal. The header stays as is, and the file stays within 6000
   characters (`wc -m`): over the cap, merge or drop the least useful notes.
3. The file changed → `Validation command` green, then commit it alone, with
   its census entry when it is new:

   ```bash
   git -C "$LOT_REPO" add docs/memory.md   # plus CLAUDE.md AGENTS.md when new
   git -C "$LOT_REPO" commit -m "docs(N): update the project memory"
   ```

   Unchanged → no commit; never an empty one.
4. Stop. Report the lot's last commit and tell the user to open a **new
   session** for `lot-test` (LOT-7).

## Rules

- Never write `.claude/current-lot`.
- Never arbitrate a stop of `sync-status.py`: ask.
- The sync commit is alone and first on the branch; no empty commit.
- The memory is amended by the development session only (Step B3), and
  committed only when it changed.
- History reads go through `rtk proxy git log`.
- Every repository read or write is scoped to `$LOT_REPO`.
- The write guard does not see a write made through `Bash`; using `Bash` to get
  around the lock violates this skill.
