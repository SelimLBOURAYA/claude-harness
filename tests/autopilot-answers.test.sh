#!/usr/bin/env bash
# The named lot and the owner's answers to a blocked session (lot 28), split
# from the lot 29 suite by lot 37; its fakes and fixture live in
# tests/autopilot-lib.sh.
. "$(dirname "$0")/autopilot-lib.sh"

# --- N: lot-start is named the lot (lot 28) -------------------------------
R=$(fixture namedlot harness)
assert_eq 0 "$(pilot "$R" 5)" "a named lot runs that lot"
assert_contains "$(cat "$R.scen/calls.log")" "prompt=/claude-harness:lot-start 5" \
  "the named lot is in the lot-start prompt"

R=$(fixture wronglot harness)
echo 6 > "$R.scen/start.lot"
assert_eq 1 "$(pilot "$R" 5)" "an answer naming another lot stops the run"
assert_eq "start " "$(calls "$R")" "no confirmation when lot-start names another lot"
assert_contains "$(state "$R" reason)" "not the required 5" "the reason names the required lot"

R=$(fixture badargs harness)
assert_eq 2 "$(pilot "$R" 5.x)" "a value that is no lot ID is refused"
assert_eq 2 "$(pilot "$R" "")" "an empty lot is refused"
assert_eq 2 "$(pilot "$R" --resume --answer "  ")" "--answer refuses a blank text"
assert_eq "" "$(calls "$R")" "no session on a refused lot"
assert_eq 2 "$(pilot "$R" 5 --resume)" "a lot and --resume are exclusive"
assert_eq 2 "$(pilot "$R" --answer x)" "--answer needs --resume"

# --- --resume --answer: the stopped session gets the answers (lot 28) -----
R=$(fixture answer harness)
echo blocked > "$R.scen/start.status"
echo '["Which lot?", "Which branch?"]' > "$R.scen/start.questions"
assert_eq 1 "$(pilot "$R")" "a blocked lot-start stops the run"
assert_eq blocked "$(state "$R" status)" "the state records the blocked status"
assert_contains "$(jq -r '.questions | join("; ")' "$R/.claude/autopilot-state.json")" \
  "Which lot?" "the state records the questions"
: > "$R.scen/calls.log"
rm "$R.scen/start.questions"
assert_eq 0 "$(pilot "$R" --resume --answer "Lot 5, branch feat/lot-5-x")" \
  "--resume --answer finishes the lot"
assert_eq "answer dev test review audit ship " "$(calls "$R")" \
  "the answers replace the start session, then the confirmation"
assert_contains "$(grep '^answer ' "$R.scen/calls.log")" "--resume S-start" \
  "the stopped session is resumed"
assert_contains "$(grep '^answer ' "$R.scen/calls.log")" "Owner answers to your questions:" \
  "the answers come with the fixed line"
assert_contains "$(grep '^answer ' "$R.scen/calls.log")" "Lot 5, branch feat/lot-5-x" \
  "the owner's answers are in the prompt"
assert_contains "$(grep '^dev ' "$R.scen/calls.log")" "prompt=lot-start confirm 5" \
  "the confirmation follows the checks"

R=$(fixture answerlot harness)
echo blocked > "$R.scen/start.status"
echo '["Which lot?"]' > "$R.scen/start.questions"
assert_eq 1 "$(pilot "$R" 5)" "a blocked named lot stops the run"
rm "$R.scen/start.questions"
echo 6 > "$R.scen/answer.lot"
: > "$R.scen/calls.log"
assert_eq 1 "$(pilot "$R" --resume --answer "lot 6")" \
  "the answered lot must still be the named one"
assert_contains "$(state "$R" reason)" "not the required 5" "the named lot check survives the answer"
assert_eq "answer " "$(calls "$R")" "no confirmation after an answered lot that is not the named one"

R=$(fixture answerdev harness)
echo blocked > "$R.scen/dev.status"
assert_eq 1 "$(pilot "$R")" "a blocked development stops the run"
assert_eq dev "$(state "$R" resume)" "the stop resumes at the development"
assert_eq blocked "$(state "$R" status)" "the state records the blocked status"
: > "$R.scen/calls.log"
assert_eq 0 "$(pilot "$R" --resume --answer "Use the narrow fix")" \
  "--resume --answer completes a blocked development"
assert_eq "answer test review audit ship " "$(calls "$R")" \
  "the answered development is not run again"
assert_contains "$(grep '^answer ' "$R.scen/calls.log")" "--resume S-start" \
  "the stopped development session is resumed"

R=$(fixture answerok harness)
echo '["Which branch?"]' > "$R.scen/start.questions"
assert_eq 1 "$(pilot "$R")" "an ok lot-start that lists questions stops the run"
assert_eq blocked "$(state "$R" status)" "questions make the stop blocked whatever the status"
assert_contains "$(tail -1 "$R.out")" "--resume --answer" "the stop advertises --answer"
rm "$R.scen/start.questions"
: > "$R.scen/calls.log"
assert_eq 0 "$(pilot "$R" --resume --answer "feat/lot-5-x")" \
  "--answer settles an ok lot-start that listed questions"

R=$(fixture answersilent harness)
echo blocked > "$R.scen/start.status"
echo '["Which branch?"]' > "$R.scen/start.questions"
assert_eq 1 "$(pilot "$R")" "a blocked lot-start stops the run"
rm "$R.scen/start.questions"
touch "$R.scen/answer.silent"
assert_eq 1 "$(pilot "$R" --resume --answer "feat/lot-5-x")" \
  "an answered session with no structured answer stops the run"
assert_eq blocked "$(state "$R" status)" "the stop stays blocked"
assert_eq start "$(state "$R" resume)" "the stop stays at start"
assert_contains "$(jq -r '.questions | join("; ")' "$R/.claude/autopilot-state.json")" \
  "Which branch?" "the stop keeps the questions"
rm "$R.scen/answer.silent"
: > "$R.scen/calls.log"
assert_eq 0 "$(pilot "$R" --resume --answer "feat/lot-5-x")" "the same answers can be sent again"
assert_contains "$(grep '^answer ' "$R.scen/calls.log")" "--resume S-start" \
  "the second answer reaches the stopped session"

# --- the lot-start checks still run on the answered session ----------------
R=$(fixture answersync harness)
echo blocked > "$R.scen/start.status"
assert_eq 1 "$(pilot "$R")" "a blocked lot-start without questions stops the run"
assert_contains "$(cat "$R.out")" "Questions: none" \
  "a blocked stop without questions says none"
cat > "$R.scen/answer.sh" <<'EOF'
sed -i 's/| 6 | `feat\/lot-6-y` | ⬜ |/| 6 | `feat\/lot-6-y` | ✅ |/' lots.md
EOF
: > "$R.scen/calls.log"
assert_eq 1 "$(pilot "$R" --resume --answer "lot 5")" \
  "a sync-status stop after the answer stops the run"
assert_eq "answer " "$(calls "$R")" "no confirmation when sync-status.py rejects the answer"
assert_contains "$(state "$R" reason)" "sync-status.py exited 3" \
  "sync-status.py runs on the answered session too"

R=$(fixture answerbranch harness)
echo blocked > "$R.scen/start.status"
assert_eq 1 "$(pilot "$R")" "a blocked lot-start stops the run"
cat > "$R.scen/answer.sh" <<'EOF'
git switch -q -c feat/lot-6-z
EOF
: > "$R.scen/calls.log"
assert_eq 1 "$(pilot "$R" --resume --answer "lot 5")" \
  "a branch outside the lot after the answer stops the run"
assert_contains "$(state "$R" reason)" "is not feat/lot-5-" \
  "the branch check runs on the answered session too"
assert_eq "answer " "$(calls "$R")" "no confirmation on a branch outside the lot"

R=$(fixture answeragain harness)
echo blocked > "$R.scen/start.status"
echo '["Which lot?"]' > "$R.scen/start.questions"
assert_eq 1 "$(pilot "$R")" "a blocked lot-start stops the run"
rm "$R.scen/start.questions"
echo '["Which branch?"]' > "$R.scen/answer.questions"
: > "$R.scen/calls.log"
assert_eq 1 "$(pilot "$R" --resume --answer "lot 5")" \
  "an answered session that still asks questions stops the run"
assert_eq "answer " "$(calls "$R")" "no confirmation while questions remain after the answer"
assert_contains "$(state "$R" questions)" "Which branch?" "the remaining questions are in the state"

finish
