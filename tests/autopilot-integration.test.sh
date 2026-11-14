#!/usr/bin/env bash
# The autopilot's frontend and Integration command steps (lot 32), split from
# the lot 29 suite by lot 37; its fakes and fixture live in
# tests/autopilot-lib.sh.
. "$(dirname "$0")/autopilot-lib.sh"

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

finish
