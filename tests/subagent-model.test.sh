#!/usr/bin/env bash
# The PostToolUse hook that shows the user a subagent's model (lot 40).
set -uo pipefail
. "$(dirname "$0")/lib.sh"

HOOK="$REPO_ROOT/plugins/claude-harness/hooks/subagent-model.py"

# run <payload> [CLAUDE_CODE_SUBAGENT_MODEL]
run() { printf '%s' "$1" | env -u CLAUDE_CODE_SUBAGENT_MODEL ${2:+CLAUDE_CODE_SUBAGENT_MODEL=$2} python3 "$HOOK"; }
msg() { printf '%s' "$1" | jq -r '.systemMessage'; }

# The model that answered, from the PostToolUse input.
out=$(run '{"hook_event_name":"PostToolUse","tool_name":"Agent","tool_input":{"subagent_type":"Explore","description":"x"},"tool_response":{"agentType":"Explore","resolvedModel":"claude-haiku-5-5"}}' claude-sonnet-5-5)
assert_eq "sous-agent Explore → claude-haiku-5-5" "$(msg "$out")" "the systemMessage names the model that answered"
assert_eq "" "$(printf '%s' "$out" | jq -r '.. | .additionalContext? // empty')" "never an additionalContext"
assert_eq "systemMessage" "$(printf '%s' "$out" | jq -r 'keys | join(",")')" "the systemMessage is the whole output"

# No answering model: the configured one, marked as such.
out=$(run '{"tool_name":"Agent","tool_input":{"subagent_type":"general-purpose"},"tool_response":{"status":"async_launched"}}' claude-haiku-5-5)
assert_eq "sous-agent general-purpose → claude-haiku-5-5 (configuré)" "$(msg "$out")" \
  "without resolvedModel, CLAUDE_CODE_SUBAGENT_MODEL is shown, marked configured"
out=$(run '{"tool_name":"Agent","tool_input":{"subagent_type":"Plan","model":"opus"}}' claude-haiku-5-5)
assert_eq "sous-agent Plan → opus (configuré)" "$(msg "$out")" "the Agent call's own model wins over the variable"
out=$(run '{"tool_name":"Task","tool_input":{}}')
assert_eq "sous-agent general-purpose → modèle de la session (configuré)" "$(msg "$out")" \
  "nothing configured: the session's model, marked configured"

# Never blocking.
out=$(printf 'garbage' | python3 "$HOOK"); rc=$?
assert_eq 0 "$rc" "an unreadable input exits 0"
assert_eq "" "$out" "and prints nothing"
assert_eq "" "$(run '{"tool_name":"Bash","tool_input":{"command":"ls"}}')" "another tool: nothing"
assert_ok "the hook leaves no __pycache__" -- test ! -e "$REPO_ROOT/plugins/claude-harness/hooks/__pycache__"

finish
