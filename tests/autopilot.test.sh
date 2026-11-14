#!/usr/bin/env bash
# Exercises the autopilot (lots 27 to 29) against a fake `claude` first on PATH,
# which returns prepared statuses and plays each step's git effects: no API call.
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
# $SCEN/<step>.questions holds questions for any step. `--resume <id>`
# keeps the session id, as a real resume does.
FAKEBIN="$WORK/bin"
mkdir -p "$FAKEBIN"
cat > "$FAKEBIN/claude" <<'EOF'
#!/usr/bin/env bash
prompt=$(cat)
case "$prompt" in
  "/claude-harness:lot-start") step=start ;;
  "/claude-harness:lot-start "*) step=start ;;
  "lot-start confirm "*) step=dev ;;
  "Owner answers to your questions:"*) step=answer ;;
  "/claude-harness:lot-test") step=test ;;
  "A test that lot-test"*) step=fix ;;
  "/claude-harness:lot-review") step=review ;;
  "/claude-harness:lot-audit") step=audit ;;
  "/claude-harness:integration-check"*) step=integration ;;
  "/claude-harness:lot-ship") step=ship ;;
  *) step=unknown ;;
esac
session="S-$step"
previous=
for arg in "$@"; do
  [ "$previous" = "--resume" ] && session="$arg"
  previous="$arg"
done
printf '%s autopilot=%s prompt=%s args=%s\n' "$step" "${HARNESS_AUTOPILOT:-}" \
  "${prompt//$'\n'/\\n}" "$*" >> "$SCEN/calls.log"
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
[ -f "$SCEN/$step.questions" ] && questions=$(cat "$SCEN/$step.questions")
lot=5
[ -f "$SCEN/$step.lot" ] && lot=$(cat "$SCEN/$step.lot")
echo "{\"type\":\"system\",\"subtype\":\"init\",\"session_id\":\"$session\"}"
jq -nc --arg s "$status" --argjson q "$questions" --arg id "$session" --arg lot "$lot" \
  '{type:"result", subtype:"success", session_id:$id,
    structured_output:{status:$s, lot:$lot, questions:$q, reason:"fake"}}'
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

# fixture <name> <stack> [integration command] : a harnessed clone on develop,
# prints its path; the scenario directory $WORK/<name>.scen holds the default
# step scripts.
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
  if [ -n "${3:-}" ]; then
    printf '| `Integration command` | `%s` |\n' "$3" >> "$repo/CLAUDE.md"
  fi
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
review_logs=("$FAKEHOME/.claude/autopilot/happy/"*lot-5-review.jsonl)
assert_ok "each step has its own log" -- test -e "${review_logs[0]}"

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

# --- the integration step (lot 32) ----------------------------------------
R=$(fixture integration frontend true)
cat > "$R.scen/integration.sh" <<'EOF'
mkdir -p docs/audits && printf '# Integration check\n\n**Verdict:** Pass\n' > docs/audits/lot-0-integration.md
git add docs && git commit -qm "docs: add the integration check report"
EOF
assert_eq 0 "$(pilot "$R")" "a frontend with an Integration command runs integration"
assert_eq "start dev test review audit integration ship " "$(calls "$R")" \
  "integration runs between the audit and the ship"
assert_contains "$(grep '^integration ' "$R.scen/calls.log")" "settings.claude.json" \
  "the integration report session runs on the claude settings"
assert_contains "$(grep '^integration ' "$R.scen/calls.log")" \
  "prompt=/claude-harness:integration-check " "the session gets the skill prompt"
assert_contains "$(grep '^integration ' "$R.scen/calls.log")" "lot-5-integration.log" \
  "the prompt carries the command's log path"
integration_logs=("$FAKEHOME/.claude/autopilot/integration/"*lot-5-integration.log)
assert_ok "the command's output has its own log" -- test -e "${integration_logs[0]}"

out=$(cd "$R" && PATH="$FAKEBIN:$PATH" HOME="$FAKEHOME" python3 "$PILOT" --dry-run)
assert_contains "$out" "integration Opus" "--dry-run lists the integration step"
assert_contains "$out" "<<< /claude-harness:integration-check <integration log>" \
  "--dry-run shows the integration prompt and its log"
assert_eq "start dev test review audit integration ship" \
  "$(grep -E '^(start|dev|test|review|audit|integration|ship) ' <<< "$out" \
     | awk '{print $1}' | paste -sd' ')" \
  "--dry-run lists the lot's steps, integration between the audit and the ship"

R=$(fixture integrationbackend backend true)
assert_eq 0 "$(pilot "$R")" "a backend runs even when a command is declared"
assert_eq "start dev test review audit ship " "$(calls "$R")" \
  "no integration step on a backend"
out=$(cd "$R" && PATH="$FAKEBIN:$PATH" HOME="$FAKEHOME" python3 "$PILOT" --dry-run)
assert_eq "start dev test review audit ship" \
  "$(grep -E '^(start|dev|test|review|audit|integration|ship) ' <<< "$out" \
     | awk '{print $1}' | paste -sd' ')" \
  "a backend dry run keeps the current sequence, without integration"

R=$(fixture integrationna frontend n/a)
cat >> "$R.scen/dev.sh" <<'EOF'
mkdir -p docs/audits && echo ok > docs/audits/lot-0-integration.md
git add docs && git commit -qm "docs: add the integration check report"
EOF
assert_eq 0 "$(pilot "$R")" "a command of n/a runs no integration step"
assert_eq "start dev test review audit ship " "$(calls "$R")" \
  "a frontend whose command is n/a keeps the existing sequence"

R=$(fixture integrationfail frontend false)
assert_eq 1 "$(pilot "$R")" "a non-zero Integration command stops the run"
assert_eq "start dev test review audit " "$(calls "$R")" \
  "no integration session after a failed command"
assert_eq integration "$(state "$R" resume)" "the stop resumes at integration"
assert_contains "$(state "$R" reason)" "lot-5-integration.log" "the reason gives the log path"

R=$(fixture integrationtimeout frontend "sleep 5")
code=$(cd "$R" && SCEN="$R.scen" PATH="$FAKEBIN:$PATH" HOME="$FAKEHOME" AUTOPILOT_INTEGRATION_TIMEOUT=1 \
  python3 "$PILOT" > "$R.out" 2>&1; echo $?)
assert_eq 1 "$code" "an Integration command over its timeout stops the run"
assert_contains "$(state "$R" reason)" "timed out" "the timeout is recorded"
assert_contains "$(state "$R" reason)" "lot-5-integration.log" \
  "the timeout reason gives the log path too"
assert_eq integration "$(state "$R" resume)" "the timed-out integration is the step resumed"

R=$(fixture integrationleftover frontend 'sleep 300 & echo $! > .git/leftover.pid')
cat > "$R.scen/integration.sh" <<'EOF'
mkdir -p docs/audits && echo ok > docs/audits/lot-0-integration.md
git add docs && git commit -qm "docs: add the integration check report"
EOF
assert_eq 0 "$(pilot "$R")" "a command leaving a background process still passes"
assert_ok "the command's background process is killed once it exits" -- \
  bash -c '! kill -0 "$1" 2>/dev/null' _ "$(cat "$R/.git/leftover.pid")"

R=$(fixture integrationnoreport frontend true)
assert_eq 1 "$(pilot "$R")" "an integration session that commits no report stops the run"
assert_eq "start dev test review audit integration " "$(calls "$R")" \
  "no ship without the report committed"
assert_eq integration "$(state "$R" resume)" "the stop resumes at integration"
assert_contains "$(state "$R" reason)" "lot-0-integration.md is not committed" \
  "the reason names the uncommitted report"

R=$(fixture integrationstale frontend true)
mkdir -p "$R/docs/audits" && echo old > "$R/docs/audits/lot-0-integration.md"
git -C "$R" add docs && git -C "$R" commit -qm "docs: add the integration check report"
git -C "$R" push -q origin develop
assert_eq 1 "$(pilot "$R")" "a report outside the lot's diff stops the ship"
assert_eq "start dev test review audit integration " "$(calls "$R")" \
  "the ship is not run without a fresh report"
assert_eq integration "$(state "$R" resume)" "the stale report resumes at integration"
assert_contains "$(state "$R" reason)" "lot-0-integration.md" "the reason names the report"
cat > "$R.scen/integration.sh" <<'EOF'
echo new > docs/audits/lot-0-integration.md
git add docs && git commit -qm "docs: add the integration check report"
EOF
: > "$R.scen/calls.log"
assert_eq 0 "$(pilot "$R" --resume)" "--resume finishes once the report is in the lot's diff"
assert_eq "integration ship " "$(calls "$R")" "the resume reruns integration, then ships"

R=$(fixture integrationaudit frontend true)
cat > "$R.scen/integration.sh" <<'EOF'
mkdir -p docs/audits && echo ok > docs/audits/lot-0-integration.md
git add docs && git commit -qm "docs: add the integration check report"
EOF
echo blocked > "$R.scen/audit.status"
assert_eq 1 "$(pilot "$R")" "a blocked lot-audit stops a frontend run"
assert_eq integration "$(state "$R" resume)" "a blocked audit resumes at integration, never past it"

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

# --- the census rows of a gate report (lot 36) ----------------------------
R=$(fixture censusreview harness)
cat >> "$R.scen/review.sh" <<'EOF'
printf '| `docs/audits/lot-5-review.md` | Lot 5 code-review report |\n' >> CLAUDE.md
printf '| `docs/audits/lot-5-review.md` | Lot 5 code-review report |\n' >> AGENTS.md
git add CLAUDE.md AGENTS.md && git commit -qm "docs(5): add the census rows"
EOF
assert_eq 0 "$(pilot "$R")" "a review may add the census rows of its report"
assert_eq "start dev test review audit ship " "$(calls "$R")" \
  "the census rows do not stop the run"

R=$(fixture censusmodify harness)
cat >> "$R.scen/review.sh" <<'EOF'
sed -i 's/| `true` |/| `false` |/' CLAUDE.md
git add CLAUDE.md && git commit -qm "fix(5): touch a line of CLAUDE.md"
EOF
assert_eq 1 "$(pilot "$R")" "a review that modifies another line of CLAUDE.md stops the run"
assert_contains "$(state "$R" reason)" "CLAUDE.md" "the reason names the modified file"

R=$(fixture censusother harness)
cat >> "$R.scen/review.sh" <<'EOF'
printf '| `README.md` | Project readme |\n' >> CLAUDE.md
git add CLAUDE.md && git commit -qm "docs(5): add a census row for another document"
EOF
assert_eq 1 "$(pilot "$R")" "a row naming a document outside docs/audits/ stops the run"
assert_eq "start dev test review " "$(calls "$R")" "no lot-audit after a non-census addition"
assert_contains "$(state "$R" reason)" "CLAUDE.md" "the reason names the file"

# A removed line starting with "--" reads "---" in the diff, like a file header.
R=$(fixture censusdashes harness)
printf -- '-- a note\n' >> "$R/CLAUDE.md"
git -C "$R" commit -qam "chore: seed a dashed line"
git -C "$R" push -q origin develop
cat >> "$R.scen/review.sh" <<'EOF'
sed -i '/^-- a note$/d' CLAUDE.md
printf '| `docs/audits/lot-5-review.md` | Lot 5 code-review report |\n' >> CLAUDE.md
git add CLAUDE.md && git commit -qm "docs(5): add the census row"
EOF
assert_eq 1 "$(pilot "$R")" "a removed line starting with -- next to a census row stops the run"
assert_contains "$(state "$R" reason)" "CLAUDE.md" "the reason names the file"

# The real census row goes inside the table, not at the end of the file.
R=$(fixture censusinsert harness)
cp "$R/CLAUDE.md" "$R/AGENTS.md"
git -C "$R" add AGENTS.md
git -C "$R" commit -qm "chore: seed the mirror"
git -C "$R" push -q origin develop
cat >> "$R.scen/review.sh" <<'EOF'
for f in CLAUDE.md AGENTS.md; do
  sed -i '/^| `Lots file`/i | `docs/audits/lot-5-review.md` | Lot 5 code-review report |' "$f"
done
git add CLAUDE.md AGENTS.md && git commit -qm "docs(5): add the census rows"
EOF
assert_eq 0 "$(pilot "$R")" "census rows inserted inside the table pass"
assert_eq "start dev test review audit ship " "$(calls "$R")" \
  "the insertion does not stop the run"

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

# Lot 36: the census row of a friction report is an addition lot-test may make.
R=$(fixture testcensus harness)
cat > "$R.scen/test.sh" <<'EOF'
mkdir -p tests docs/audits && echo t > tests/a.test.sh && echo f > docs/audits/lot-5-friction.md
printf '| `docs/audits/lot-5-friction.md` | Lot 5 friction record |\n' >> CLAUDE.md
printf '| `docs/audits/lot-5-friction.md` | Lot 5 friction record |\n' >> AGENTS.md
git add tests docs CLAUDE.md AGENTS.md && git commit -qm "test(5): complete the lot coverage"
EOF
assert_eq 0 "$(pilot "$R")" "lot-test may add the census rows of its friction report"
assert_eq "start dev test review audit ship " "$(calls "$R")" \
  "the census rows do not stop the run"

R=$(fixture testcensusmodify harness)
cat > "$R.scen/test.sh" <<'EOF'
mkdir -p tests && echo t > tests/a.test.sh
sed -i 's/| `true` |/| `false` |/' CLAUDE.md
git add tests CLAUDE.md && git commit -qm "test(5): complete the lot coverage"
EOF
assert_eq 1 "$(pilot "$R")" "lot-test cannot modify another line of CLAUDE.md"
assert_eq "start dev test " "$(calls "$R")" "no lot-review after it"
assert_contains "$(state "$R" reason)" "CLAUDE.md" "the reason names the modified file"

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

# --- the questions, readable in a terminal (lot 29) ------------------------
R=$(fixture layout harness)
echo blocked > "$R.scen/start.status"
printf '%s' '["Which lot?", "Which branch?\n(a) feat/lot-5-x\n(b) feat/lot-5-y"]' \
  > "$R.scen/start.questions"
assert_eq 1 "$(pilot "$R")" "a blocked lot-start stops the run"
assert_contains "$(cat "$R.out")" $'Questions:\n  1. Which lot?\n\n  2. Which branch?\n     (a) feat/lot-5-x\n     (b) feat/lot-5-y' \
  "each question is numbered on its own line, its options indented below it"
assert_eq 1 "$(grep -c 'Which lot?' "$R.out")" "each question is printed once"
assert_eq 0 "$(state "$R" reason | grep -c 'Which')" "the questions are no longer copied into the reason"
assert_contains "$(tail -1 "$R.out")" "--resume --answer" "the answer command closes the message"
assert_contains "$(cat "$R.scen/notify.log")" "  2. Which branch?" "the notification has the same layout"

R=$(fixture auditquestion harness)
: > "$R.scen/audit.sh"
echo blocked > "$R.scen/audit.status"
echo '["The Validation command is red: how to proceed?"]' > "$R.scen/audit.questions"
assert_eq 1 "$(pilot "$R")" "a blocked lot-audit without its committed report stops the run"
assert_contains "$(state "$R" reason)" "lot-5.md is not committed" "the reason names the report"
assert_contains "$(state "$R" questions)" "how to proceed?" "the audit's question survives the report check"
assert_eq blocked "$(state "$R" status)" "the audit's status survives the report check"
assert_eq audit "$(state "$R" resume)" "the report check resumes at the audit"
assert_contains "$(cat "$R.out")" "  1. The Validation command is red: how to proceed?" \
  "the audit's question is shown"
assert_contains "$(tail -1 "$R.out")" "Settle them, then: autopilot.py --resume" \
  "a gate stop is settled by the owner, then resumed"

R=$(fixture auditokquestion harness)
: > "$R.scen/audit.sh"
echo '["Le rapport est-il à commiter ?"]' > "$R.scen/audit.questions"
assert_eq 1 "$(pilot "$R")" "an ok lot-audit with questions and no committed report stops the run"
assert_eq blocked "$(state "$R" status)" "questions make the report stop blocked whatever the status"

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

# --- the live watch (lot 34) ----------------------------------------------
WATCH="$REPO_ROOT/plugins/claude-harness/autopilot/watch.py"

# watch_case <tool|subagent|result> : prints what watch.py renders for one event.
watch_case() {
  python3 - "$WATCH" "$1" <<'EOF'
import importlib.util
import sys

sys.dont_write_bytecode = True
spec = importlib.util.spec_from_file_location("watch", sys.argv[1])
watch = importlib.util.module_from_spec(spec)
spec.loader.exec_module(watch)


def emit(*events):
    for event in events:
        for line in watch.lines(event, "dev", "12:34:56"):
            print(line)


case = sys.argv[2]
if case == "tool":
    emit({"type": "system", "subtype": "init", "model": "deepseek-v4[1m]"},
         {"type": "assistant", "message": {"model": "deepseek-v4[1m]", "content": [
             {"type": "tool_use", "name": "Read", "input": {"file_path": "docs/memory.md"}}]}})
elif case == "subagent":
    emit({"type": "system", "subtype": "init", "model": "claude-opus-5-5"},
         {"type": "assistant", "parent_tool_use_id": "tu_1",
          "message": {"model": "claude-haiku-5-5", "content": [
              {"type": "tool_use", "name": "Task", "input": {"description": "explore"}}]}})
elif case == "result":
    emit({"type": "system", "subtype": "init", "model": "claude-opus-5-5"},
         {"type": "result", "structured_output": {"status": "ok", "reason": "done"}})
elif case == "text":
    emit({"type": "system", "subtype": "init", "model": "deepseek-v4[1m]"},
         {"type": "assistant", "message": {"model": "deepseek-v4[1m]", "content": [
             {"type": "text", "text": "Je vérifie les tests.\nDeuxième ligne."}]}})
elif case == "denied":
    emit({"type": "system", "subtype": "permission_denied", "tool_name": "Bash",
          "message": "refused by the permission rules"})
elif case == "clock":
    for line in watch.lines({"type": "assistant", "message": {
            "model": "deepseek-v4", "content": [
                {"type": "tool_use", "name": "Read", "input": {}}]}}, "dev"):
        print(line)
EOF
}

out=$(watch_case tool)
assert_contains "$out" "12:34:56" "a watch line carries the time"
assert_contains "$out" "dev" "a watch line carries the step"
assert_contains "$out" "deepseek-v4" "a watch line carries the model"
assert_contains "$out" "Read" "a watch line carries the tool"
assert_contains "$out" "docs/memory.md" "a watch line carries the tool's detail"

out=$(watch_case subagent)
assert_contains "$out" "↳claude-haiku" "a sub-agent's line is marked with ↳"

out=$(watch_case result)
assert_contains "$out" "claude-opus-5-5" "a result line falls back to the init event's model"
assert_contains "$out" "✔ fin d'étape: ok done" "a result line carries the step's verdict"

out=$(watch_case text)
assert_eq 1 "$(wc -l <<< "$out")" "a text block gets one line"
assert_contains "$out" "» Je vérifie les tests." "a text line shows the text"

out=$(watch_case denied)
assert_contains "$out" "✗ refusé Bash" "a denial gets one line carrying the tool"

out=$(watch_case clock)
assert_eq 1 "$(grep -cE '^[0-9]{2}:[0-9]{2}:[0-9]{2} ' <<< "$out")" \
  "a live line defaults to an HH:MM:SS stamp"

# The history replayed from the newest log when a step starts (lot 34).
H="$WORK/history"
mkdir -p "$H/.claude/autopilot/history"
printf '%s\n' '{"type":"assistant","message":{"model":"deepseek-v4[1m]","content":[{"type":"text","text":"Bonjour"}]}}' \
  > "$H/.claude/autopilot/history/lot-5-dev.jsonl"
out=$(cd "$H" && HOME="$H" timeout 2 python3 "$WATCH" "$H" 2>&1; true)
assert_contains "$out" "autopilot-watch:" "the watch announces the log folder it follows"
assert_contains "$out" "== lot-5-dev.jsonl ==" "the watch names the step's log"
assert_eq 1 "$(grep -cE '^~[0-9]{2}:[0-9]{2} +dev ' <<< "$out")" \
  "a backlog line is stamped ~HH:MM and carries the step"
assert_contains "$out" "Bonjour" "the backlog replays the step's text"

# A terminal starts the watch; a dry run never does (lot 34). `script` gives
# the autopilot a pseudo-terminal, as a user's shell does.
if command -v script >/dev/null 2>&1 && command -v pgrep >/dev/null 2>&1; then
  R=$(fixture watchon harness)
  echo 1 > "$R.scen/dev.sleep"
  out=$(cd "$R" && SCEN="$R.scen" PATH="$FAKEBIN:$PATH" HOME="$FAKEHOME" \
    script -qec "python3 $PILOT" /dev/null < /dev/null 2>&1)
  assert_contains "$out" "autopilot-watch:" "a terminal starts the live watch"
  assert_contains "$out" "autopilot: Lot 5 merged" "the run ends with its watch in the terminal"
  assert_eq 0 "$(pgrep -fc "watch.py $R" || true)" "the watch is stopped with the run"

  out=$(cd "$R" && SCEN="$R.scen" PATH="$FAKEBIN:$PATH" HOME="$FAKEHOME" \
    script -qec "python3 $PILOT --dry-run" /dev/null < /dev/null 2>&1)
  assert_contains "$out" "review Opus" "the dry run prints in the terminal"
  assert_eq "" "$(grep -o 'autopilot-watch' <<< "$out" || true)" \
    "a dry run starts no watch, even in a terminal"
else
  echo "  (skipped: script or pgrep not installed, the terminal watch is not exercised)"
fi

R=$(fixture watchoff harness)
assert_eq 0 "$(pilot "$R")" "the run is green with its output redirected"
assert_eq "" "$(grep -o 'autopilot-watch' "$R.out" || true)" \
  "a redirected output starts no watch process"

finish
