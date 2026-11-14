#!/usr/bin/env bash
# Exercises the SessionStart hook that re-injects the repository state (lot 19).
set -uo pipefail
. "$(dirname "$0")/lib.sh"

HOOK="$REPO_ROOT/plugins/claude-harness/hooks/session-context.sh"
HOOKS_JSON="$REPO_ROOT/plugins/claude-harness/hooks/hooks.json"
LOTFILE="$REPO_ROOT/plugins/claude-harness/hooks/lotfile.py"
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

# --- the current lot section, a range instead of a hunt (lot 38) -----------
cat >> "$REPO/lots.md" <<'EOF'

## LOT 0 — The foundation

Folded row.

## Lot 01 — The first lot

Its body.

## LOT 2 — The second lot

Second body.

### Note

A level-3 heading never ends the section.

## Annex — a level-2 heading that is not a lot section

Tail.

## LOT 6b — A sub-lot

Sub-lot body.
EOF
lot1_line=$(grep -n '^## Lot 01 ' "$REPO/lots.md" | cut -d: -f1)
lot2_line=$(grep -n '^## LOT 2 ' "$REPO/lots.md" | cut -d: -f1)
annex_line=$(grep -n '^## Annex ' "$REPO/lots.md" | cut -d: -f1)
lot6b_line=$(grep -n '^## LOT 6b ' "$REPO/lots.md" | cut -d: -f1)
total_lines=$(wc -l < "$REPO/lots.md")
assert_eq "lots.md:$lot2_line-$((annex_line - 1))" "$(python3 "$LOTFILE" section "$REPO" 2)" \
  "section: any level-2 heading, lot or not, ends the section"
assert_eq "lots.md:$lot1_line-$((lot2_line - 1))" "$(python3 "$LOTFILE" section "$REPO" 001)" \
  "section: leading zeros are ignored"
assert_eq "lots.md:$lot6b_line-$total_lines" "$(python3 "$LOTFILE" section "$REPO" 6b)" \
  "section: the last section runs to the end of the file"
out=$(python3 "$LOTFILE" section "$REPO" 6); rc=$?
assert_eq 1 "$rc" "section: a sub-lot heading is not its parent lot's"
assert_eq "" "$out" "section: the parent lot of a sub-lot prints nothing"
out=$(python3 "$LOTFILE" section "$REPO" 99); rc=$?
assert_eq 1 "$rc" "section: no heading for the lot exits 1"
assert_eq "" "$out" "section: no heading prints nothing"
DUP="$WORK/dup"
mkdir -p "$DUP"
printf '## Gate parameters\n\n| Parameter | Value |\n|---|---|\n| `Lots file` | `lots.md` |\n' > "$DUP/CLAUDE.md"
printf '## LOT 3\n\nOne.\n\n## Lot 03\n\nTwo.\n' > "$DUP/lots.md"
out=$(python3 "$LOTFILE" section "$DUP" 3); rc=$?
assert_eq 1 "$rc" "section: several headings for the lot exit 1"
assert_eq "" "$out" "section: several headings print nothing"

body=$(text "$(context startup "$REPO")")
assert_contains "$body" "Current lot section: lots.md:$lot2_line-$((annex_line - 1)) (read this range only)" \
  "lot branch: the current lot section line carries the range"
table_at=$(printf '%s\n' "$body" | grep -n '## Status table of' | cut -d: -f1)
section_at=$(printf '%s\n' "$body" | grep -n 'Current lot section:' | cut -d: -f1)
assert_ok "lot branch: the section line comes after the status table" -- \
  test "$section_at" -gt "$table_at"
assert_contains "$(printf '%s\n' "$body" | grep -m1 '^1\. Read CLAUDE.md')" "Current lot section" \
  "consigne 1 points at the range"
git -C "$REPO" switch -q develop
body=$(text "$(context startup "$REPO")")
assert_eq "" "$(printf '%s\n' "$body" | grep '^Current lot section:' || true)" \
  "non-lot branch: no section line"
git -C "$REPO" switch -q feat/lot-2-b
git -C "$REPO" switch -qc feat/lot-9-missing
body=$(text "$(context startup "$REPO")")
assert_eq "" "$(printf '%s\n' "$body" | grep '^Current lot section:' || true)" \
  "lot branch without a section: no section line"
git -C "$REPO" switch -q feat/lot-2-b
git -C "$REPO" switch -qc feat/lot-6b-sub
body=$(text "$(context startup "$REPO")")
assert_contains "$body" "Current lot section: lots.md:$lot6b_line-$total_lines (read this range only)" \
  "sub-lot branch: the sub-lot section, to the end of the file"
git -C "$REPO" switch -q feat/lot-2-b

# --- the lock, once written, is reported ----------------------------------
mkdir -p "$REPO/.claude"
printf 'lot=2\nbranch=feat/lot-2-b\nconfirmed=2026-09-21T00:00:00Z\n' > "$REPO/.claude/current-lot"
assert_contains "$(text "$(context resume "$REPO")")" "lot=2 branch=feat/lot-2-b" "lock reported"

# --- the lock is displayed, never removed (lot 24) -------------------------
# A lock bound to another branch unlocks nothing, so the merge of its lot is no
# reason to delete it.
git -C "$REPO" commit -q --allow-empty -m "feat(2): the work"
git -C "$REPO" switch -q develop
git -C "$REPO" merge -q --no-ff -m "Merge pull request #7 from someone/feat/lot-2-b" feat/lot-2-b
git -C "$REPO" commit -q --allow-empty -m "docs(2): add the lot audit report"
git -C "$REPO" switch -q feat/lot-2-b
body=$(text "$(context startup "$REPO")")
assert_contains "$body" "lot=2 branch=feat/lot-2-b" "merged lot: the lock is still reported"
assert_ok "merged lot: the lock file is kept" -- test -f "$REPO/.claude/current-lot"
assert_eq "" "$(printf '%s' "$body" | grep 'removed the lock' || true)" "merged lot: nothing is removed"
git -C "$REPO" switch -q develop
git -C "$REPO" reset -q --hard HEAD~2
git -C "$REPO" switch -q feat/lot-2-b

# --- deepseek rules only under a base URL ---------------------------------
body=$(text "$(context startup "$REPO" https://api.deepseek.com/anthropic)")
assert_contains "$body" "deepseek profile: imperative rules" "deepseek: rules section present"
assert_contains "$body" "- LOT-1:" "deepseek: rules rendered as imperatives"
body=$(text "$(context startup "$REPO")")
assert_eq "" "$(printf '%s' "$body" | grep 'LOT-1' || true)" "claude profile: no deepseek rules"
# Lot 33: the desktop app sets ANTHROPIC_BASE_URL to the native API itself.
body=$(text "$(context startup "$REPO" https://api.anthropic.com)")
assert_eq "" "$(printf '%s' "$body" | grep 'LOT-1' || true)" "the native API URL: no deepseek rules"

# --- the profile signal, one definition (lot 33) ---------------------------
for case in "|claude" "https://api.anthropic.com|claude" "https://API.anthropic.com/|claude" \
            "api.anthropic.com|claude" "https://api.deepseek.com/anthropic|deepseek" \
            "https://api.anthropic.com.evil.example|deepseek" "https://[bad|deepseek"; do
  url=${case%|*}; want=${case##*|}
  assert_eq "$want" "$(python3 "$LOTFILE" profile "$url")" "profile of '$url' is $want"
done
assert_eq deepseek "$(ANTHROPIC_BASE_URL=https://api.deepseek.com/anthropic python3 "$LOTFILE" profile)" \
  "profile reads ANTHROPIC_BASE_URL when given no URL"
assert_eq claude "$(env -u ANTHROPIC_BASE_URL python3 "$LOTFILE" profile)" \
  "profile is claude when ANTHROPIC_BASE_URL is unset"

# --- the ponytail text, a hook of its own (lot 33, CODE-6) ------------------
# Claude Code keeps at most 10,000 characters of each hook's context: the text
# has its own hook and budget, so the state and the card above keep theirs.
PONYTAIL="$REPO_ROOT/plugins/claude-harness/hooks/ponytail-context.sh"
PONYTAIL_MD="$REPO_ROOT/plugins/claude-harness/skills/ponytail/SKILL.md"
assert_ok "hooks.json runs the ponytail hook on the four SessionStart matchers" -- \
  jq -e '.hooks.SessionStart[0].hooks | any(.command | test("hooks/ponytail-context[.]sh"))' "$HOOKS_JSON"
first_rule=$(grep -m1 '^1\. ' "$PONYTAIL_MD")
for source in startup resume clear compact; do
  for url in "" https://api.deepseek.com/anthropic; do
    out=$(jq -nc --arg s "$source" --arg d "$REPO" '{hook_event_name:"SessionStart", source:$s, cwd:$d}' \
      | env -u ANTHROPIC_BASE_URL ${url:+ANTHROPIC_BASE_URL=$url} bash "$PONYTAIL")
    assert_eq "SessionStart" "$(printf '%s' "$out" | jq -r '.hookSpecificOutput.hookEventName')" \
      "ponytail, $source, ${url:-no base URL}: valid SessionStart output"
    assert_contains "$(text "$out")" "$first_rule" "ponytail, $source, ${url:-no base URL}: the text is injected"
  done
done
body=$(text "$out")
assert_eq "" "$(printf '%s\n' "$body" | grep -E '^(---|name:|description:)' || true)" \
  "ponytail: the frontmatter is not injected"
assert_eq "" "$(printf '%s' "$body" | grep 'truncated at' || true)" "ponytail: the text is never cut"
cap=$(sed -n 's/^PONYTAIL_CAP=//p' "$PONYTAIL")
assert_ok "ponytail: the body fits PONYTAIL_CAP" -- test "${#body}" -le "${cap:-0}"
assert_ok "ponytail: PONYTAIL_CAP stays under the 10,000 characters of a hook" -- test "${cap:-10000}" -lt 10000

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
assert_eq "" "$(printf '%s\n' "$(text "$out")" | grep '^Current lot section:' || true)" \
  "no lots file: no section line"
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
assert_contains "$body" "[truncated at " "the global cap cuts, and says so"
assert_contains "$body" "- OUT-1:" "the global cap cuts the state, never the rules card"
[ "${#body}" -le 9100 ] || assert_eq "<=9100" "${#body}" "the global cap holds"
body=$(text "$(context compact "$REPO")")
assert_contains "$body" "[truncated at 9000 characters]" "no card: the whole cap goes to the state"

# --- the rules card is valid and carries what the hook renders -------------
CARD="$REPO_ROOT/plugins/claude-harness/rules/deepseek.json"
assert_ok "rules/deepseek.json is valid JSON" -- jq -e . "$CARD"
assert_ok "every rule has an id and a text" -- \
  jq -e '(.rules | length) > 0 and all(.rules[]; (.id | length) > 0 and (.rule | length) > 0)' "$CARD"
assert_eq "" "$(jq -r '.rules[].id' "$CARD" | sort | uniq -d)" "rule ids are unique"

finish
