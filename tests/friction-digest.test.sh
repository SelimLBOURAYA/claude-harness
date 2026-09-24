#!/usr/bin/env bash
# Runs the harness-sync friction digest on fixture repositories (lot 21).
# Executed, not grepped: three lots of friction, a harness lots file that plans,
# merges or ignores their corrections, and the drafts the digest proposes.
set -uo pipefail
. "$(dirname "$0")/lib.sh"

DIGEST="$REPO_ROOT/plugins/claude-harness/skills/harness-sync/friction-digest.py"
WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT

digest() { python3 "$DIGEST" "$@"; }
field() { printf '%s' "$1" | jq -r "$2"; }

# friction <repo> <lot> <date> : friction file read from stdin, committed at <date>.
friction() {
  mkdir -p "$1/docs/audits"
  cat > "$1/docs/audits/lot-$2-friction.md"
  git -C "$1" add -A
  GIT_COMMITTER_DATE="$3T12:00:00" GIT_AUTHOR_DATE="$3T12:00:00" \
    git -C "$1" commit -qm "docs($2): record the friction"
}

P="$WORK/project"
mkdir -p "$P"
git -C "$P" init -q -b develop
git -C "$P" config user.email test@example.com
git -C "$P" config user.name Test
printf '# P\n\n## Gate parameters\n\n| Parameter | Value |\n|---|---|\n| `Lots file` | `lots.md` |\n' > "$P/CLAUDE.md"
printf '# Lots\n\n| Lot | Branche | Statut |\n|---|---|---|\n| 1 | `feat/lot-1-a` | ✅ |\n' > "$P/lots.md"
git -C "$P" add -A
git -C "$P" commit -qm "docs: seed"

friction "$P" 1 2026-09-01 <<'EOF'
# Lot 1 — Skill friction

## lot-start
- `lot-start / A3` — the rebase merge of lot 0 was not seen; the row stayed
  in progress. Cost: one question.

## lot-test
- `lot-test / 3.1` — the coverage report was not where the gate parameters say.

## lot-review
None.

## lot-audit
None.

## lot-ship
None.
EOF

friction "$P" 2 2026-09-10 <<'EOF'
# Lot 2 — Skill friction

## lot-start
- `lot-start / A3` — same rebase blind spot on lot 1.

## lot-test
None.

## lot-review
- `lot-review / Step 4` — the template has no place for a rejected finding.

## lot-audit
None.

## lot-ship
None.
EOF

friction "$P" 3 2026-09-20 <<'EOF'
# Lot 3 — Skill friction

## lot-start
None.

## lot-test
- `lot-test / 3.1` — the coverage report moved again.

## lot-review
None.

## lot-ship
None.
EOF

H="$WORK/harness-plan.md"

# --- 1. nothing cited: every key is open, one draft per skill -------------
printf '# Plan\n\n## LOT 9 — unrelated ⬜\n\nNothing here.\n' > "$H"
before=$(git -C "$P" status --porcelain; md5sum "$H")
out=$(digest "$P" --lots "$H"); rc=$?
assert_eq 0 "$rc" "open: exit 0"
assert_eq "3" "$(field "$out" '.files | length')" "open: three friction files read"
assert_eq "lot-audit" "$(field "$out" '.files[] | select(.lot=="3") | .missing_sections | join(",")')" \
  "open: the missing lot-audit section of lot 3 is reported"
assert_eq "3" "$(field "$out" '.keys | length')" "open: three distinct keys"
assert_eq "2" "$(field "$out" '.keys[] | select(.key=="lot-start / A3") | .occurrences | length')" \
  "open: a key seen in two lots is grouped once"
assert_eq "open open open" "$(field "$out" '[.keys[].status] | join(" ")')" \
  "open: no lots file cites a key"
assert_eq "lot-review lot-start lot-test" "$(field "$out" '[.drafts[].skill] | join(" ")')" \
  "open: one draft per skill"
assert_eq "claude-harness/dev-plan.md" "$(field "$out" '.drafts[0].target')" \
  "open: a gate skill draft targets the harness plan"
assert_eq "1,3" "$(field "$out" '.drafts[] | select(.skill=="lot-test") | .lots | join(",")')" \
  "open: a draft names the lots its keys came from"
assert_contains "$(field "$out" '.keys[] | select(.key=="lot-start / A3") | .occurrences[0].text')" \
  "row stayed in progress" "open: a wrapped entry keeps its continuation line"
assert_eq "1 2 3" "$(field "$out" '.window | join(" ")')" "open: the window covers every live lot"
assert_eq "$before" "$(git -C "$P" status --porcelain; md5sum "$H")" \
  "open: the digest writes nothing"

# --- 2. corrections planned, merged, and one that did not work ------------
cat > "$H" <<'EOF'
# Plan

## LOT 30 — See merges ✅

**Mergé** le 2026-09-15 sur `claude-harness` (PR #50).

Addresses `lot-start / A3`.

## LOT 31 — Coverage path ✅

**Mergé** le 2026-09-05 sur `claude-harness` (PR #51).

Addresses `lot-test / 3.1`.

## LOT 32 — Review template ⬜

Addresses `lot-review / Step 4`.
EOF
out=$(digest "$P" --lots "$H")
assert_eq "addressed" "$(field "$out" '.keys[] | select(.key=="lot-start / A3") | .status')" \
  "merged fix with no later occurrence: addressed"
assert_eq "30" "$(field "$out" '.keys[] | select(.key=="lot-start / A3") | .decided_by.lot')" \
  "addressed: names the lot that fixed it"
assert_eq "ineffective" "$(field "$out" '.keys[] | select(.key=="lot-test / 3.1") | .status')" \
  "a key back after its fix was merged: ineffective"
assert_eq "planned" "$(field "$out" '.keys[] | select(.key=="lot-review / Step 4") | .status')" \
  "a key cited by an unmerged lot: planned"
assert_eq "lot-test" "$(field "$out" '[.drafts[].skill] | join(" ")')" \
  "only the ineffective key produces a draft"
assert_eq "lot-test / 3.1" "$(field "$out" '.drafts[0].ineffective | join(",")')" \
  "the draft flags the ineffective correction"

# --- 3. the window keeps at least the last N lots --------------------------
assert_eq "1 2 3" "$(field "$out" '.window | join(" ")')" \
  "window: the live key's lots plus the three most recent"
out=$(digest "$P" --lots "$H" --min 1)
assert_eq "1 3" "$(field "$out" '.window | join(" ")')" \
  "window: --min 1 keeps the live lots and the latest one"

# --- 4. the project's own lots file counts as a citation source ------------
printf '\n## LOT 2 — Rejected friction ✅\n\nSet aside: `lot-test / 3.1`.\n' >> "$P/lots.md"
out=$(digest "$P")
assert_eq "planned" "$(field "$out" '.keys[] | select(.key=="lot-test / 3.1") | .status')" \
  "a key cited in the project lots file with no merge date is not re-proposed"
git -C "$P" checkout -q lots.md

# --- 5. not harnessed ------------------------------------------------------
mkdir -p "$WORK/bare" && git -C "$WORK/bare" init -q
digest "$WORK/bare" > /dev/null; rc=$?
assert_eq 2 "$rc" "a repository without Gate parameters exits 2"

finish
