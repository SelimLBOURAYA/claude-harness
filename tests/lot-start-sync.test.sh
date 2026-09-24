#!/usr/bin/env bash
# Runs the lot-start status synchronisation on fixture repositories (lot 19).
# Executed, not grepped: every fixture is a real git history with real merges.
#
# The last fixture replays the 2026-09-21 incident end to end: a stale table,
# sub-lots on one flat branch, the stop, the write guard, and the user's
# confirmation that finally opens it.
set -uo pipefail
. "$(dirname "$0")/lib.sh"

HOOKS="$REPO_ROOT/plugins/claude-harness/hooks"
SYNC="$REPO_ROOT/plugins/claude-harness/skills/lot-start/sync-status.py"
WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT

# new_repo <name> : harnessed repository on develop; lots.md read from stdin.
new_repo() {
  local dir="$WORK/$1"
  mkdir -p "$dir/src"
  git -C "$dir" init -q -b develop
  git -C "$dir" config user.email test@example.com
  git -C "$dir" config user.name Test
  printf '# P\n\n## Gate parameters\n\n| Parameter | Value |\n|---|---|\n| `Lots file` | `lots.md` |\n' > "$dir/CLAUDE.md"
  cat > "$dir/lots.md"
  git -C "$dir" add -A
  git -C "$dir" commit -qm "docs: seed"
  printf '%s' "$dir"
}

# merge_pr <repo> <branch> <pr> : a branch with one commit, merged with --no-ff
# under the subject GitHub gives a merged pull request.
merge_pr() {
  git -C "$1" switch -qc "$2" develop
  printf '%s\n' "$2" > "$1/src/$3.txt"
  git -C "$1" add -A
  git -C "$1" commit -qm "feat: work of $2"
  git -C "$1" switch -q develop
  git -C "$1" merge -q --no-ff -m "Merge pull request #$3 from someone/$2" "$2"
}

sync() { python3 "$SYNC" "$@"; }
field() { printf '%s' "$1" | jq -r "$2"; }

# --- 1. unambiguous merge: the stale row goes to done --------------------
U=$(new_repo univocal <<'EOF'
# Lots

| Lot | Branche | Statut |
|---|---|---|
| 4 | `feat/lot-4-a` | ✅ |
| 5 | `feat/lot-5-…` | ⬜ |
| 6 | `feat/lot-6-…` | ⬜ |

## LOT 4 — Four ✅

## LOT 5 — Five ⬜

Scope of five.

## LOT 6 — Six ⬜
EOF
)
merge_pr "$U" feat/lot-4-a 11
merge_pr "$U" feat/lot-5-quotes 12
merge_sha=$(git -C "$U" rev-parse --short HEAD)

out=$(sync "$U"); rc=$?
assert_eq 0 "$rc" "univocal: exit 0"
assert_eq "5" "$(field "$out" '.updates[0].lot')" "univocal: lot 5 is detected as merged"
assert_eq "12" "$(field "$out" '.updates[0].pr')" "univocal: with its PR number"
assert_eq "$merge_sha" "$(field "$out" '.updates[0].sha')" "univocal: with its merge SHA"
assert_eq "6" "$(field "$out" '.candidate')" "univocal: the candidate is the next lot, lot 6"
assert_eq "0" "$(field "$out" '.stops | length')" "univocal: no stop"
assert_eq "false" "$(field "$out" '.changed')" "univocal: a dry run writes nothing"
assert_ok "univocal: lots file untouched by the dry run" -- git -C "$U" diff --quiet

# The skill's Part B, on the lot branch, after the confirmation.
git -C "$U" switch -qc feat/lot-6-next develop
out=$(sync "$U" --apply --start 6); rc=$?
assert_eq 0 "$rc" "apply: exit 0"
assert_eq "true" "$(field "$out" '.changed')" "apply: the file changed"
assert_eq "6" "$(field "$out" '.started')" "apply: lot 6 started"
assert_ok "apply: row 5 is done" -- grep -qF '| 5 | `feat/lot-5-…` | ✅ |' "$U/lots.md"
assert_ok "apply: row 6 is in progress" -- grep -qF '| 6 | `feat/lot-6-…` | 🔄 |' "$U/lots.md"
assert_ok "apply: heading 5 is done" -- grep -qx '## LOT 5 — Five ✅' "$U/lots.md"
assert_ok "apply: heading 6 is in progress" -- grep -qx '## LOT 6 — Six 🔄' "$U/lots.md"
assert_ok "apply: the merged line opens section 5" -- \
  grep -qF "**Mergé** le $(date +%Y-%m-%d) (PR #12, merge \`$merge_sha\`)." "$U/lots.md"
assert_eq "**Merg" \
  "$(awk '/^## LOT 5/ { getline; getline; print substr($0, 1, 6); exit }' "$U/lots.md")" \
  "apply: the merged line sits right under the heading"
assert_ok "apply: row 4 untouched" -- grep -qF '| 4 | `feat/lot-4-a` | ✅ |' "$U/lots.md"
assert_eq "1" "$(grep -c 'Mergé' "$U/lots.md")" "apply: exactly one merged line"
if ! git -C "$U" diff --quiet; then
  git -C "$U" add lots.md
  git -C "$U" commit -qm "docs: sync lots file status"
fi
assert_eq "docs: sync lots file status" \
  "$(git -C "$U" log --reverse --format=%s develop..HEAD | head -1)" \
  "the first commit of the lot branch is the sync commit"

# --- 2. already up to date: nothing to write, nothing to commit -----------
before=$(sha256sum "$U/lots.md")
out=$(sync "$U" --apply --start 6); rc=$?
assert_eq 0 "$rc" "up to date: exit 0"
assert_eq "false" "$(field "$out" '.changed')" "up to date: nothing changed"
assert_eq "$before" "$(sha256sum "$U/lots.md")" "up to date: the file is byte-identical"
assert_ok "up to date: nothing to commit" -- git -C "$U" diff --quiet

# --- 3. paused and frozen lots are skipped for the candidate --------------
P=$(new_repo paused <<'EOF'
| Lot | Branche | Statut |
|---|---|---|
| 7 | `feat/lot-7-a` | ⏸️ |
| 8 | `feat/lot-8-b` | ❄️ |
| 9 | `feat/lot-9-c` | ⬜ |
EOF
)
out=$(sync "$P")
assert_eq "9" "$(field "$out" '.candidate')" "paused and frozen rows are not candidates"

# --- 4. a done row with no trace on develop is a stop ---------------------
D=$(new_repo done-no-merge <<'EOF'
| Lot | Branche | Statut |
|---|---|---|
| 3 | `feat/lot-3-x` | ✅ |
| 4 | `feat/lot-4-y` | ⬜ |
| 7 | `chore/harness-adoption` (kb) | ✅ |
EOF
)
out=$(sync "$D" --apply); rc=$?
assert_eq 3 "$rc" "done without merge: exit 3"
assert_eq "done-without-merge" "$(field "$out" '.stops[0].kind')" "done without merge: stop kind"
assert_contains "$(field "$out" '.stops[0].detail')" "lot 3" "done without merge: names the lot"
assert_eq "1" "$(field "$out" '.stops | length')" "a branch of another repository is not checked"
# A commit scoped to the lot is enough evidence (rebase or squash merge).
git -C "$D" commit -q --allow-empty -m "feat(3): shipped by rebase"
out=$(sync "$D"); rc=$?
assert_eq 0 "$rc" "a scoped commit on develop is evidence enough"
# So is a range scope covering the lot.
D2=$(new_repo done-range <<'EOF'
| Lot | Branche | Statut |
|---|---|---|
| 2b | `feat/lot-0-6-foundation` | ✅ |
| 7 | `feat/lot-7-z` | ⬜ |
EOF
)
git -C "$D2" commit -q --allow-empty -m "docs(0-6): foundation reports"
out=$(sync "$D2"); rc=$?
assert_eq 0 "$rc" "a range scope covers a lettered lot inside it"

# --- 5. a lot-shaped merge with no row is a stop --------------------------
M=$(new_repo merge-no-lot <<'EOF'
| Lot | Branche | Statut |
|---|---|---|
| 1 | `feat/lot-1-a` | ⬜ |
EOF
)
merge_pr "$M" feat/lot-42-stray 3
merge_pr "$M" chore/tidy 4
out=$(sync "$M"); rc=$?
assert_eq 3 "$rc" "merge without lot: exit 3"
assert_eq "merge-without-lot" "$(field "$out" '.stops[0].kind')" "merge without lot: stop kind"
assert_eq "1" "$(field "$out" '.stops | length')" "a chore/* merge is not a lot"

# --- 6. the candidate's scope already merged is a stop --------------------
S=$(new_repo scope-merged <<'EOF'
| Lot | Branche | Statut |
|---|---|---|
| 5 | `feat/lot-5-a` | ⬜ |
EOF
)
git -C "$S" commit -q --allow-empty -m "feat(5): half of lot 5, rebased"
out=$(sync "$S"); rc=$?
assert_eq 3 "$rc" "scope already merged: exit 3"
assert_eq "scope-already-merged" "$(field "$out" '.stops[0].kind')" "scope already merged: stop kind"

# --- 7. not harnessed: exit 2 ---------------------------------------------
N="$WORK/plain"
mkdir -p "$N" && git -C "$N" init -q -b develop
printf '# P\n' > "$N/CLAUDE.md"
sync "$N" >/dev/null; rc=$?
assert_eq 2 "$rc" "no Gate parameters: exit 2"

# --- 7b. a stop answered by the user and cited by SHA does not come back ---
R=$(new_repo reconciled <<'EOF'
# Lots

| Lot | Branche | Statut |
|---|---|---|
| 2.1 | `feat/lot-2-quotes` | ✅ |
| 2.2 | `feat/lot-2-quotes` | ⬜ |
EOF
)
merge_pr "$R" feat/lot-2-quotes 3
out=$(sync "$R"); rc=$?
assert_eq 3 "$rc" "reconciled: the shared-branch merge stops while unanswered"
printf '\n2.1 livré par la merge `%s`.\n' "$(git -C "$R" rev-parse --short HEAD)" >> "$R/lots.md"
out=$(sync "$R" --apply --start 2.2); rc=$?
assert_eq 0 "$rc" "reconciled: the cited merge no longer stops"
assert_eq "2.2" "$(field "$out" '.started')" "reconciled: the next sub-lot can start"

# --- 8. replay of the 2026-09-21 incident ---------------------------------
I=$(new_repo incident <<'EOF'
# Lots

| Lot | Branche | Statut |
|---|---|---|
| 1 | `feat/lot-1-init` | ✅ |
| 2 | `feat/lot-2-quotes` | ⬜ |

## LOT 1 — Init ✅

## LOT 2 — Quotes ⬜

### LOT-2.1 — Totals

### LOT-2.2 — PDF export
EOF
)
merge_pr "$I" feat/lot-1-init 1
merge_pr "$I" feat/lot-2-quote-totals 2
before=$(sha256sum "$I/lots.md")
out=$(sync "$I" --apply); rc=$?
assert_eq 3 "$rc" "incident: lot-start stops"
assert_eq "ambiguous" "$(field "$out" '.stops[0].kind')" "incident: on the ambiguous sub-lot mapping"
assert_contains "$(field "$out" '.stops[0].detail')" "which lots does it complete?" \
  "incident: as a question for the user"
assert_eq "$before" "$(sha256sum "$I/lots.md")" "incident: --apply writes nothing while a stop is pending"
assert_eq "[]" "$(field "$out" '.updates' | jq -c .)" "incident: nothing decided for the user"

# No write into src/ before the user types the confirmation.
git -C "$I" switch -qc feat/lot-2-pdf-export develop
guard() {
  local out
  out=$(jq -nc --arg f "$I/src/Pdf.java" --arg d "$I" \
    '{tool_name:"Write", tool_input:{file_path:$f}, cwd:$d}' | python3 "$HOOKS/lot-lock-guard.py")
  [ -z "$out" ] && { printf 'pass'; return; }
  printf '%s' "$out" | jq -r '.hookSpecificOutput.permissionDecision'
}
assert_eq deny "$(guard)" "incident: src/ is locked before the confirmation"
# The model saying it is confirmed changes nothing: only the user's prompt does.
jq -nc --arg d "$I" '{prompt:"lot-start confirm 2", cwd:$d}' | bash "$HOOKS/lot-confirm.sh" >/dev/null
assert_eq pass "$(guard)" "incident: src/ opens once the user typed lot-start confirm 2"


# --- 9. a lot merged by rebase: its audit commit on develop closes the row --
# commit_on <repo> <subject> : one first-parent commit on develop, as a rebase
# merge of the lot pull request leaves it (no merge commit at all).
commit_on() {
  printf '%s\n' "$2" >> "$1/src/rebased.txt"
  git -C "$1" add -A
  git -C "$1" commit -qm "$2"
}
R=$(new_repo rebased <<'EOF'
# Lots

| Lot | Branche | Statut |
|---|---|---|
| 5 | `feat/lot-5-…` | 🔄 |
| 6 | `feat/lot-6-…` | ⬜ |

## LOT 5 — Five 🔄

## LOT 6 — Six ⬜
EOF
)
commit_on "$R" "feat(5): the work"
out=$(sync "$R"); rc=$?
assert_eq 0 "$rc" "rebased: exit 0"
assert_eq "0" "$(field "$out" '.updates | length')" "rebased: no audit commit yet, the lot stays open"
assert_eq "5" "$(field "$out" '.in_progress[0]')" "rebased: lot 5 still in progress"
commit_on "$R" "docs(5): add the lot audit report"
audit_sha=$(git -C "$R" rev-parse --short HEAD)
out=$(sync "$R" --apply); rc=$?
assert_eq 0 "$rc" "rebased: apply exits 0"
assert_eq "5" "$(field "$out" '.updates[0].lot')" "rebased: the audit commit marks lot 5 merged"
assert_eq "audit" "$(field "$out" '.updates[0].evidence')" "rebased: with the audit commit as evidence"
assert_eq "6" "$(field "$out" '.candidate')" "rebased: the candidate moves to lot 6"
assert_ok "rebased: row 5 is done" -- grep -qF '| 5 | `feat/lot-5-…` | ✅ |' "$R/lots.md"
assert_ok "rebased: heading 5 is done" -- grep -qx '## LOT 5 — Five ✅' "$R/lots.md"
assert_ok "rebased: the note cites the audit commit" -- \
  grep -qF "(commit d'audit \`$audit_sha\`)" "$R/lots.md"
git -C "$R" commit -qam "docs: sync lots file status"
out=$(sync "$R" --apply); rc=$?
assert_eq "0 false" "$rc $(field "$out" '.changed')" "rebased: a second run changes nothing"

# --- 10. sub-lots listed in the row close one by one, then the row --------
S=$(new_repo sublots <<'EOF'
# Lots

| Lot | Branche | Statut | Objet |
|---|---|---|---|
| 3 | `feat/lot-3-…` | 🔄 | Media (3.1 ✅, 3.2 🔄, 3.3 ⬜) |
| 4 | `feat/lot-4-…` | ⬜ | Next |

## LOT 3 — Media

### LOT-3.1 — Storage ✅

### LOT-3.2 — Endpoints 🔄

### LOT-3.3 — Robustness ⬜

## LOT 4 — Next ⬜
EOF
)
commit_on "$S" "docs(3.1): add the lot audit report"
commit_on "$S" "docs(3.2): add the lot audit report"
out=$(sync "$S" --apply); rc=$?
assert_eq 0 "$rc" "sub-lots: exit 0"
assert_eq "3.2" "$(field "$out" '.sub_updates[0].lot')" "sub-lots: 3.2 is marked merged"
assert_eq "0" "$(field "$out" '.updates | length')" "sub-lots: row 3 stays open while 3.3 is pending"
assert_ok "sub-lots: the row marks 3.2 done" -- grep -qF '(3.1 ✅, 3.2 ✅, 3.3 ⬜)' "$S/lots.md"
assert_ok "sub-lots: row 3 still in progress" -- grep -qF '| 3 | `feat/lot-3-…` | 🔄 |' "$S/lots.md"
assert_ok "sub-lots: heading 3.2 is done" -- grep -qx '### LOT-3.2 — Endpoints ✅' "$S/lots.md"
git -C "$S" commit -qam "docs: sync lots file status"
commit_on "$S" "docs(3.3): add the lot audit report"
out=$(sync "$S" --apply); rc=$?
assert_eq "3" "$(field "$out" '.updates[0].lot')" "sub-lots: the last audit closes row 3"
assert_eq "4" "$(field "$out" '.candidate')" "sub-lots: the candidate moves to lot 4"
assert_ok "sub-lots: row 3 is done" -- grep -qF '| 3 | `feat/lot-3-…` | ✅ | Media (3.1 ✅, 3.2 ✅, 3.3 ✅) |' "$S/lots.md"

# --- 11. a sub-lot the row does not list is a stop, not a guess -----------
X=$(new_repo unlisted <<'EOF'
# Lots

| Lot | Branche | Statut | Objet |
|---|---|---|---|
| 3 | `feat/lot-3-…` | 🔄 | Media (3.1 🔄) |

### LOT-3.1 — Storage 🔄

### LOT-3.2 — Endpoints ⬜
EOF
)
commit_on "$X" "docs(3.1): add the lot audit report"
before=$(sha256sum "$X/lots.md")
out=$(sync "$X" --apply); rc=$?
assert_eq 3 "$rc" "unlisted: exit 3"
assert_eq "ambiguous" "$(field "$out" '.stops[0].kind')" "unlisted: asked, not decided"
assert_contains "$(field "$out" '.stops[0].detail')" "3.2" "unlisted: the stop names the missing sub-lot"
assert_eq "$before" "$(sha256sum "$X/lots.md")" "unlisted: nothing written"

finish
