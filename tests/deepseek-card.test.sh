#!/usr/bin/env bash
# The deepseek card chooses rules by identifier and takes their text from
# CONVENTIONS.md (lot 24): the committed card must be exactly its generation,
# and must fit the SessionStart hook's budget.
set -uo pipefail
. "$(dirname "$0")/lib.sh"

GEN="$REPO_ROOT/.github/scripts/deepseek-card.py"
CARD="$REPO_ROOT/plugins/claude-harness/rules/deepseek.json"
WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT

assert_ok "the committed card is its generation from CONVENTIONS.md" -- python3 "$GEN" --check
assert_eq "OUT-0 OUT-1" "$(jq -r '[.rules[].id | select(startswith("OUT-"))] | join(" ")' "$CARD")" \
  "the completeness floor comes before the length rule"

# A copy of the tree the generator reads, to break it on purpose.
tree() {
  rm -rf "$WORK/t"
  mkdir -p "$WORK/t/.github/scripts" "$WORK/t/plugins/claude-harness/rules" "$WORK/t/plugins/claude-harness/hooks"
  cp "$GEN" "$WORK/t/.github/scripts/"
  cp "$REPO_ROOT/CONVENTIONS.md" "$WORK/t/"
  cp "$CARD" "$WORK/t/plugins/claude-harness/rules/"
  cp "$REPO_ROOT/plugins/claude-harness/hooks/session-context.sh" "$WORK/t/plugins/claude-harness/hooks/"
}
check() { python3 "$WORK/t/.github/scripts/deepseek-card.py" --check 2>&1; echo "|$?"; }

tree
sed -i 's/^- \*\*OUT-1\*\* No preamble/- **OUT-1** Never a preamble/' "$WORK/t/CONVENTIONS.md"
out=$(check)
assert_eq "1" "${out##*|}" "a rule edited in CONVENTIONS.md and not regenerated fails"
assert_contains "$out" "differs from CONVENTIONS.md" "and says so"
python3 "$WORK/t/.github/scripts/deepseek-card.py"
assert_eq "0" "$(check | sed 's/.*|//')" "regenerating brings the card back in line"

tree
jq '.rules += [{"id": "NOPE-1", "rule": ""}]' "$CARD" > "$WORK/t/plugins/claude-harness/rules/deepseek.json"
out=$(check)
assert_eq "1" "${out##*|}" "a card naming an unknown rule fails"
assert_contains "$out" "NOPE-1" "and names it"

tree
sed -i 's/^CAP=[0-9]*/CAP=6000/' "$WORK/t/plugins/claude-harness/hooks/session-context.sh"
out=$(check)
assert_eq "1" "${out##*|}" "a card over the hook budget fails"
assert_contains "$out" "over its budget" "and says so"

finish
