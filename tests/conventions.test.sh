#!/usr/bin/env bash
# Structure of the conventions master (lots 5 and 24): every repository's copy
# is compared against it, the skills cite it by section number and by rule
# identifier, and it stays short. What a rule says is reviewed, not grepped.
set -uo pipefail
. "$(dirname "$0")/lib.sh"

C="$REPO_ROOT/CONVENTIONS.md"
assert_file "$C" "the harness carries the conventions master"

# --- sections and identifiers ----------------------------------------------
for n in 1 2 2.5 3 4 5 6 7 8 9 10 11 12 13 14 15; do
  assert_ok "section $n exists" -- grep -qE "^## ${n}[.] |^## ${n} " "$C"
done
while IFS= read -r ref; do
  assert_ok "the section $ref cited in the master exists" -- \
    grep -qE "^## ${ref}[.] |^## ${ref} " "$C"
done < <(grep -oE '§[0-9]+(\.[0-9]+)?' "$C" | tr -d '§' | sort -u)

ids=$(grep -oE '^- \*\*[A-Z]+-[0-9]+\*\* ' "$C" | sed -E 's/^- \*\*(.*)\*\* $/\1/')
assert_ok "every rule carries an identifier" -- test -n "$ids"
assert_eq "" "$(printf '%s\n' "$ids" | sort | uniq -d)" "no identifier is used twice"
assert_eq "" "$(grep -E '^- ' "$C" | grep -vE '^- \*\*[A-Z]+-[0-9]+\*\* ' || true)" \
  "every list item is an identified rule"
# A rule cites another by its identifier: each cited one must exist.
while IFS= read -r ref; do
  assert_ok "the rule $ref cited in the master exists" -- grep -qE "^- \*\*$ref\*\* " "$C"
done < <(grep -oE '\b(CODE|LOT|GATE|ASK|SEC|API|GIT|DOC|START|CTX|PLUG|PROF|OUT)-[0-9]+\b' "$C" | sort -u)

# --- the rules other machinery reads ---------------------------------------
# The eleven parameters, spelled as harness-invariants.yml greps for them.
for p in Stack "Validation command" "Coverage tool" "Coverage threshold" \
         "Coverage exclusions" "Migrations directory" "Lots file" \
         "Frontend backend pair" "Health path" "Dist forbidden pattern" "Image name"; do
  assert_ok "section 12 lists the '$p' parameter" -- grep -qF "\`$p\`" "$C"
done
# One list of commit types: the master's is commit-format.yml's default.
types=$(grep -oE '^- \*\*GIT-2\*\* .*' "$C" | grep -oE 'type one of [^.]*' | grep -oE '`[a-z]+`' | tr -d '`' | paste -sd'|')
assert_eq "$types" \
  "$(sed -n 's/^ *default: "\(feat|[a-z|]*\)"$/\1/p' "$REPO_ROOT/.github/workflows/commit-format.yml")" \
  "the commit types of GIT-2 are the default of commit-format.yml"
assert_eq "$types" \
  "$(grep -E '^- `<type>`:' "$REPO_ROOT/plugins/claude-harness/skills/lot-ship/SKILL.md" | grep -oE '`[a-z]+`' | tr -d '`' | paste -sd'|')" \
  "lot-ship lists the same commit types"

# --- short, rules only, English (section 11 applies to itself) ------------
assert_ok "the master stays within 14000 bytes" -- test "$(wc -c < "$C")" -le 14000
assert_eq "" "$(grep -niE 'incident|20[0-9]{2}-[0-9]{2}-[0-9]{2}' "$C" || true)" \
  "the master carries no incident narrative and no dated story"
assert_eq "" "$(grep -cE '\b(le |la |les |une |des |dans |pour |avec )' "$C" \
  | grep -v '^0$' || true)" \
  "the master carries no French prose"

finish
