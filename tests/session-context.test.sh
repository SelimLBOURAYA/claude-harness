#!/usr/bin/env bash
# Exercises the SessionStart hook that re-injects the repository state (lot 19).
set -uo pipefail
. "$(dirname "$0")/lib.sh"

HOOK="$REPO_ROOT/plugins/claude-harness/hooks/session-context.sh"
HOOKS_JSON="$REPO_ROOT/plugins/claude-harness/hooks/hooks.json"
WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT

REPO="$WORK/repo"
mkdir -p "$REPO"
git -C "$REPO" init -q -b develop
git -C "$REPO" config user.email test@example.com
git -C "$REPO" config user.name Test
printf '# P\n\n## Gate parameters\n\n| Parameter | Value |\n|---|---|\n| `Lots file` | `lots.md` |\n' > "$REPO/CLAUDE.md"
cat > "$REPO/lots.md" <<'EOF'
# Lots

| Lot | Branche | Statut |
|---|---|---|
| 1 | `feat/lot-1-a` | ✅ |
| 2 | `feat/lot-2-b` | ⬜ |
EOF
git -C "$REPO" add -A
git -C "$REPO" commit -qm "docs: seed the lots file"
git -C "$REPO" switch -qc feat/lot-2-b
printf 'wip\n' > "$REPO/dirty.txt"

# context <source> <cwd> [ANTHROPIC_BASE_URL]
context() {
  jq -nc --arg s "$1" --arg d "$2" '{hook_event_name:"SessionStart", source:$s, cwd:$d}' \
    | env -u ANTHROPIC_BASE_URL ${3:+ANTHROPIC_BASE_URL=$3} bash "$HOOK"
}
text() { printf '%s' "$1" | jq -r '.hookSpecificOutput.additionalContext'; }

# --- every matcher produces the state -------------------------------------
for source in startup resume clear compact; do
  out=$(context "$source" "$REPO")
  assert_eq "SessionStart" "$(printf '%s' "$out" | jq -r '.hookSpecificOutput.hookEventName')" \
    "$source: valid SessionStart output"
  body=$(text "$out")
  assert_contains "$body" "SessionStart: $source" "$source: names its trigger"
  assert_contains "$body" "Branch: feat/lot-2-b" "$source: current branch"
  assert_contains "$body" "?? dirty.txt" "$source: git status --short"
  assert_contains "$body" "docs: seed the lots file" "$source: first-parent commits of develop"
  assert_contains "$body" "Lot lock: none confirmed" "$source: lock state"
  assert_contains "$body" '| 2 | `feat/lot-2-b` | ⬜ |' "$source: open rows of the status table"
  assert_contains "$body" "lot-start" "$source: the start instructions"
done
assert_ok "hooks.json wires all four SessionStart matchers" -- \
  jq -e '.hooks.SessionStart[0].matcher == "startup|resume|clear|compact"' "$HOOKS_JSON"

body=$(text "$(context compact "$REPO")")
assert_contains "$body" "not a source of truth" "compact: the summary is flagged as untrusted"
body=$(text "$(context startup "$REPO")")
assert_eq "" "$(printf '%s' "$body" | grep 'not a source of truth' || true)" \
  "startup: no compaction warning"

# --- the lock, once written, is reported ----------------------------------
mkdir -p "$REPO/.claude"
printf 'lot=2\nbranch=feat/lot-2-b\nconfirmed=2026-09-21T00:00:00Z\n' > "$REPO/.claude/current-lot"
assert_contains "$(text "$(context resume "$REPO")")" "lot=2 branch=feat/lot-2-b" "lock reported"

# --- deepseek rules only under a base URL ---------------------------------
body=$(text "$(context startup "$REPO" https://api.deepseek.com/anthropic)")
assert_contains "$body" "deepseek profile: imperative rules" "deepseek: rules section present"
assert_contains "$body" "- LOT-1:" "deepseek: rules rendered as imperatives"
body=$(text "$(context startup "$REPO")")
assert_eq "" "$(printf '%s' "$body" | grep 'LOT-1' || true)" "claude profile: no deepseek rules"

# --- size cap --------------------------------------------------------------
for i in $(seq 1 300); do
  printf '| %d | `feat/lot-%d-long-branch-name-for-the-cap` | ⬜ |\n' $((i + 10)) $((i + 10))
done >> "$REPO/lots.md"
body=$(text "$(context compact "$REPO" https://api.deepseek.com/anthropic)")
[ "${#body}" -le 9100 ] || assert_eq "<=9100" "${#body}" "the output is capped"
assert_contains "$body" "[table truncated at" "a long table is cut, and says so"
assert_contains "$body" "- OUT-1:" "a long table never pushes the rules out of the cap"

# --- degraded but never blocking -------------------------------------------
rm "$REPO/lots.md"
out=$(context startup "$REPO"); rc=$?
assert_eq 0 "$rc" "no lots file: exit 0"
assert_contains "$(text "$out")" "no lots file or no status table found" "no lots file: said so"
out=$(context startup "$WORK"); rc=$?
assert_eq 0 "$rc" "not a repository: exit 0"
assert_contains "$(text "$out")" "not a git repository" "not a repository: said so"
out=$(printf 'garbage' | bash "$HOOK"); rc=$?
assert_eq 0 "$rc" "unparseable payload: exit 0"

# The global cap holds even when every section is within its own budget.
git -C "$REPO" switch -q develop
long=$(printf 'x%.0s' $(seq 1 1200))
for i in $(seq 1 10); do git -C "$REPO" commit -q --allow-empty -m "docs: $i $long"; done
git -C "$REPO" switch -q feat/lot-2-b
body=$(text "$(context compact "$REPO" https://api.deepseek.com/anthropic)")
assert_contains "$body" "[truncated at 9000 characters]" "the global cap cuts, and says so"
[ "${#body}" -le 9100 ] || assert_eq "<=9100" "${#body}" "the global cap holds"

# --- the rules card is valid and carries what the hook renders -------------
CARD="$REPO_ROOT/plugins/claude-harness/rules/deepseek.json"
assert_ok "rules/deepseek.json is valid JSON" -- jq -e . "$CARD"
assert_ok "every rule has an id and a text" -- \
  jq -e '(.rules | length) > 0 and all(.rules[]; (.id | length) > 0 and (.rule | length) > 0)' "$CARD"
assert_eq "" "$(jq -r '.rules[].id' "$CARD" | sort | uniq -d)" "rule ids are unique"

finish
