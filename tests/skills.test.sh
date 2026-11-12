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
# style and ponytail a coding rule, both generic and unrelated to any gate.
GATE_SKILLS="lot-start lot-test lot-review lot-audit lot-ship harness-sync integration-check"
ALL_SKILLS="$GATE_SKILLS dep-update bootstrap-project i-have-adhd ponytail"

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
  grep -qF -- "-p --grep='^test[(]'" "$SKILLS/lot-review/SKILL.md"

# Completion from the lot 26 specification: reading order, no empty commit,
# the skeleton mirror, and the rules that name the close.
START_SKILL="$SKILLS/lot-start/SKILL.md"
a2=$(sed -n '/^### Step A2/,/^### Step A3/p' "$START_SKILL")
assert_ok "lot-start reads the memory in step A2, before the candidate section" -- \
  test "$(grep -n 'docs/memory.md' <<< "$a2" | head -1 | cut -d: -f1)" -lt "$(grep -n 'candidate' <<< "$a2" | head -1 | cut -d: -f1)"
# Lot 30: the plugin of the repository is updated first, and only where the
# repository has its own project-scope install (elsewhere the CLI updates
# another project).
a0=$(sed -n '/^### Step A0/,/^### Step A1/p' "$START_SKILL")
assert_ok "lot-start step A0 comes before step A1" -- \
  test "$(grep -n '^### Step A0' "$START_SKILL" | cut -d: -f1)" -lt "$(grep -n '^### Step A1' "$START_SKILL" | cut -d: -f1)"
assert_contains "$a0" "claude plugin update claude-harness@claude-harness --scope project --json" \
  "lot-start step A0 updates the plugin at project scope"
assert_contains "$a0" '.scope == "project" and .projectPath == $p' \
  "lot-start step A0 updates only a repository with its own project-scope install"
assert_contains "$a0" "plugins/installed_plugins.json" \
  "lot-start step A0 reads the install records, not the repository settings"
assert_contains "$(grep -F '**Stop**' <<< "$a0")" "rerun the autopilot" \
  "lot-start step A0 tells the autopilot to stop blocked after an update"
assert_contains "$a0" "**Stop**" "lot-start step A0 stops when the version changed"
assert_contains "$(grep -F '**Stop**' <<< "$a0")" "reopen the session" \
  "lot-start step A0 tells the user to reopen the session after an update"
assert_contains "$(grep -F 'up_to_date' <<< "$a0")" "Go on" \
  "lot-start step A0 goes on when the plugin is up to date"
assert_contains "$(grep -F 'The command fails' <<< "$a0")" "go on" \
  "lot-start step A0 goes on when the update fails"
assert_eq "" "$(grep -E -- '--scope (user|local)' <<< "$a0" || true)" \
  "lot-start step A0 updates the project scope only"
assert_ok "lot-start step A0 runs the update verbatim, the autopilot's allowlist entry" -- \
  grep -qx 'claude plugin update claude-harness@claude-harness --scope project --json' <<< "$a0"
assert_contains "$(cat "$START_SKILL")" "Unchanged → no commit" "lot-start skips the memory commit when the file is unchanged"
assert_contains "$(cat "$START_SKILL")" "never an empty one" "lot-start never makes an empty memory commit"
assert_ok "the skeleton CLAUDE.md and AGENTS.md are byte-identical" -- \
  cmp -s "$REPO_ROOT/templates/project/CLAUDE.md" "$REPO_ROOT/templates/project/AGENTS.md"
conv_rule() { grep -E "^- \*\*$1\*\* " "$REPO_ROOT/CONVENTIONS.md"; }
assert_contains "$(conv_rule GATE-7)" "its close (MEM-1) → \`lot-test\`" "GATE-7 names the close before lot-test"
assert_contains "$(conv_rule LOT-7)" "test files only" "LOT-7 limits lot-test to test files"
assert_contains "$(conv_rule LOT-7)" "any profile" "LOT-7 lets lot-test run under any profile"
assert_contains "$(conv_rule MEM-1)" "6000 characters" "MEM-1 states the cap"

# --- the autopilot (lot 27) ------------------------------------------------
# lot-review and lot-audit sort every finding into three classes under the
# autopilot's signal; the script reads the outcome they write.
for skill in lot-review lot-audit; do
  section=$(sed -n '/^## Autopilot$/,/^## /p' "$SKILLS/$skill/SKILL.md")
  assert_contains "$section" "HARNESS_AUTOPILOT" "$skill: the Autopilot section keys on HARNESS_AUTOPILOT"
  for class in "**Fixed**" "**Ignored**" "**Exception**"; do
    assert_contains "$section" "$class" "$skill: the Autopilot section names the class $class"
  done
  assert_contains "$section" "rejected: minor (autopilot)" "$skill: an ignored finding keeps its row"
done

# --- integration-check under the autopilot (lot 32) -----------------------
# The command already ran; the session reads its log instead of replaying the
# manual steps, and its verdict may not contradict the exit code.
SECTION=$(sed -n '/^## Autopilot$/,/^## /p' "$SKILLS/integration-check/SKILL.md")
assert_contains "$SECTION" "HARNESS_AUTOPILOT" "integration-check: the Autopilot section keys on HARNESS_AUTOPILOT"
assert_contains "$SECTION" "Steps 1 to 3 are never replayed" "integration-check: the manual steps are not replayed"
assert_contains "$SECTION" "Read the log" "integration-check: the log feeds the report"
assert_contains "$SECTION" "\`Fail\` is forbidden" "integration-check: no Fail on a zero exit code"
assert_contains "$SECTION" "\`Pass\` is" "integration-check: no Pass on a partial scenario"
assert_contains "$SECTION" "contract comparison (Step 4) from that log" \
  "integration-check: the scenario and contract comparison come from the log"
assert_contains "$SECTION" "Step 6 only" "integration-check: the autopilot session runs Step 6 only"
assert_contains "$SECTION" "docs: add the integration check report" "integration-check: Step 6 commits the report"
DESC=$(sed -n '/^description:/,/^metadata:/p' "$SKILLS/integration-check/SKILL.md")
assert_eq "" "$(grep -i 'manual' <<< "$DESC" || true)" \
  "integration-check no longer calls itself manual"

# --- ponytail, the smallest complete change (lot 33, CODE-6) --------------
# The text is adapted from an MIT project, whose licence requires its notice.
PONY="$SKILLS/ponytail"
assert_ok "ponytail carries the upstream MIT notice" -- grep -q '^MIT License$' "$PONY/LICENSE"
assert_ok "the notice names the upstream copyright holder" -- \
  grep -q '^Copyright (c) 2026 DietrichGebert$' "$PONY/LICENSE"
assert_contains "$(conv_rule CODE-6)" "\`ponytail\` skill" "CODE-6 sends the reader to the ponytail skill"
for rule in GATE-3 LOT-4 OUT-0; do
  assert_contains "$(conv_rule CODE-6)" "$rule" "CODE-6 lets $rule win over ponytail"
done
# Every step that can write code cites the rule, for an agent that loads no hook.
for skill in lot-start lot-test lot-review lot-audit; do
  assert_ok "$skill cites CODE-6 where it writes code" -- grep -q 'CODE-6' "$SKILLS/$skill/SKILL.md"
done
assert_eq "" "$(jq -r '.rules[].id' "$REPO_ROOT/plugins/claude-harness/rules/deepseek.json" | grep -x 'CODE-6' || true)" \
  "CODE-6 stays off the deepseek card: the ponytail hook carries the whole text"

# i-have-adhd stays user-invoked only.
assert_ok "i-have-adhd is never model-invoked" -- \
  grep -q '^disable-model-invocation: true' "$SKILLS/i-have-adhd/SKILL.md"

finish
