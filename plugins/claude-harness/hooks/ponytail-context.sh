#!/usr/bin/env bash
# SessionStart hook (startup, resume, clear, compact): injects the body of the
# ponytail skill, the smallest complete change (CODE-6), into every session and
# under every profile, as additionalContext (lot 33).
#
# Loading the skill is not left to the model: the development, the autopilot's
# fix step, lot-test, lot-review and lot-audit each open a session, so each one
# gets the text, and a compaction gets it back.
#
# A hook of its own rather than a section of session-context.sh: Claude Code
# caps the context of each hook at 10,000 characters, and replaces a longer one
# with a file path and a preview. The text keeps its own budget, PONYTAIL_CAP,
# and the state and the deepseek card keep theirs.
#
# Never blocks: a missing skill file yields no output, and the hook exits 0.
set -uo pipefail

PONYTAIL_CAP=4000
here=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
skill="$here/../skills/ponytail/SKILL.md"

cat > /dev/null
[ -f "$skill" ] || exit 0

# The body: what follows the closing --- of the frontmatter, leading blank lines dropped.
body=$(awk 'n >= 2 { print; next } /^---$/ { n++ }' "$skill" | sed '/./,$!d')
[ -n "$body" ] || exit 0
if [ "${#body}" -gt "$PONYTAIL_CAP" ]; then
  body="${body:0:$PONYTAIL_CAP}"$'\n'"[truncated at $PONYTAIL_CAP characters: read skills/ponytail/SKILL.md]"
fi

jq -nc --arg c "$body" \
  '{hookSpecificOutput: {hookEventName: "SessionStart", additionalContext: $c}}'
