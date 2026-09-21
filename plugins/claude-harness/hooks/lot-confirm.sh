#!/usr/bin/env bash
# UserPromptSubmit hook: turns the user's lot confirmation into the lot lock.
#
# The lock `.claude/current-lot` is what lot-lock-guard.py requires before any
# write on a `feat/lot-N-*` branch. It is written here and nowhere else, because
# this hook only sees prompts the *user* submitted: the model cannot forge one,
# so the lock proves a human confirmed the lot.
#
# Accepted, as the whole prompt and nothing else (surrounding blanks aside):
#   lot-start confirm <N>
#   /claude-harness:lot-start confirm <N>
# A prompt that merely contains the phrase, such as pasted text, is not a
# confirmation and is left alone.
#
# Refused, with the prompt blocked and the reason shown to the user:
#   - <N> is not a row of the status table of the lots file;
#   - the checked-out branch is not `feat/lot-<N>-*` (lot-start creates it).
set -uo pipefail

here=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

payload=$(cat)
prompt=$(printf '%s' "$payload" | jq -r '.prompt // ""' 2>/dev/null) || exit 0
cwd=$(printf '%s' "$payload" | jq -r '.cwd // ""' 2>/dev/null) || exit 0
[ -n "$cwd" ] || cwd=$(pwd)

# Trim surrounding whitespace; the match is then anchored on the whole prompt.
prompt="${prompt#"${prompt%%[![:space:]]*}"}"
prompt="${prompt%"${prompt##*[![:space:]]}"}"
re='^(/claude-harness:)?lot-start confirm ([0-9]+[a-z]?(\.[0-9]+)?)$'
[[ "$prompt" =~ $re ]] || exit 0
lot="${BASH_REMATCH[2]}"

block() {
  jq -nc --arg r "$1" '{decision: "block", reason: $r}'
  exit 0
}

root=$(python3 "$here/lotfile.py" root "$cwd")
[ -n "$root" ] || block "lot-start confirm: $cwd is not inside a git repository; no lock written."

if ! python3 "$here/lotfile.py" has-lot "$root" "$lot"; then
  block "lot-start confirm: lot $lot is not a row of the status table of the lots file in $root; no lock written. Check the lot ID that lot-start proposed."
fi

branch=$(git -C "$root" rev-parse --abbrev-ref HEAD 2>/dev/null || true)
base=${lot%%.*}
case "$branch" in
  "feat/lot-$base-"*) ;;
  *) block "lot-start confirm: the checked-out branch is \`$branch\`, not \`feat/lot-$base-<slug>\`; no lock written. lot-start creates the branch from develop before asking for the confirmation." ;;
esac

mkdir -p "$root/.claude"
{
  printf 'lot=%s\n' "$lot"
  printf 'branch=%s\n' "$branch"
  printf 'confirmed=%s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
} > "$root/.claude/current-lot"

context="The user confirmed lot $lot on \`$branch\`; the lot lock .claude/current-lot is written. Next, per the lot-start skill: run its sync-status.py with --apply --start $lot, commit \`docs: sync lots file status\` only if the lots file changed, then implement strictly the scope of lot $lot."
jq -nc --arg c "$context" \
  '{hookSpecificOutput: {hookEventName: "UserPromptSubmit", additionalContext: $c}}'
