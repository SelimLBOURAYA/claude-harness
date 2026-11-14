#!/usr/bin/env bash
# The autopilot's dry run (lot 29), split from the lot 29 suite by lot 37; its
# fakes and fixture live in tests/autopilot-lib.sh.
. "$(dirname "$0")/autopilot-lib.sh"

# --- dry run --------------------------------------------------------------
R=$(fixture dry harness)
out=$(cd "$R" && PATH="$FAKEBIN:$PATH" HOME="$FAKEHOME" python3 "$PILOT" --dry-run)
assert_contains "$out" "review Opus" "--dry-run shows the model of each step"
assert_eq "" "$(grep '^integration ' <<< "$out" || true)" \
  "a stack without Integration command lists no integration step"
assert_eq "" "$(calls "$R")" "--dry-run runs no session"
assert_contains "$out" "Bash(printenv ANTHROPIC_BASE_URL)" \
  "the allowlist lets lot-review run its profile guard"
assert_contains "$out" "Bash(printenv HARNESS_AUTOPILOT)" \
  "the allowlist lets lot-review and lot-audit read HARNESS_AUTOPILOT"
# Lot 30: lot-start Step A0 updates the plugin, exact command, no wildcard.
assert_contains "$out" "Bash(claude plugin update claude-harness@claude-harness --scope project --json)" \
  "the allowlist lets lot-start update the plugin at project scope"
assert_eq 1 "$(grep -o 'Bash(claude [^)]*)' <<< "$out" | sort -u | wc -l | tr -d ' ')" \
  "the allowlist names no other claude command"
# Lot 33: the skeleton's permission rules go per process, its ask rules as
# denials, since a headless session has nobody to ask.
rules=$(jq -r '.permissions.deny + .permissions.ask | join(",")' "$REPO_ROOT/templates/project/.claude/settings.json")
assert_contains "$out" "--disallowedTools $rules " \
  "--dry-run passes the skeleton's deny and ask rules as --disallowedTools"
out=$(cd "$R" && PATH="$FAKEBIN:$PATH" HOME="$FAKEHOME" python3 "$PILOT" --dry-run 5)
assert_contains "$out" 'The `lot-start confirm N` hand-off' \
  "--dry-run shows the confirmation hand-off in the system prompt"
assert_contains "$out" "one entry per question, in French, each option of a question on its own line" \
  "--dry-run shows the questions' language and layout in the system prompt"
assert_contains "$out" "/claude-harness:lot-start 5" "--dry-run N shows the named lot-start prompt"
assert_eq "" "$(calls "$R")" "--dry-run N runs no session"
assert_ok "the script leaves no __pycache__ in the plugin" -- \
  test ! -e "$REPO_ROOT/plugins/claude-harness/hooks/__pycache__"

finish
