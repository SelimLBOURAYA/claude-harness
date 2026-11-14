#!/usr/bin/env bash
# Where --answer and --resume cannot apply, and the stop message's layout (lot
# 29), split from the lot 29 suite by lot 37; its fakes and fixture live in
# tests/autopilot-lib.sh.
. "$(dirname "$0")/autopilot-lib.sh"

# --- --answer needs the stopped session in the state ----------------------
R=$(fixture answersession harness)
echo blocked > "$R.scen/start.status"
echo '["Which lot?"]' > "$R.scen/start.questions"
assert_eq 1 "$(pilot "$R")" "a blocked lot-start stops the run"
assert_eq "S-start" "$(state "$R" session_id)" "the stopped session is in the state"
jq 'del(.session_id)' "$R/.claude/autopilot-state.json" > "$R/state.tmp" \
  && mv "$R/state.tmp" "$R/.claude/autopilot-state.json"
: > "$R.scen/calls.log"
assert_eq 2 "$(pilot "$R" --resume --answer "lot 5")" \
  "--answer refuses a state without the stopped session"
assert_eq "" "$(calls "$R")" "no session when the stopped one is missing from the state"

# --- --resume without --answer after a blocked lot-start ------------------
R=$(fixture freshresume harness)
echo blocked > "$R.scen/start.status"
echo '["Which lot?"]' > "$R.scen/start.questions"
assert_eq 1 "$(pilot "$R")" "a blocked lot-start stops the run"
rm "$R.scen/start.status" "$R.scen/start.questions"
: > "$R.scen/calls.log"
assert_eq 0 "$(pilot "$R" --resume)" "--resume without --answer runs lot-start again"
assert_eq "start dev test review audit ship " "$(calls "$R")" \
  "the fresh lot-start opens the run"
assert_eq "" "$(grep '^start ' "$R.scen/calls.log" | grep -o -- '--resume' || true)" \
  "--resume without --answer opens a new session, never the stopped one"
assert_contains "$(grep '^start ' "$R.scen/calls.log")" "prompt=/claude-harness:lot-start" \
  "the fresh lot-start gets its own prompt, without the answers"

# --- --answer is refused wherever it cannot apply -------------------------
R=$(fixture answertest harness)
echo blocked > "$R.scen/test.status"
assert_eq 1 "$(pilot "$R")" "a blocked lot-test stops the run"
assert_eq 2 "$(pilot "$R" --resume --answer "anything")" \
  "--answer refuses a stop that is not a blocked start or development"

R=$(fixture answercheck harness)
echo 'echo dirty > src/dirty.txt' >> "$R.scen/dev.sh"
assert_eq 1 "$(pilot "$R")" "a dirty tree after the development stops the run"
assert_eq 2 "$(pilot "$R" --resume --answer "anything")" \
  "--answer refuses a failed check, not a blocked session"

R=$(fixture answerconfirm harness)
echo blocked > "$R.scen/start.status"
echo '["Which lot?"]' > "$R.scen/start.questions"
assert_eq 1 "$(pilot "$R")"
assert_eq 2 "$(pilot "$R" --resume --answer "lot-start confirm 5")" \
  "--answer refuses a bare confirmation"
assert_eq 2 "$(pilot "$R" --resume --answer "/claude-harness:lot-start confirm 5")" \
  "--answer refuses the slash confirmation"
assert_eq 2 "$(pilot "$R" --resume --answer "  lot-start confirm 5  ")" \
  "--answer refuses a padded confirmation"
assert_eq 2 "$(pilot "$R" --resume --answer "lot-start confirm 5.1")" \
  "--answer refuses a sub-lot confirmation"

# --- the stop message carries the questions and the command ---------------
R=$(fixture stopline harness)
echo blocked > "$R.scen/start.status"
echo '["Which lot?"]' > "$R.scen/start.questions"
assert_eq 1 "$(pilot "$R")"
assert_contains "$(cat "$R.out")" "  1. Which lot?" "the message lists the questions"
assert_contains "$(tail -1 "$R.out")" "--resume --answer" "the last line gives the command"
assert_contains "$(cat "$R.scen/notify.log")" "Which lot?" "the notification lists the questions"
assert_contains "$(cat "$R.scen/notify.log")" "--resume --answer" "the notification gives the command"

R=$(fixture nohint harness)
echo 'echo dirty > src/dirty.txt' >> "$R.scen/dev.sh"
assert_eq 1 "$(pilot "$R")"
assert_eq "" "$(grep -o -- '--resume --answer' "$R.out" || true)" \
  "a stop that --answer cannot settle does not advertise it"

finish
