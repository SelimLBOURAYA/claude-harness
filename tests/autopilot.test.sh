#!/usr/bin/env bash
# The autopilot's run lifecycle (lots 27 to 29): one session per step, the fake
# `claude` returning prepared statuses, the fixture a real repository with a
# bare origin. Split from the lot 29 suite by lot 37; its fakes and fixture live
# in tests/autopilot-lib.sh.
. "$(dirname "$0")/autopilot-lib.sh"

# --- the whole lot, then a stop after the merge ---------------------------
R=$(fixture happy harness)
assert_eq 0 "$(pilot "$R")" "a lot runs to its merge"
assert_eq "start dev test review audit ship " "$(calls "$R")" \
  "one session per step, and none after the merge"
assert_contains "$(cat "$R.scen/calls.log")" "Bash(python3 $FAKEHOME/.claude/plugins/cache/claude-harness/*)" \
  "python3 is allowed on the plugin's scripts"
assert_eq 0 "$(grep -cF 'Bash(python3 *)' "$R.scen/calls.log")" \
  "python3 is never allowed on any argument"
log="$R.scen/calls.log"
for step in start dev test ship; do
  assert_contains "$(grep "^$step " "$log")" "settings.deepseek.json" "$step runs on the deepseek settings"
  assert_eq "" "$(grep "^$step " "$log" | grep -o -- '--model' || true)" "$step passes no Claude model"
done
assert_contains "$(grep '^dev ' "$log")" "prompt=lot-start confirm 5" "the confirmation is the exact prompt"
assert_contains "$(grep '^dev ' "$log")" "--resume S-start" "the development resumes the lot-start session"
assert_contains "$(grep '^review ' "$log")" "--model claude-opus-5-5" "lot-review runs on Opus"
assert_contains "$(grep '^audit ' "$log")" "--model claude-opus-5-5" "lot-audit runs on Opus"
for step in review audit; do
  assert_contains "$(grep "^$step " "$log")" "settings.claude.json" "$step runs on the claude settings, never deepseek"
done
assert_contains "$(grep '^review ' "$log")" "autopilot=1" "HARNESS_AUTOPILOT=1 reaches lot-review"
assert_contains "$(grep '^audit ' "$log")" "autopilot=1" "HARNESS_AUTOPILOT=1 reaches lot-audit"
assert_eq "" "$(grep -c -- '--dangerously-skip-permissions' "$log" | grep -v '^0$')" \
  "permissions are never skipped"
assert_ok "the state file is removed after the merge" -- test ! -e "$R/.claude/autopilot-state.json"
assert_contains "$(cat "$R.scen/notify.log")" "Lot 5 merged" "the merge is notified"
assert_contains "$(cat "$R.out")" "1 fixed, 1 ignored, 0 deferred" "the summary counts the findings"
review_logs=("$FAKEHOME/.claude/autopilot/happy/"*lot-5-review.jsonl)
assert_ok "each step has its own log" -- test -e "${review_logs[0]}"

# --- the Stack's targeted test form reaches a real session (lot 37) -------
# The dry run proves the table; this proves the command a session actually runs.
R=$(fixture targeted harness)
mkdir -p "$R/tests"
printf 'exit 0\n' > "$R/tests/probe.test.sh"
git -C "$R" add tests
git -C "$R" commit -qm "chore: seed a suite"
git -C "$R" push -q origin develop
assert_eq 0 "$(pilot "$R")" "a harness lot runs with its targeted suite present"
assert_contains "$(grep '^dev ' "$R.scen/calls.log")" "Bash(bash tests/probe.test.sh)" \
  "the session's allowlist carries the suite present at its launch"
assert_contains "$(grep '^dev ' "$R.scen/calls.log")" \
  "A file outside the repository is read with the Read tool" \
  "the session's system prompt carries the command hint"

# --- no confirmation on questions -----------------------------------------
R=$(fixture questions harness)
echo '["Which lot?"]' > "$R.scen/start.questions"
assert_eq 1 "$(pilot "$R")" "questions stop the run"
assert_eq "start " "$(calls "$R")" "no confirmation when questions is not empty"
assert_eq start "$(state "$R" resume)" "the stop resumes at lot-start"
assert_contains "$(state "$R" questions)" "Which lot?" "the questions are in the state"
assert_contains "$(cat "$R.scen/notify.log")" "stopped" "the stop is notified"
assert_ok "the state file is ignored by git" -- git -C "$R" check-ignore -q .claude/autopilot-state.json

# --- no confirmation when sync-status.py stops ----------------------------
R=$(fixture syncstop harness)
cat >> "$R.scen/start.sh" <<'EOF'
sed -i 's/| 6 | `feat\/lot-6-y` | ⬜ |/| 6 | `feat\/lot-6-y` | ✅ |/' lots.md
EOF
assert_eq 1 "$(pilot "$R")" "a sync-status stop stops the run"
assert_eq "start " "$(calls "$R")" "no confirmation when sync-status.py exits 3"
assert_contains "$(state "$R" reason)" "sync-status.py exited 3" "the reason names sync-status"

# --- no confirmation on a lot that is no lot ID ---------------------------
R=$(fixture badlot harness)
echo '5.x/../../escape' > "$R.scen/start.lot"
assert_eq 1 "$(pilot "$R")" "a malformed lot stops the run"
assert_eq "start " "$(calls "$R")" "no confirmation on a lot that is no lot ID"
assert_contains "$(state "$R" reason)" "is not a lot ID" "the reason names the lot ID"

# --- a profile left on deepseek -------------------------------------------
R=$(fixture profile harness)
mkdir -p "$WORK/badhome/.claude"
echo '{"env":{"ANTHROPIC_BASE_URL":"https://api.deepseek.com/anthropic"}}' > "$WORK/badhome/.claude/settings.json"
code=$(cd "$R" && SCEN="$R.scen" PATH="$FAKEBIN:$PATH" HOME="$WORK/badhome" python3 "$PILOT" > "$R.out" 2>&1; echo $?)
assert_eq 2 "$code" "refuses to start under a settings.json carrying ANTHROPIC_BASE_URL"
assert_eq "" "$(calls "$R")" "no session under the deepseek profile"
# Lot 33: the native API URL, as the desktop app sets it, is the claude profile.
mkdir -p "$WORK/nativehome/.claude"
echo '{"env":{"ANTHROPIC_BASE_URL":"https://api.anthropic.com"}}' > "$WORK/nativehome/.claude/settings.json"
code=$(cd "$R" && SCEN="$R.scen" PATH="$FAKEBIN:$PATH" HOME="$WORK/nativehome" python3 "$PILOT" --dry-run > "$R.out" 2>&1; echo $?)
assert_eq 0 "$code" "starts under ANTHROPIC_BASE_URL=https://api.anthropic.com, the native API"
code=$(cd "$R" && SCEN="$R.scen" PATH="$FAKEBIN:$PATH" HOME="$WORK/nativehome" \
  ANTHROPIC_BASE_URL=https://api.deepseek.com/anthropic python3 "$PILOT" --dry-run > "$R.out" 2>&1; echo $?)
assert_eq 2 "$code" "refuses to start under a deepseek ANTHROPIC_BASE_URL in the environment"

# --- one fix iteration only -----------------------------------------------
R=$(fixture fixonce harness)
printf 'failed\nfailed\n' > "$R.scen/test.status"
assert_eq 1 "$(pilot "$R")" "a second lot-test failure stops the run"
assert_eq "start dev test fix test " "$(calls "$R")" "one fix session, then lot-test again"
assert_contains "$(grep '^fix ' "$R.scen/calls.log")" "settings.deepseek.json" "the fix runs on the deepseek settings"
assert_eq test "$(state "$R" resume)" "the stop resumes at lot-test"

R=$(fixture fixok harness)
printf 'failed\nok\n' > "$R.scen/test.status"
assert_eq 0 "$(pilot "$R")" "a fixed bug lets the lot go on"
assert_eq "start dev test fix test review audit ship " "$(calls "$R")" "the run goes on after the fix"

R=$(fixture fixfail harness)
echo failed > "$R.scen/test.status"
echo blocked > "$R.scen/fix.status"
assert_eq 1 "$(pilot "$R")" "a fix session that does not end ok stops the run"
assert_eq test "$(state "$R" resume)" "a stopped fix resumes at lot-test, a step of the sequence"
: > "$R.scen/calls.log"
echo ok > "$R.scen/test.status"
assert_eq 0 "$(pilot "$R" --resume)" "--resume after a stopped fix finishes the lot"
assert_eq "test review audit ship " "$(calls "$R")" "--resume reruns lot-test, no second fix"

# --- a rerun the same day never reads an earlier session's answer ----------
R=$(fixture stale harness)
cat > "$R.scen/dev.sh" <<'EOF'
mkdir -p .claude src && printf 'branch=feat/lot-5-x\n' > .claude/current-lot
echo a > src/a.txt && git add src && git commit -qm "feat(5): add a"
echo dirty > src/dirty.txt
EOF
assert_eq 1 "$(pilot "$R")" "a dirty tree after the development stops the run"
rm "$R/src/dirty.txt"
touch "$R.scen/dev.silent"
assert_eq 1 "$(pilot "$R" --resume)" "a rerun with no answer stops, whatever the earlier log holds"
assert_contains "$(state "$R" reason)" "no structured answer" "the earlier ok answer is not reused"

finish
