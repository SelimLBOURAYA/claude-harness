#!/usr/bin/env bash
# Exercises the git/gh guard against every trapped case listed in dev-plan.md
# ("Gate allege des lots de remediation", rule 1).
#
# The fixtures are real git repositories created in a temp directory: the guard
# resolves branches and repo roots by shelling out to git, and a fake would
# prove nothing about that path.
set -uo pipefail
. "$(dirname "$0")/lib.sh"

GUARD="$REPO_ROOT/plugins/claude-harness/hooks/git-guard.py"
WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT

# make_repo <name> <branch> : a repo with one commit, checked out on <branch>.
make_repo() {
  local dir="$WORK/$1"
  mkdir -p "$dir"
  git -C "$dir" init -q -b main
  git -C "$dir" config user.email test@example.com
  git -C "$dir" config user.name Test
  git -C "$dir" remote add origin git@github.com:example/"$1".git
  printf 'seed\n' > "$dir/README.md"
  git -C "$dir" add README.md
  git -C "$dir" commit -qm "chore: seed"
  [ "$2" = "main" ] || git -C "$dir" switch -qc "$2"
  printf '%s' "$dir"
}

# decision <cwd> <command> : the guard's verdict, or "pass" when it stays silent.
decision() {
  local out
  out=$(printf '%s' "$(jq -nc --arg c "$2" --arg d "$1" \
    '{tool_name:"Bash", tool_input:{command:$c}, cwd:$d}')" | python3 "$GUARD" 2>/dev/null)
  [ -z "$out" ] && { printf 'pass'; return; }
  printf '%s' "$out" | jq -r '.hookSpecificOutput.permissionDecision // "pass"'
}

# expect <verdict> <cwd> <command>
expect() {
  assert_eq "$1" "$(decision "$2" "$3")" "$3"
}

FEAT=$(make_repo feat-repo feat/lot-1-hooks)
MAIN=$(make_repo main-repo main)

# --- pushes to the production branch -------------------------------------
expect deny "$FEAT" "git push origin HEAD:main"
expect deny "$FEAT" "git push origin main"
expect deny "$FEAT" "git push origin HEAD:refs/heads/main"
expect deny "$FEAT" "git push origin feat/lot-1-hooks:main"
expect deny "$MAIN" "git push"
expect deny "$MAIN" "git push origin"

# --- history rewriting and hook bypassing --------------------------------
expect deny "$FEAT" "git push -f"
expect deny "$FEAT" "git push --force"
expect deny "$FEAT" "git push --force-with-lease"
expect deny "$FEAT" "git push --force-if-includes origin HEAD"
expect deny "$FEAT" "git push origin +feat/lot-1-hooks"
expect deny "$FEAT" "git push --no-verify origin feat/lot-1-hooks"
expect deny "$FEAT" "git push -fu origin feat/lot-1-hooks"
# On push, -n is --dry-run, not --no-verify: it must not be mistaken for a bypass.
expect ask "$FEAT" "git push -n origin feat/lot-1-hooks"
expect deny "$FEAT" "git commit --no-verify -m 'chore: x'"
expect deny "$FEAT" "git commit -n -m 'chore: x'"
expect deny "$FEAT" "git -c core.hooksPath=/dev/null commit -m 'chore: x'"
expect deny "$FEAT" "git -c core.hooksPath=/dev/null push"
expect deny "$FEAT" "git -ccore.hooksPath=/dev/null commit -m 'chore: x'"
expect deny "$FEAT" "git reset --hard origin/develop"

# --- remote branch deletion ----------------------------------------------
expect deny "$FEAT" "git push origin --delete feat/lot-1-hooks"
expect deny "$FEAT" "git push origin :feat/lot-1-hooks"
expect deny "$FEAT" "git branch -D origin/feat/lot-1-hooks"
expect deny "$FEAT" "git branch -rd origin/feat/lot-1-hooks"

# A local branch deletion is ordinary housekeeping, not a guard concern.
expect pass "$FEAT" "git branch -D feat/lot-1-hooks"

# --- the guard must follow -C, cd and bash -c ----------------------------
expect deny "$WORK" "git -C $MAIN push"
expect deny "$WORK" "git -C$MAIN push"
expect deny "$WORK" "cd $MAIN && git push"
expect deny "$WORK" "bash -c \"cd $MAIN && git push\""
expect deny "$FEAT" "bash -c 'git push --force'"
expect deny "$FEAT" "sh -c 'git push origin HEAD:main'"
expect deny "$FEAT" "echo start && git push origin main"
expect deny "$FEAT" "git status; git push origin main"

# --- what cannot be resolved must be confirmed, never passed -------------
expect ask "$FEAT" "B=main; git push origin \$B"
expect ask "$FEAT" "git push origin \$(git branch --show-current)"
expect ask "$FEAT" "git push origin 'unbalanced"
expect ask "$WORK" "git push"

# --- ordinary pushes ask for confirmation --------------------------------
expect ask "$FEAT" "git push"
expect ask "$FEAT" "git push -u origin feat/lot-1-hooks"
expect ask "$FEAT" "git push origin HEAD"

# --- commands the guard has no opinion about -----------------------------
expect pass "$FEAT" "git status"
expect pass "$FEAT" "git log --oneline -5"
expect pass "$FEAT" "git commit -m 'feat(1): add the git guard'"
expect pass "$FEAT" "git switch -c feat/lot-2-skills develop"
expect pass "$FEAT" "npm test"

# --- gh pull requests ----------------------------------------------------
expect deny "$FEAT" "gh pr merge 12 --squash"
expect deny "$FEAT" "gh pr create --title t --body b"
expect deny "$FEAT" "gh pr create -B main --title t --body b"
expect deny "$FEAT" "gh pr create --base main --title t --body b"
expect deny "$FEAT" "gh pr create --base=main --title t --body b"

# On a lot branch, no audit report means no PR.
expect deny "$FEAT" "gh pr create --base develop --title t --body b"

mkdir -p "$FEAT/docs/audits"
printf '# Lot 1\n\n| Severity | Finding |\n|---|---|\n| Info | none |\n' \
  > "$FEAT/docs/audits/lot-1.md"
expect ask "$FEAT" "gh pr create --base develop --title t --body b"
expect ask "$FEAT" "gh pr create -B develop --title t --body b"

# An unresolved Critical row blocks the PR; a resolved one does not.
printf '| Critical | src/x | secret in logs | fix it |\n' >> "$FEAT/docs/audits/lot-1.md"
expect deny "$FEAT" "gh pr create --base develop --title t --body b"
printf '' > "$FEAT/docs/audits/lot-1.md"
printf '# Lot 1\n\n| Critical | src/x | secret in logs | resolved in 1a2b3c4 |\n' \
  > "$FEAT/docs/audits/lot-1.md"
expect ask "$FEAT" "gh pr create --base develop --title t --body b"

# The severity must be the row's FIRST cell. Every report opens with a summary
# table whose header names a Critical column and whose counts are zero; that
# header is not a finding and must not block the PR.
printf '# Lot 1\n\n| Dimension | Critical | Warning | Info |\n|---|---|---|---|\n| Security | 0 | 1 | 1 |\n' \
  > "$FEAT/docs/audits/lot-1.md"
expect ask "$FEAT" "gh pr create --base develop --title t --body b"
# A severity cell prefixed by its emoji still counts as a first-cell Critical.
printf '| ⚠️ Critical | src/y | token in clear | to do |\n' >> "$FEAT/docs/audits/lot-1.md"
expect deny "$FEAT" "gh pr create --base develop --title t --body b"

# A frontend repo additionally needs its integration report.
FRONT=$(make_repo front-repo feat/lot-3-list)
mkdir -p "$FRONT/docs/audits"
printf '# Lot 3\n' > "$FRONT/docs/audits/lot-3.md"
printf '## Gate parameters\n\n| Parameter | Value |\n|---|---|\n| `Stack` | `frontend` |\n' \
  > "$FRONT/CLAUDE.md"
expect deny "$FRONT" "gh pr create --base develop --title t --body b"
printf '# Integration\n' > "$FRONT/docs/audits/lot-0-integration.md"
expect ask "$FRONT" "gh pr create --base develop --title t --body b"

# Other gh commands are none of the guard's business.
expect pass "$FEAT" "gh pr view 12"
expect pass "$FEAT" "gh pr checks --watch"
expect pass "$FEAT" "gh repo view --json visibility"

finish
