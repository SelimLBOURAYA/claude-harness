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

# --- the targeted test form of each Stack (lot 37) -------------------------
# harness: one exact entry per suite present at the launch, relative and
# absolute, never a wildcard.
R=$(fixture stackharness harness)
mkdir -p "$R/tests"
printf 'exit 0\n' > "$R/tests/probe.test.sh"
printf 'exit 0\n' > "$R/tests/other.test.sh"
printf 'exit 0\n' > "$R/tests/helper.sh"
out=$(cd "$R" && PATH="$FAKEBIN:$PATH" HOME="$FAKEHOME" python3 "$PILOT" --dry-run)
assert_contains "$out" "Bash(bash tests/probe.test.sh)" "a harness session may run one suite"
assert_contains "$out" "Bash(bash $R/tests/probe.test.sh)" "and the same suite by absolute path"
assert_contains "$out" "Bash(bash tests/other.test.sh)" "every suite present at the launch is listed"
assert_eq "" "$(grep -o 'Bash(bash tests/\*)' <<< "$out" || true)" \
  "no wildcard covers the harness suites"
assert_eq "" "$(grep -o 'helper[.]sh' <<< "$out" || true)" \
  "a sourced helper is not a suite"
assert_contains "$out" "bash tests/<suite>.test.sh" "the command hint cites the harness form"
assert_contains "$out" "A file outside the repository is read with the Read tool" \
  "the hint sends an out-of-repo file to the Read tool"
assert_contains "$out" "No binary that launches another command" \
  "the hint forbids a command that launches another"
assert_contains "$out" "A denied command is not retried in another form" \
  "the hint forbids retrying a denied command in another form"

# A harness project without a tests directory lists no suite and does not crash.
R=$(fixture stackempty harness)
out=$(cd "$R" && PATH="$FAKEBIN:$PATH" HOME="$FAKEHOME" python3 "$PILOT" --dry-run)
assert_eq 0 "$?" "a harness project without tests/ still starts"
assert_eq "" "$(grep -o 'Bash(bash' <<< "$out" || true)" \
  "and gets no targeted test entry"

R=$(fixture stackbackend backend)
out=$(cd "$R" && PATH="$FAKEBIN:$PATH" HOME="$FAKEHOME" python3 "$PILOT" --dry-run)
assert_contains "$out" "Bash(./mvnw test -Dtest=*)" "a backend session may run one test class"
assert_contains "$out" "./mvnw test -Dtest=<Class>" "the command hint cites the backend form"

R=$(fixture stackfrontend frontend)
out=$(cd "$R" && PATH="$FAKEBIN:$PATH" HOME="$FAKEHOME" python3 "$PILOT" --dry-run)
assert_contains "$out" "Bash(npm test -- *)" "a frontend session may filter its tests"
assert_contains "$out" "npm test -- <filter>" "the command hint cites the frontend form"

R=$(fixture stackother other)
out=$(cd "$R" && PATH="$FAKEBIN:$PATH" HOME="$FAKEHOME" python3 "$PILOT" --dry-run)
assert_eq "" "$(grep -oE 'Bash\((\./mvnw test|npm test --|bash tests/)' <<< "$out" || true)" \
  "another Stack gets no targeted test entry"
assert_contains "$out" "this Stack has no targeted form" "the command hint says so"

# One hint per step, inside each step's command.
R=$(fixture hints harness)
out=$(cd "$R" && PATH="$FAKEBIN:$PATH" HOME="$FAKEHOME" python3 "$PILOT" --dry-run)
steps=$(grep -cE '^(start|dev|test|fix|review|audit|ship) ' <<< "$out")
assert_eq "$steps" "$(grep -o 'One simple command per Bash call' <<< "$out" | wc -l | tr -d ' ')" \
  "each step's command carries the command hint"

finish
