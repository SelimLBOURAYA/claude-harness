#!/usr/bin/env bash
# Shared fakes, fixture and helpers of the autopilot suites (lot 37). Sourced by
# every tests/autopilot-*.test.sh; its name keeps it out of run.sh's *.test.sh
# glob, so it is never run as a suite.
set -uo pipefail
. "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

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

# --- fixture --------------------------------------------------------------
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

# --- helpers --------------------------------------------------------------
# pilot <repo> [args...] : runs the autopilot in <repo>, prints its exit status.
pilot() {
  local repo="$1"; shift
  (cd "$repo" && SCEN="$repo.scen" PATH="$FAKEBIN:$PATH" HOME="$FAKEHOME" \
    python3 "$PILOT" "$@" > "$repo.out" 2>&1)
  printf '%s' "$?"
}

calls() { cut -d' ' -f1 "$1.scen/calls.log" 2>/dev/null | tr '\n' ' '; }
state() { jq -r ".$2" "$1/.claude/autopilot-state.json" 2>/dev/null; }
