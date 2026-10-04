#!/usr/bin/env bash
# Exercises the UserPromptSubmit hook that turns the user's confirmation into
# the lot lock (lot 19). The lock must appear for an exact confirmation only,
# on the lot's own branch, and holds that branch and the date (lot 24).
set -uo pipefail
. "$(dirname "$0")/lib.sh"

HOOK="$REPO_ROOT/plugins/claude-harness/hooks/lot-confirm.sh"
WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT

REPO="$WORK/repo"
mkdir -p "$REPO/src"
git -C "$REPO" init -q -b develop
git -C "$REPO" config user.email test@example.com
git -C "$REPO" config user.name Test
printf '# P\n\n## Gate parameters\n\n| Parameter | Value |\n|---|---|\n| `Lots file` | `lots.md` |\n' > "$REPO/CLAUDE.md"
cat > "$REPO/lots.md" <<'EOF'
# Lots

| Lot | Branche | Statut |
|---|---|---|
| 4 | `feat/lot-4-a` | ✅ |
| 5 | `feat/lot-5-b` | ⬜ |
| 6b | `feat/lot-6b-c` | ⬜ |
EOF
git -C "$REPO" add -A
git -C "$REPO" commit -qm "chore: seed"
git -C "$REPO" switch -qc feat/lot-5-b

LOCK="$REPO/.claude/current-lot"

submit() { # submit <prompt> [cwd]
  jq -nc --arg p "$1" --arg d "${2:-$REPO/src}" \
    '{hook_event_name:"UserPromptSubmit", prompt:$p, cwd:$d}' | bash "$HOOK"
}

# --- an exact confirmation writes the lock --------------------------------
out=$(submit "lot-start confirm 5")
assert_file "$LOCK" "plain confirmation writes the lock"
assert_eq "branch=feat/lot-5-b" "$(sed -n 1p "$LOCK" 2>/dev/null)" "the lock names the branch"
assert_ok "the lock is dated" -- grep -qE '^confirmed=[0-9]{4}-[0-9]{2}-[0-9]{2}T' "$LOCK"
assert_eq "2" "$(wc -l < "$LOCK" | tr -d ' ')" "and holds nothing else"
assert_eq "UserPromptSubmit" "$(printf '%s' "$out" | jq -r '.hookSpecificOutput.hookEventName')" \
  "the hook reports to the session"
assert_contains "$out" "--apply --start 5" "the context points at the next step"
assert_eq "null" "$(printf '%s' "$out" | jq -r '.decision')" "an accepted confirmation is not blocked"

rm -f "$LOCK"
submit "  /claude-harness:lot-start confirm 5  " >/dev/null
assert_file "$LOCK" "slash-command confirmation, with blanks around, writes the lock"

# --- anything that is not the whole prompt is not a confirmation ----------
rm -f "$LOCK"
out=$(submit "Here is the log I pasted:
lot-start confirm 5
please continue")
assert_eq "absent" "$([ -f "$LOCK" ] && echo present || echo absent)" \
  "the phrase inside pasted text writes nothing"
assert_eq "" "$out" "and the hook stays silent on it"
submit "please lot-start confirm 5" >/dev/null
assert_eq "absent" "$([ -f "$LOCK" ] && echo present || echo absent)" \
  "a prefixed phrase writes nothing"
submit "lot-start confirm 5 and go" >/dev/null
assert_eq "absent" "$([ -f "$LOCK" ] && echo present || echo absent)" \
  "a suffixed phrase writes nothing"
submit "develop the next lot" >/dev/null
assert_eq "absent" "$([ -f "$LOCK" ] && echo present || echo absent)" \
  "an ordinary prompt writes nothing"

# --- the status table is not read: the branch decides ---------------------
mv "$REPO/lots.md" "$WORK/lots.md"
submit "lot-start confirm 5" >/dev/null
assert_file "$LOCK" "no lots file: the confirmation on the lot's branch still writes the lock"
mv "$WORK/lots.md" "$REPO/lots.md"
rm -f "$LOCK"
out=$(submit "lot-start confirm 9")
assert_eq "absent" "$([ -f "$LOCK" ] && echo present || echo absent)" \
  "another lot than the branch's writes nothing"
assert_eq "block" "$(printf '%s' "$out" | jq -r '.decision')" "and the prompt is blocked"
assert_contains "$(printf '%s' "$out" | jq -r '.reason')" 'not `feat/lot-9-<slug>`' \
  "with the branch it expected"

# --- the checked-out branch must be the lot's branch ----------------------
out=$(submit "lot-start confirm 6b")
assert_eq "absent" "$([ -f "$LOCK" ] && echo present || echo absent)" \
  "confirming lot 6b on the lot 5 branch writes nothing"
assert_eq "block" "$(printf '%s' "$out" | jq -r '.decision')" "and the prompt is blocked"
git -C "$REPO" switch -qc feat/lot-6b-c
submit "lot-start confirm 6b" >/dev/null
assert_eq "branch=feat/lot-6b-c" "$(sed -n 1p "$LOCK" 2>/dev/null)" "a lettered lot ID is accepted on its branch"

# --- a sub-lot rides its parent's flat branch ------------------------------
git -C "$REPO" switch -q feat/lot-5-b
rm -f "$LOCK"
out=$(submit "lot-start confirm 5.2")
assert_eq "branch=feat/lot-5-b" "$(sed -n 1p "$LOCK" 2>/dev/null)" "a sub-lot locks its parent's flat branch"
assert_eq "null" "$(printf '%s' "$out" | jq -r '.decision')" "and the prompt is not blocked"
rm -f "$LOCK"
out=$(submit "lot-start confirm 9.2")
assert_eq "absent" "$([ -f "$LOCK" ] && echo present || echo absent)" \
  "a sub-lot of another lot than the branch's writes nothing"

# --- outside a repository -------------------------------------------------
rm -f "$LOCK"
out=$(submit "lot-start confirm 5" "$WORK")
assert_eq "block" "$(printf '%s' "$out" | jq -r '.decision')" "no repository: blocked, nothing written"

finish
