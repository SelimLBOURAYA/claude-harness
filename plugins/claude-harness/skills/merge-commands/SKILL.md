---
name: merge-commands
description: Hands the user a ready-to-paste shell block that merges a set of open pull requests in the right order, preceded by a one-line-per-PR summary. Use when a guard denies you a merge (gh pr merge), when PRs you opened are left for the user to merge, or when the user asks for "la commande pour merger", "dans le bon ordre", or a merge order.
---

# merge-commands

You never merge here: the guards forbid it. You check the PRs, order them and print the
command the user runs. Never run a `gh pr merge` or an update-branch call yourself.

## Step 1. Collect the PRs

Take the PRs from the conversation (the ones you opened, or the ones the user names).
If none are named, ask; do not sweep every repository.

## Step 2. Check each PR (read-only, one Bash call per PR, in parallel)

```
gh pr view <N> --repo <owner>/<repo> --json number,title,state,mergeable,mergeStateStatus,baseRefName,headRefName,files
```

Drop and report, outside the command:
- `state` is `MERGED` or `CLOSED`: already done, say so.
- `mergeable` is `CONFLICTING` or `mergeStateStatus` is `DIRTY`: the user resolves it first.
- `baseRefName` is `main`: never merged by this command (GIT-1), unless the user asked for a hotfix.
- head `chore/sync-harness-files`: the `sync-projects` workflow merges it (GIT-7).

A PR with pending or failing CI stays in: the command waits for its checks and stops on a red one.

## Step 3. Order

Apply in this order, then keep the user's or the conversation's order for ties:
1. Stacked PRs: a PR whose `baseRefName` is another PR's `headRefName` comes after it.
2. Same repository, overlapping `files`: the smaller or alignment PR (harness docs,
   `CLAUDE.md`/`AGENTS.md`, dependency bumps) goes first; each later PR of that repository
   gets an update-branch call and a `sleep 20` before its merge.
3. Cross-repository dependencies: the harness repo before projects, a backend before the
   frontend that consumes its API change.
4. PRs whose CI is still running go last.

## Step 4. Output (in the user's language)

First a short list, one line per PR whenever it fits, in merge order:

```
1. deployment#15: CalDAV et passage à Funnel + mTLS (rebase sur develop d'abord)
2. kreadevis#58: alignement CLAUDE.md / AGENTS.md
3. elya#53: pin JDK 25 dans Dependabot (CI en cours)
```

Each line: `repo#N: <what it changes, in a few words>`, plus a parenthesis only for an
order reason or a status (CI pending, rebase needed). Then the dropped PRs with their reason.

Then a single `bash` block, wrapped in a subshell so `set -e` never closes the terminal:

```bash
(
set -e
m() { gh pr checks "$2" --repo "<owner>/$1" --watch --fail-fast && gh pr merge "$2" --repo "<owner>/$1" --merge; }
m <repo> <N>
gh api -X PUT repos/<owner>/<repo>/pulls/<N>/update-branch
sleep 20
m <repo> <N>
)
```

Rules for the block:
- `--merge`, the strategy of the harness skills; no `--auto`, no `--admin`.
- Update a branch with `gh api -X PUT .../update-branch`, never `gh pr update-branch`
  (missing from the Ubuntu `gh` 2.45).
- If PRs span several owners, write the full `owner/repo` in each call instead of `<owner>/$1`.

After the block, two lines at most: if a step fails, the block stops there; remove the
merged lines and rerun. An update-branch error saying the branch is already up to date
stops it too: rerun without that `gh api` line and its `sleep`.
