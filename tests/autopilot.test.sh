#!/usr/bin/env bash
# Exercises the autopilot (lot 27) against a fake `claude` first on PATH, which
# returns prepared statuses and plays each step's git effects: no API call.
# The fixture is a real repository with a bare origin, so sync-status.py and
# every git check of the script run on real history.
set -uo pipefail
. "$(dirname "$0")/lib.sh"

PILOT="$REPO_ROOT/plugins/claude-harness/autopilot/autopilot.py"
WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT

# --- fakes: claude, gh, notify-send ---------------------------------------
# The fake claude reads the prompt on stdin, logs one line per call (the step,
# HARNESS_AUTOPILOT, the arguments), runs $SCEN/<step>.sh in the repository,
# sleeps $SCEN/<step>.sleep seconds, and answers the first line of
# $SCEN/<step>.status (`ok` by default; a line is consumed while others follow).
# $SCEN/start.questions holds questions for the start step.
FAKEBIN="$WORK/bin"
mkdir -p "$FAKEBIN"
cat > "$FAKEBIN/claude" <<'EOF'
#!/usr/bin/env bash
prompt=$(cat)
case "$prompt" in
  "/claude-harness:lot-start") step=start ;;
  "lot-start confirm "*) step=dev ;;
  "/claude-harness:lot-test") step=test ;;
  "A test that lot-test"*) step=fix ;;
  "/claude-harness:lot-review") step=review ;;
  "/claude-harness:lot-audit") step=audit ;;
  "/claude-harness:lot-ship") step=ship ;;
  *) step=unknown ;;
esac
printf '%s autopilot=%s prompt=%s args=%s\n' "$step" "${HARNESS_AUTOPILOT:-}" "$prompt" "$*" >> "$SCEN/calls.log"
[ -f "$SCEN/$step.sh" ] && bash "$SCEN/$step.sh" >/dev/null 2>&1
[ -f "$SCEN/$step.sleep" ] && sleep "$(cat "$SCEN/$step.sleep")"
status=ok
if [ -f "$SCEN/$step.status" ]; then
  status=$(head -1 "$SCEN/$step.status")
  if [ "$(wc -l < "$SCEN/$step.status")" -gt 1 ]; then
    tail -n +2 "$SCEN/$step.status" > "$SCEN/$step.next" && mv "$SCEN/$step.next" "$SCEN/$step.status"
  fi
fi
[ -f "$SCEN/$step.silent" ] && exit 1
questions='[]'
[ "$step" = start ] && [ -f "$SCEN/start.questions" ] && questions=$(cat "$SCEN/start.questions")
echo "{\"type\":\"system\",\"subtype\":\"init\",\"session_id\":\"S-$step\"}"
jq -nc --arg s "$status" --argjson q "$questions" --arg id "S-$step" \
  '{type:"result", subtype:"success", session_id:$id,
    structured_output:{status:$s, lot:"5", questions:$q, reason:"fake"}}'
EOF
cat > "$FAKEBIN/gh" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' "${FAKE_GH_STATE:-MERGED}"
EOF
cat > "$FAKEBIN/notify-send" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' "$*" >> "$SCEN/notify.log"
EOF
chmod +x "$FAKEBIN"/*

# --- fixtures -------------------------------------------------------------
FAKEHOME="$WORK/home"
mkdir -p "$FAKEHOME/.claude"
echo '{}' > "$FAKEHOME/.claude/settings.json"
echo '{}' > "$FAKEHOME/.claude/settings.claude.json"
echo '{}' > "$FAKEHOME/.claude/settings.deepseek.json"

# fixture <name> <stack> : a harnessed clone on develop, prints its path; the
# scenario directory $WORK/<name>.scen holds the default step scripts.
fixture() {
  local origin="$WORK/$1.git" repo="$WORK/$1" scen="$WORK/$1.scen"
  git init -q --bare -b develop "$origin"
  git init -q -b develop "$repo"
  git -C "$repo" config user.email test@example.com
  git -C "$repo" config user.name Test
  cat > "$repo/CLAUDE.md" <<EOF
# P

## Gate parameters

| Parameter | Value |
|---|---|
| \`Stack\` | \`$2\` |
| \`Validation command\` | \`true\` |
| \`Lots file\` | \`lots.md\` |
EOF
  cat > "$repo/lots.md" <<'EOF'
# Lots

| Lot | Branche | Statut |
|---|---|---|
| 5 | `feat/lot-5-x` | ⬜ |
| 6 | `feat/lot-6-y` | ⬜ |

## LOT 5 — x
EOF
  printf '.claude/current-lot\n' > "$repo/.gitignore"
  git -C "$repo" add -A
  git -C "$repo" commit -qm "chore: seed"
  git -C "$repo" remote add origin "$origin"
  git -C "$repo" push -q origin develop
  mkdir -p "$scen"
  cat > "$scen/start.sh" <<'EOF'
git switch -q --no-track -c feat/lot-5-x origin/develop
EOF
  cat > "$scen/dev.sh" <<'EOF'
mkdir -p .claude src && printf 'branch=feat/lot-5-x\n' > .claude/current-lot
echo a > src/a.txt && git add src && git commit -qm "feat(5): add a"
EOF
  cat > "$scen/review.sh" <<'EOF'
mkdir -p docs/audits && echo r > docs/audits/lot-5-review.md
git add docs && git commit -qm "docs(5): add the lot review report"
EOF
  cat > "$scen/audit.sh" <<'EOF'
mkdir -p docs/audits && printf '| C | `src/a.txt` | x | fixed in abc |\n| I | y | z | rejected: minor (autopilot) |\n' > docs/audits/lot-5.md
git add docs && git commit -qm "docs(5): add the lot audit report"
EOF
  cat > "$scen/ship.sh" <<'EOF'
rm -f .claude/current-lot
EOF
  printf '%s' "$repo"
}

# pilot <repo> [args...] : runs the autopilot in <repo>, prints its exit status.
pilot() {
  local repo="$1"; shift
  (cd "$repo" && SCEN="$repo.scen" PATH="$FAKEBIN:$PATH" HOME="$FAKEHOME" \
    python3 "$PILOT" "$@" > "$repo.out" 2>&1)
  printf '%s' "$?"
}

calls() { cut -d' ' -f1 "$1.scen/calls.log" 2>/dev/null | tr '\n' ' '; }
state() { jq -r ".$2" "$1/.claude/autopilot-state.json" 2>/dev/null; }

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
assert_eq 1 "$(ls "$FAKEHOME/.claude/autopilot/happy/" | grep -c 'lot-5-review.jsonl')" \
  "each step has its own log"

# --- no confirmation on questions -----------------------------------------
R=$(fixture questions harness)
echo '["Which lot?"]' > "$R.scen/start.questions"
assert_eq 1 "$(pilot "$R")" "questions stop the run"
assert_eq "start " "$(calls "$R")" "no confirmation when questions is not empty"
assert_eq start "$(state "$R" resume)" "the stop resumes at lot-start"
assert_contains "$(state "$R" reason)" "Which lot?" "the questions are in the reason"
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

# --- a profile left on deepseek -------------------------------------------
R=$(fixture profile harness)
mkdir -p "$WORK/badhome/.claude"
echo '{"env":{"ANTHROPIC_BASE_URL":"https://api.deepseek.com/anthropic"}}' > "$WORK/badhome/.claude/settings.json"
code=$(cd "$R" && SCEN="$R.scen" PATH="$FAKEBIN:$PATH" HOME="$WORK/badhome" python3 "$PILOT" > "$R.out" 2>&1; echo $?)
assert_eq 2 "$code" "refuses to start under a settings.json carrying ANTHROPIC_BASE_URL"
assert_eq "" "$(calls "$R")" "no session under the deepseek profile"

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

# --- a frontend without its integration report, then --resume -------------
R=$(fixture front frontend)
assert_eq 1 "$(pilot "$R")" "a frontend without integration report stops"
assert_eq "start dev test review audit " "$(calls "$R")" "the stop comes before lot-ship"
assert_eq ship "$(state "$R" resume)" "the stop resumes at lot-ship"
mkdir -p "$R/docs/audits" && echo ok > "$R/docs/audits/lot-0-integration.md"
git -C "$R" add docs && git -C "$R" commit -qm "docs: add the integration check report"
: > "$R.scen/calls.log"
assert_eq 0 "$(pilot "$R" --resume)" "--resume finishes the lot"
assert_eq "ship " "$(calls "$R")" "--resume starts at the recorded step"
assert_eq 2 "$(pilot "$R" --resume)" "nothing left to resume after the merge"

# --- a review fix outside the lot's diff ----------------------------------
R=$(fixture outside harness)
cat >> "$R.scen/review.sh" <<'EOF'
echo x > other.txt && git add other.txt && git commit -qm "fix(5): apply the lot review findings"
EOF
assert_eq 1 "$(pilot "$R")" "a fix outside the diff stops the run"

R=$(fixture outsideblocked harness)
cat >> "$R.scen/review.sh" <<'EOF'
echo x > other.txt && git add other.txt && git commit -qm "feat(5): extend the lot"
EOF
echo blocked > "$R.scen/review.status"
assert_eq 1 "$(pilot "$R")" "a blocked lot-review with a commit outside the diff stops the run"
assert_eq review "$(state "$R" resume)" "the out-of-diff commit is not skipped by resuming at lot-audit"
assert_contains "$(state "$R" reason)" "other.txt" "any commit type outside the diff is named"
assert_eq "start dev test review " "$(calls "$R")" "the stop comes right after lot-review"
assert_contains "$(state "$R" reason)" "other.txt" "the reason names the file"

# --- the close of the development -----------------------------------------
R=$(fixture dirty harness)
echo 'echo x > stray.txt' >> "$R.scen/dev.sh"
assert_eq 1 "$(pilot "$R")" "a dirty tree after the development stops the run"
assert_eq "start dev " "$(calls "$R")" "no lot-test on a dirty tree"
assert_eq dev "$(state "$R" resume)" "the stop resumes at the development"

R=$(fixture unscoped harness)
sed -i 's/feat(5): add a/feat: add a/' "$R.scen/dev.sh"
assert_eq 1 "$(pilot "$R")" "a development without a lot-scoped commit stops the run"
assert_eq "start dev " "$(calls "$R")" "no lot-test without a commit scoped to the lot"

R=$(fixture red harness)
sed -i 's/| `true` |/| `false` |/' "$R/CLAUDE.md"
git -C "$R" commit -qam "chore: red gate" && git -C "$R" push -q origin develop
assert_eq 1 "$(pilot "$R")" "a red Validation command after the development stops the run"
assert_eq "start dev " "$(calls "$R")" "no lot-test on a red Validation command"
assert_contains "$(state "$R" reason)" "Validation command" "the reason names the Validation command"

# --- what lot-test may commit ---------------------------------------------
R=$(fixture testscope harness)
cat > "$R.scen/test.sh" <<'EOF'
echo b > src/b.txt && git add src && git commit -qm "test(5): complete the lot coverage"
EOF
assert_eq 1 "$(pilot "$R")" "a lot-test commit outside the test files stops the run"
assert_eq "start dev test " "$(calls "$R")" "no lot-review after it"
assert_contains "$(state "$R" reason)" "src/b.txt" "the reason names the file"

R=$(fixture testblocked harness)
echo blocked > "$R.scen/test.status"
assert_eq 1 "$(pilot "$R")" "a blocked lot-test stops the run"
assert_eq "start dev test " "$(calls "$R")" "a blocked lot-test opens no fix session"
assert_eq test "$(state "$R" resume)" "the stop resumes at lot-test"

# --- a missing report, a finding that needs a decision --------------------
R=$(fixture noreport harness)
: > "$R.scen/review.sh"
assert_eq 1 "$(pilot "$R")" "a lot-review without its committed report stops the run"
assert_eq "start dev test review " "$(calls "$R")" "no lot-audit without the review report"
assert_contains "$(state "$R" reason)" "lot-5-review.md" "the reason names the report"

R=$(fixture decision harness)
cat > "$R.scen/test.sh" <<'EOF'
mkdir -p tests docs/audits && echo t > tests/a.test.sh && echo f > docs/audits/lot-5-friction.md
git add tests docs && git commit -qm "test(5): complete the lot coverage"
EOF
echo blocked > "$R.scen/review.status"
assert_eq 1 "$(pilot "$R")" "a finding that needs a decision stops the run"
assert_eq "start dev test review " "$(calls "$R")" "test files and the friction entry pass the lot-test check"
assert_eq audit "$(state "$R" resume)" "once the owner decided, --resume goes on with lot-audit"
assert_eq 2 "$(pilot "$R")" "a stopped run refuses a fresh launch"
: > "$R.scen/calls.log"
assert_eq 0 "$(pilot "$R" --resume)" "--resume finishes the lot after the decision"
assert_eq "audit ship " "$(calls "$R")" "lot-review is not run again"

# --- the merge, checked by the script -------------------------------------
R=$(fixture notmerged harness)
assert_eq 1 "$(FAKE_GH_STATE=OPEN pilot "$R")" "a pull request left open stops the run"
assert_contains "$(state "$R" reason)" "OPEN" "the reason gives the pull request state"
assert_eq ship "$(state "$R" resume)" "the stop resumes at lot-ship"

R=$(fixture locked harness)
: > "$R.scen/ship.sh"
assert_eq 1 "$(pilot "$R")" "a lot lock left after lot-ship stops the run"
assert_contains "$(state "$R" reason)" "current-lot" "the reason names the lock"

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

# --- dry run --------------------------------------------------------------
R=$(fixture dry harness)
out=$(cd "$R" && PATH="$FAKEBIN:$PATH" HOME="$FAKEHOME" python3 "$PILOT" --dry-run)
assert_contains "$out" "review Opus" "--dry-run shows the model of each step"
assert_eq "" "$(calls "$R")" "--dry-run runs no session"
assert_ok "the script leaves no __pycache__ in the plugin" -- \
  test ! -e "$REPO_ROOT/plugins/claude-harness/hooks/__pycache__"

finish
