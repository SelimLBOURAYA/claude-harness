#!/usr/bin/env bash
# Exercises the lot write guard (lot 19) against the trapped cases of dev-plan.md.
#
# Real git repositories in a temp directory: the guard resolves the repository
# from the written path through git and realpath, and a fake would prove
# nothing about either.
set -uo pipefail
. "$(dirname "$0")/lib.sh"

GUARD="$REPO_ROOT/plugins/claude-harness/hooks/lot-lock-guard.py"
WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT

# make_repo <name> <branch> [harnessed=yes] : one commit, checked out on <branch>.
make_repo() {
  local dir="$WORK/$1"
  mkdir -p "$dir/src"
  git -C "$dir" init -q -b develop
  git -C "$dir" config user.email test@example.com
  git -C "$dir" config user.name Test
  if [ "${3:-yes}" = yes ]; then
    printf '# P\n\n## Gate parameters\n\n| Parameter | Value |\n|---|---|\n| `Lots file` | `lots.md` |\n' \
      > "$dir/CLAUDE.md"
  else
    printf '# P\n' > "$dir/CLAUDE.md"
  fi
  printf '| Lot | Branche | Statut |\n|---|---|---|\n| 5 | `feat/lot-5-x` | ⬜ |\n' > "$dir/lots.md"
  git -C "$dir" add -A
  git -C "$dir" commit -qm "chore: seed"
  [ "$2" = develop ] || git -C "$dir" switch -qc "$2"
  printf '%s' "$dir"
}

lock() { # lock <repo> <branch> : the lock lot-confirm.sh writes (lot 24)
  mkdir -p "$1/.claude"
  printf 'branch=%s\nconfirmed=2026-09-21T00:00:00Z\n' "$2" > "$1/.claude/current-lot"
}

# decision <cwd> <tool> <file_path>
decision() {
  local out
  out=$(jq -nc --arg t "$2" --arg f "$3" --arg d "$1" \
    '{tool_name:$t, tool_input:{file_path:$f}, cwd:$d}' | python3 "$GUARD" 2>/dev/null)
  [ -z "$out" ] && { printf 'pass'; return; }
  printf '%s' "$out" | jq -r '.hookSpecificOutput.permissionDecision // "pass"'
}

expect() { # expect <verdict> <label> <cwd> <tool> <path>
  assert_eq "$1" "$(decision "$3" "$4" "$5")" "$2"
}

reason_for() { # reason_for <cwd> <path> : the denial's reason
  jq -nc --arg d "$1" --arg f "$2" '{tool_name:"Write", tool_input:{file_path:$f}, cwd:$d}' \
    | python3 "$GUARD" | jq -r '.hookSpecificOutput.permissionDecisionReason'
}

LOT=$(make_repo lot-repo feat/lot-5-x)

# --- no lock: development is denied --------------------------------------
expect deny "lock absent: Write denied" "$LOT" Write "$LOT/src/App.java"
expect deny "lock absent: Edit denied" "$LOT" Edit "src/App.java"
expect deny "lock absent: MultiEdit denied" "$LOT" MultiEdit "$LOT/src/App.java"
out=$(jq -nc --arg d "$LOT" '{tool_name:"NotebookEdit", tool_input:{notebook_path:"src/n.ipynb"}, cwd:$d}' \
  | python3 "$GUARD" | jq -r '.hookSpecificOutput.permissionDecision')
assert_eq deny "$out" "lock absent: NotebookEdit denied"
reason=$(jq -nc --arg d "$LOT" '{tool_name:"Write", tool_input:{file_path:"src/A.java"}, cwd:$d}' \
  | python3 "$GUARD" | jq -r '.hookSpecificOutput.permissionDecisionReason')
assert_contains "$reason" "lot-start confirm <N>" "the deny tells how to get the lock"

# --- the lots file stays writable, the lock never is ---------------------
expect pass "lots file writable without a lock" "$LOT" Edit "$LOT/lots.md"
expect deny "the lock file is never written by a tool" "$LOT" Write "$LOT/.claude/current-lot"

# --- the lock is bound to the branch (lot 24) -----------------------------
lock "$LOT" feat/lot-6-y
expect deny "a lock of another branch" "$LOT" Write "$LOT/src/App.java"
assert_contains "$(reason_for "$LOT" "$LOT/src/App.java")" 'confirmed on `feat/lot-6-y`' \
  "the reason names the branch the lock was confirmed on"
lock "$LOT" feat/lot-5-x
expect pass "the lock of this branch: write goes to the normal flow" "$LOT" Write "$LOT/src/App.java"
expect deny "the lock file stays denied with a lock" "$LOT" Edit "$LOT/.claude/current-lot"
git -C "$LOT" branch -qm feat/lot-5-renamed
expect deny "branch renamed after confirmation" "$LOT" Write "$LOT/src/App.java"
git -C "$LOT" branch -qm feat/lot-5-x
# A lock written before lot 24 still carries its lot: the branch alone decides.
mkdir -p "$LOT/.claude"
printf 'lot=4\nbranch=feat/lot-5-x\nconfirmed=2026-09-21T00:00:00Z\n' > "$LOT/.claude/current-lot"
expect pass "a lock of the old format on this branch: the branch decides" "$LOT" Write "$LOT/src/App.java"
lock "$LOT" feat/lot-5-x

# --- the repository comes from the path, not from the session ------------
OTHER=$(make_repo other-repo feat/lot-7-z)
expect deny "../other-repo path judged against the other repository" \
  "$LOT" Write "../other-repo/src/B.java"
ln -s "$OTHER/src" "$LOT/src/linked"
expect deny "symlink into another repository judged against its target" \
  "$LOT" Write "$LOT/src/linked/B.java"
expect deny "a new file in a new directory of the other repository" \
  "$LOT" Write "$OTHER/src/deep/new/C.java"

# --- the git directory is never written by a tool -------------------------
expect deny "unlocked lot branch: .git/HEAD denied" "$LOT" Write "$LOT/.git/HEAD"
expect deny "unlocked lot branch: .git/config denied" "$LOT" Edit ".git/config"
expect deny "even with a matching lock: .git/hooks denied" "$LOT" Write "$LOT/.git/hooks/pre-commit"

# --- develop and main: left to the normal flow (lot 24) --------------------
DEV=$(make_repo dev-repo develop)
expect pass "develop: no lock required" "$DEV" Write "$DEV/src/App.java"
git -C "$DEV" branch -qm main
expect pass "main: no lock required" "$DEV" Edit "$DEV/src/App.java"

# --- outside the guard's business ----------------------------------------
PLAIN=$(make_repo plain-repo feat/lot-5-x no)
expect pass "repository without Gate parameters: silence" "$PLAIN" Write "$PLAIN/src/App.java"
expect pass "not harnessed: .git left to the normal flow" "$PLAIN" Write "$PLAIN/.git/config"
CHORE=$(make_repo chore-repo chore/tidy)
expect pass "chore/* branch: no lock required" "$CHORE" Write "$CHORE/src/App.java"
expect pass "outside any repository: silence" "$WORK" Write "$WORK/scratch.txt"
expect pass "a read-only tool is ignored" "$LOT" Read "$OTHER/src/B.java"
assert_eq "" "$(printf 'not json' | python3 "$GUARD")" "unparseable payload: silence"

# The guard narrows, it never widens.
assert_eq "" "$(grep -nE '"allow" *[,)]' "$GUARD" || true)" "the guard never answers allow"
assert_ok "the guard documents its Bash limit" -- grep -q 'is not seen by this guard' "$GUARD"

finish
