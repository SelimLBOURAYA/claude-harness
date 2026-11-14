#!/usr/bin/env bash
# The `lot-start confirm N` hand-off, which ends lot-start's Part A without
# being a question (lot 29), split from the lot 29 suite by lot 37; its fakes
# and fixture live in tests/autopilot-lib.sh.
. "$(dirname "$0")/autopilot-lib.sh"

# --- the confirmation hand-off is not a question (lot 29) -----------------
R=$(fixture confirmation harness)
echo blocked > "$R.scen/start.status"
echo '["Lot candidat : 5 — confirmer avec `lot-start confirm 5`"]' > "$R.scen/start.questions"
assert_eq 0 "$(pilot "$R")" "a confirmation hand-off is the normal end of lot-start"
assert_eq "start dev test review audit ship " "$(calls "$R")" \
  "the confirmation follows the hand-off"
assert_contains "$(grep '^dev ' "$R.scen/calls.log")" "prompt=lot-start confirm 5" \
  "the autopilot sends the confirmation itself"

R=$(fixture confirmationanswer harness)
echo blocked > "$R.scen/start.status"
echo '["Which lot?"]' > "$R.scen/start.questions"
assert_eq 1 "$(pilot "$R")" "a blocked lot-start stops the run"
rm "$R.scen/start.questions"
echo blocked > "$R.scen/answer.status"
echo '["Lot candidat : 5 — confirmer avec `lot-start confirm 5`"]' > "$R.scen/answer.questions"
: > "$R.scen/calls.log"
assert_eq 0 "$(pilot "$R" --resume --answer "Lot 5")" \
  "a confirmation hand-off on the answered session is no question either"
assert_eq "answer dev test review audit ship " "$(calls "$R")" \
  "the confirmation follows the answered hand-off"
assert_contains "$(grep '^dev ' "$R.scen/calls.log")" "prompt=lot-start confirm 5" \
  "the confirmation follows the answers"

R=$(fixture confirmationother harness)
echo blocked > "$R.scen/start.status"
echo '["Which branch?", "Lot candidat : 5 — confirmer avec `lot-start confirm 5`"]' > "$R.scen/start.questions"
assert_eq 1 "$(pilot "$R")" "another question still stops the run"
assert_eq "start " "$(calls "$R")" "no confirmation while another question remains"
assert_eq '["Which branch?"]' "$(jq -c '.questions' "$R/.claude/autopilot-state.json")" \
  "only the other question is kept in the state"
assert_contains "$(cat "$R.out")" "  1. Which branch?" "the other question is shown"

R=$(fixture confirmationchoice harness)
echo blocked > "$R.scen/start.status"
printf '%s\n' '["Lot 5 ou 6 ?\n a) lot-start confirm 5\n b) lot-start confirm 6"]' > "$R.scen/start.questions"
assert_eq 1 "$(pilot "$R")" "a choice between two confirmations is a real question"
assert_eq "start " "$(calls "$R")" "no confirmation while the owner has not chosen the lot"
assert_contains "$(state "$R" questions)" "Lot 5 ou 6" "the choice is kept in the state"

R=$(fixture confirmationotherlot harness)
echo blocked > "$R.scen/start.status"
echo '["Lot candidat : 6 — confirmer avec `lot-start confirm 6`"]' > "$R.scen/start.questions"
assert_eq 1 "$(pilot "$R")" "a hand-off naming another lot than the answered one stops the run"
assert_eq "start " "$(calls "$R")" "no confirmation on a hand-off for another lot"

R=$(fixture confirmationnone harness)
echo blocked > "$R.scen/start.status"
assert_eq 1 "$(pilot "$R")" "a blocked lot-start without questions still stops"
assert_eq "start " "$(calls "$R")" "no confirmation without any question"

R=$(fixture confirmationslash harness)
echo blocked > "$R.scen/start.status"
echo '["Lot 5 : /claude-harness:lot-start confirm 5"]' > "$R.scen/start.questions"
assert_eq 0 "$(pilot "$R")" "the slash form of the hand-off is no question either"
assert_contains "$(grep '^dev ' "$R.scen/calls.log")" "prompt=lot-start confirm 5" \
  "the autopilot sends the confirmation itself after a dropped slash form"

R=$(fixture confirmationbranch harness)
echo blocked > "$R.scen/start.status"
echo '["Lot candidat : 5 — confirmer avec `lot-start confirm 5`"]' > "$R.scen/start.questions"
cat >> "$R.scen/start.sh" <<'EOF'
git switch -q -c feat/lot-6-z
EOF
assert_eq 1 "$(pilot "$R")" "a dropped confirmation does not skip the branch check"
assert_eq "start " "$(calls "$R")" "no confirmation on a branch outside the lot"
assert_contains "$(state "$R" reason)" "is not feat/lot-5-" \
  "the branch check still runs after the hand-off is dropped"

R=$(fixture confirmationsync harness)
echo blocked > "$R.scen/start.status"
echo '["Lot candidat : 5 — confirmer avec `lot-start confirm 5`"]' > "$R.scen/start.questions"
cat >> "$R.scen/start.sh" <<'EOF'
sed -i 's/| 6 | `feat\/lot-6-y` | ⬜ |/| 6 | `feat\/lot-6-y` | ✅ |/' lots.md
EOF
assert_eq 1 "$(pilot "$R")" "a dropped confirmation does not skip sync-status.py"
assert_eq "start " "$(calls "$R")" "no confirmation when sync-status.py rejects the hand-off"
assert_contains "$(state "$R" reason)" "sync-status.py exited 3" \
  "sync-status.py still runs after the hand-off is dropped"

R=$(fixture confirmationdev harness)
echo blocked > "$R.scen/dev.status"
echo '["Lot candidat : 5 — confirmer avec `lot-start confirm 5`"]' > "$R.scen/dev.questions"
assert_eq 1 "$(pilot "$R")" "the development still stops on a confirmation question"
assert_eq "start dev " "$(calls "$R")" "no lot-test after a blocked development"
assert_eq blocked "$(state "$R" status)" "the development stop stays blocked"
assert_eq dev "$(state "$R" resume)" "the development stop resumes at the development"

R=$(fixture confirmationok harness)
echo '["Lot candidat : 5 — confirmer avec `lot-start confirm 5`"]' > "$R.scen/start.questions"
assert_eq 0 "$(pilot "$R")" "an ok lot-start that lists the hand-off as a question goes on"
assert_eq "start dev test review audit ship " "$(calls "$R")" \
  "the confirmation follows an ok answer whose only question was the hand-off"

R=$(fixture confirmationfailed harness)
echo failed > "$R.scen/start.status"
echo '["Lot candidat : 5 — confirmer avec `lot-start confirm 5`"]' > "$R.scen/start.questions"
assert_eq 1 "$(pilot "$R")" "a failed lot-start stops the run even when its only question is the hand-off"
assert_eq "start " "$(calls "$R")" "no confirmation after a failed lot-start"
assert_eq failed "$(state "$R" status)" "only a blocked answer turns ok, a failed one stays failed"

R=$(fixture confirmationanswerother harness)
echo blocked > "$R.scen/start.status"
echo '["Which lot?"]' > "$R.scen/start.questions"
assert_eq 1 "$(pilot "$R")" "a blocked lot-start stops the run"
rm "$R.scen/start.questions"
echo blocked > "$R.scen/answer.status"
echo '["Which branch?", "Lot candidat : 5 — confirmer avec `lot-start confirm 5`"]' \
  > "$R.scen/answer.questions"
: > "$R.scen/calls.log"
assert_eq 1 "$(pilot "$R" --resume --answer "Lot 5")" \
  "another question after the answer still stops the run"
assert_eq "answer " "$(calls "$R")" "no confirmation while another question remains after the answer"
assert_eq '["Which branch?"]' "$(jq -c '.questions' "$R/.claude/autopilot-state.json")" \
  "only the other question is kept after the answer"
assert_eq blocked "$(state "$R" status)" "the answered stop stays blocked"

finish
