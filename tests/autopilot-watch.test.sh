#!/usr/bin/env bash
# The autopilot's live watch (lot 34), split from the lot 29 suite by lot 37;
# its fakes and fixture live in tests/autopilot-lib.sh.
. "$(dirname "$0")/autopilot-lib.sh"

# --- the live watch (lot 34) ----------------------------------------------
WATCH="$REPO_ROOT/plugins/claude-harness/autopilot/watch.py"

# watch_case <tool|subagent|result|text|denied|clock> : prints what watch.py renders for one event.
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
elif case == "escape":
    emit({"type": "assistant", "message": {"model": "deepseek-v4", "content": [
        {"type": "text", "text": "\x1b]52;c;cGF5bG9hZA==\x07done \x9b2J"}]}})
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

out=$(watch_case escape)
assert_eq "" "$(tr -d '\n' <<< "$out" | grep -P '[\x00-\x1f\x7f]' || true)" \
  "a watch line carries no control character from the log"
assert_contains "$out" "done" "a watch line keeps the text around a neutralised control"

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

# A log older than the run's start is a previous run, never shown as live; a
# half-written last line waits for its end instead of being lost.
touch -d '2 hours ago' "$H/.claude/autopilot/history/lot-5-dev.jsonl"
printf '%s\n%s' '{"type":"assistant","message":{"content":[{"type":"text","text":"Complet"}]}}' \
  '{"type":"assistant","message":{"content":[{"type":"text","text":"Moi' \
  > "$H/.claude/autopilot/history/lot-6-start.jsonl"
out=$(cd "$H" && HOME="$H" timeout 2 python3 "$WATCH" "$H" "$(date -d '1 hour ago' +%s)" 2>&1; true)
assert_eq "" "$(grep -o 'lot-5-dev' <<< "$out" || true)" "the watch skips a log older than its start"
assert_contains "$out" "Complet" "the watch follows the run's own log"
assert_eq "" "$(grep -o 'Moi' <<< "$out" || true)" "a half-written line is not shown before its end"

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
