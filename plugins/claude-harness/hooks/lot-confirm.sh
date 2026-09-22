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
# <N> may be a sub-lot, `3.3`: sub-lots share the flat branch of their parent,
# and the table carries one row per lot, so the row to find is `3`.
# A prompt that merely contains the phrase, such as pasted text, is not a
# confirmation and is left alone.
#
# Refused, with the prompt blocked and the reason shown to the user:
#   - <N> is not a row of the status table of the lots file, nor a sub-lot of
#     one;
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

# The lot as the branch names it: a sub-lot (3.3) rides the branch of its
# parent (feat/lot-3-*), and the table carries the parent's row.
base=${lot%%.*}

if ! python3 "$here/lotfile.py" has-lot "$root" "$lot"; then
  # Sub-lot ids are the case worth spelling out: `confirm 3.3` is accepted when
  # the table carries a row 3, so a refusal here means that row is missing, and
  # repeating the whole id would not say which row to look for.
  hint=""
  [ "$base" = "$lot" ] || hint=" A sub-lot is confirmed on its parent row: the status table carries no row \`$base\`."
  block "lot-start confirm: lot $lot is not a row of the status table of the lots file in $root; no lock written. Check the lot ID that lot-start proposed.${hint}"
fi

branch=$(git -C "$root" rev-parse --abbrev-ref HEAD 2>/dev/null || true)
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
