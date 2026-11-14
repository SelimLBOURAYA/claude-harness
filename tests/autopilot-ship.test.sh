#!/usr/bin/env bash
# The autopilot's merge check, its refusal outside a harnessed repository and
# the step timeout (lot 29), split from the lot 29 suite by lot 37; its fakes
# and fixture live in tests/autopilot-lib.sh.
. "$(dirname "$0")/autopilot-lib.sh"

# --- the merge, checked by the script -------------------------------------
R=$(fixture notmerged harness)
: > "$R.scen/ship.sh"
assert_eq 1 "$(FAKE_GH_STATE=OPEN pilot "$R")" "a pull request left open stops the run"
assert_contains "$(state "$R" reason)" "OPEN" "the reason gives the pull request state"
assert_ok "the lock stays while the pull request is not merged" -- test -e "$R/.claude/current-lot"
assert_eq ship "$(state "$R" resume)" "the stop resumes at lot-ship"

# The headless ship session cannot remove a file under .claude/: the autopilot
# does it once the pull request is merged (lot 35).
R=$(fixture locked harness)
: > "$R.scen/ship.sh"
assert_eq 0 "$(pilot "$R")" "the autopilot removes the lock left after lot-ship"
assert_ok "and the lock is gone" -- test ! -e "$R/.claude/current-lot"

# A removal that fails is a recorded stop, not a traceback: the run resumes at
# lot-ship once the owner has cleared the lock (lot 35).
R=$(fixture unremovable harness)
cat > "$R.scen/ship.sh" <<'EOF'
rm -f .claude/current-lot
mkdir .claude/current-lot
EOF
assert_eq 1 "$(pilot "$R")" "a lock that cannot be removed stops the run"
assert_contains "$(state "$R" reason)" "cannot remove the lot lock" "the reason says the lock cannot be removed"
assert_eq ship "$(state "$R" resume)" "the stop resumes at lot-ship"

# --- outside a harnessed repository ---------------------------------------
mkdir -p "$WORK/plain" && git -C "$WORK/plain" init -q
code=$(cd "$WORK/plain" && PATH="$FAKEBIN:$PATH" HOME="$FAKEHOME" python3 "$PILOT" >/dev/null 2>&1; echo $?)
assert_eq 2 "$code" "refuses to start outside a harnessed repository"

# --- a step over its timeout ----------------------------------------------
R=$(fixture slow harness)
echo 10 > "$R.scen/start.sleep"
began=$(date +%s)
code=$(cd "$R" && SCEN="$R.scen" PATH="$FAKEBIN:$PATH" HOME="$FAKEHOME" AUTOPILOT_STEP_TIMEOUT=1 \
  python3 "$PILOT" > "$R.out" 2>&1; echo $?)
assert_eq 1 "$code" "a step over its timeout stops the run"
assert_ok "the session is killed at the timeout" -- test $(( $(date +%s) - began )) -lt 8
assert_contains "$(state "$R" reason)" "timeout" "the timeout is recorded"
assert_eq start "$(state "$R" resume)" "the timed-out step is the one resumed"

finish
