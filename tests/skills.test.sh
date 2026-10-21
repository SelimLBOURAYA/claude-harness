#!/usr/bin/env bash
# Structure of the plugin skills: frontmatter, no user path, no legacy path, no
# hard-coded gate command or threshold, and every file a skill names beside
# itself present. What a skill says is reviewed, not grepped (lot 24).
set -uo pipefail
. "$(dirname "$0")/lib.sh"

SKILLS="$REPO_ROOT/plugins/claude-harness/skills"

# Skills that drive the lot gate. They must read everything from the repo's
# Gate parameters. dep-update is excluded from the command check: its whole job
# is to drive a package manager, selected by Stack. i-have-adhd is an output
# style, generic and unrelated to any gate.
GATE_SKILLS="lot-start lot-test lot-review lot-audit lot-ship harness-sync integration-check"
ALL_SKILLS="$GATE_SKILLS dep-update bootstrap-project i-have-adhd"

assert_eq "$(printf '%s\n' $ALL_SKILLS | sort | tr '\n' ' ')" \
  "$(find "$SKILLS" -mindepth 1 -maxdepth 1 -type d -printf '%f\n' | sort | tr '\n' ' ')" \
  "the plugin ships exactly the listed skills"

for skill in $ALL_SKILLS; do
  dir="$SKILLS/$skill"
  file="$dir/SKILL.md"
  assert_file "$file" "$skill ships a SKILL.md"
  [ -f "$file" ] || continue

  # Frontmatter: delimited, and the declared name matches the directory.
  assert_eq "---" "$(head -1 "$file")" "$skill frontmatter opens on line 1"
  assert_eq "$skill" "$(sed -n 's/^name: *//p' "$file" | head -1)" \
    "$skill declares its own name"
  assert_ok "$skill has a description" -- grep -q '^description:' "$file"

  # The description is what makes a skill fire at the right moment; an empty
  # or one-word one is the "vague trigger" drift harness-sync reports.
  body=$(sed -n '/^description:/,/^[a-z-]*:/p' "$file" | wc -c)
  [ "$body" -gt 80 ] || assert_eq "long" "short" "$skill description is substantial"

  # No absolute user path baked into a shared skill. Two are allowed because
  # they are the documented locations themselves: the harness clone that
  # non-Claude agents read, and the claude-profile script named in section 4
  # of CONVENTIONS.md.
  assert_eq "" "$(grep -n '/home/[a-z]*/' "$file" \
    | grep -v 'ENV/projets/claude-harness' \
    | grep -v '\.local/bin/claude-profile' || true)" \
    "$skill has no absolute user path beyond the two documented ones"

  # No legacy skill/ directory reference (finding #1).
  assert_eq "" "$(grep -nE '(^|[^.a-z/])skill/[a-z-]+/SKILL\.md' "$file" || true)" \
    "$skill references no legacy skill/ path"

  # Every file the skill names beside itself exists: the scripts it runs from
  # its base directory, and the relative links of its text.
  while IFS= read -r ref; do
    [ -n "$ref" ] || continue
    assert_ok "$skill: the referenced $ref exists" -- test -e "$dir/${ref%%#*}"
  done < <({
    grep -oE "<this skill's base directory>/[A-Za-z0-9_./-]+" "$file" \
      | sed "s#^<this skill's base directory>/##"
    grep -oE '\]\([A-Za-z0-9_./#-]+\)' "$file" | sed -E 's#^\]\((.*)\)$#\1#'
  } | sort -u)
done

# --- no hard-coded gate command or threshold -----------------------------
for skill in $GATE_SKILLS; do
  file="$SKILLS/$skill/SKILL.md"
  [ -f "$file" ] || continue

  assert_eq "" "$(grep -nE '\./mvnw verify|npm test|npm run test' "$file" || true)" \
    "$skill does not hard-code a validation command"
  assert_eq "" "$(grep -nE '0\.(70|75|79|80)|\b(70|79|80) ?%' "$file" || true)" \
    "$skill does not hard-code a coverage threshold"
done

# --- the project memory (lot 26, MEM-1) -----------------------------------
# Three skills in three sessions share one file and one commit title: those
# names are the contract between them, so they are checked, not reviewed.
MEM_TPL="$REPO_ROOT/templates/project/docs/memory.md"
MEM_OWN="$REPO_ROOT/docs/memory.md"
cap=$(grep -E '^- \*\*MEM-1\*\* ' "$REPO_ROOT/CONVENTIONS.md" | grep -oE 'at most [0-9]+ characters' | grep -oE '[0-9]+')
assert_eq "6000" "$cap" "MEM-1 caps the memory at 6000 characters"
header() { sed '/^## /,$d' "$1"; }
for mem in "$MEM_TPL" "$MEM_OWN"; do
  assert_file "$mem" "${mem#"$REPO_ROOT"/} exists"
  [ -f "$mem" ] || continue
  assert_ok "${mem#"$REPO_ROOT"/} stays within the cap" -- test "$(wc -m < "$mem")" -le "${cap:-0}"
  assert_eq "## Code map|## Decisions|## Pitfalls|## Open questions" \
    "$(grep '^## ' "$mem" | paste -sd'|')" "${mem#"$REPO_ROOT"/} has the four sections, in order"
done
assert_contains "$(header "$MEM_TPL")" "not the truth: the code and git are" \
  "the template header says the notes are not the truth"
assert_contains "$(header "$MEM_TPL")" "MEM-1" "the template header cites its rule"
assert_eq "$(header "$MEM_TPL")" "$(header "$MEM_OWN")" \
  "the harness memory keeps the template header verbatim"
assert_eq "" "$(sed '1,/^## /d' "$MEM_TPL" | grep -vE '^(## .*)?$' || true)" \
  "the template sections are empty"
for claude in "$REPO_ROOT/CLAUDE.md" "$REPO_ROOT/templates/project/CLAUDE.md"; do
  assert_ok "${claude#"$REPO_ROOT"/} lists docs/memory.md in its census" -- \
    grep -qF '| [`docs/memory.md`](docs/memory.md) |' "$claude"
done
for skill in lot-start lot-test lot-review; do
  assert_ok "$skill names docs/memory.md" -- grep -qF 'docs/memory.md' "$SKILLS/$skill/SKILL.md"
done
assert_ok "lot-start names its close in its description" -- \
  grep -qF 'lot-start close N' <<< "$(sed -n '/^description:/,/^metadata:/p' "$SKILLS/lot-start/SKILL.md")"
assert_ok "lot-start commits the memory under its title" -- \
  grep -qF 'commit -m "docs(N): update the project memory"' "$SKILLS/lot-start/SKILL.md"
# lot-test measures its boundary from its own starting point, never from the
# memory commit, which exists only when the memory changed.
assert_ok "lot-test notes its starting point" -- \
  grep -qF 'START=$(git rev-parse HEAD)' "$SKILLS/lot-test/SKILL.md"
assert_ok "lot-test checks its boundary from that point" -- \
  grep -qF 'git diff --name-only "$START" HEAD' "$SKILLS/lot-test/SKILL.md"
assert_ok "lot-test writes test files only" -- grep -qF 'test files only' "$SKILLS/lot-test/SKILL.md"
assert_eq "" "$(grep -n 'update the project memory' "$SKILLS/lot-test/SKILL.md" || true)" \
  "lot-test does not require the memory commit"
assert_ok "lot-review checks the test(N) commits" -- \
  grep -qF -- "--grep='^test('" "$SKILLS/lot-review/SKILL.md"

# i-have-adhd stays user-invoked only.
assert_ok "i-have-adhd is never model-invoked" -- \
  grep -q '^disable-model-invocation: true' "$SKILLS/i-have-adhd/SKILL.md"

finish
