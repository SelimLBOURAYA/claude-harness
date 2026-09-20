#!/usr/bin/env bash
# CONVENTIONS.md is the master (lot 5): every repository's copy is compared
# against it by harness-invariants.yml, and the skills cite it by section
# number. A renumbered or deleted section turns every one of those citations
# into a dangling reference that nothing else would catch.
set -uo pipefail
. "$(dirname "$0")/lib.sh"

C="$REPO_ROOT/CONVENTIONS.md"
assert_file "$C" "the harness carries the conventions master"

# --- it says, in the file itself, that it is the master -------------------
assert_ok "the master declares itself the master" -- \
  grep -qF '**Master: `claude-harness/CONVENTIONS.md`.**' "$C"
assert_ok "the master states the symlink that loads it into Claude Code" -- \
  grep -qF '`~/.claude/coding-conventions.md` is a **symlink**' "$C"
# The old master pointed the propagation the other way round; the reverse path
# is what let the copies drift in the first place.
assert_eq "" "$(grep -n 'coding-conventions.md` is the \*\*master' "$C" || true)" \
  "the master no longer names the user-level file as the master"

# --- every section a skill or a workflow cites must exist -----------------
for n in 1 2 2.5 3 4 5 6 7 8 9 10 11 12 13 14 15; do
  assert_ok "section $n exists" -- grep -qE "^## ${n}[.] |^## ${n} " "$C"
done

# A citation that points at a section number the file does not carry is the
# exact drift this suite exists to catch, and §15 shipped with one (§2.9).
while IFS= read -r ref; do
  assert_ok "the section $ref cited in the master exists" -- \
    grep -qE "^## ${ref}[.] |^## ${ref} " "$C"
done < <(grep -oE '§[0-9]+(\.[0-9]+)?' "$C" | tr -d '§' | sort -u)

# --- section 2: the stop after the PR, and the history read --------------
assert_ok "section 2 forbids chaining onto the next lot" -- \
  grep -qF '**No lot chaining.**' "$C"
assert_ok "section 2 reads history through the rtk proxy" -- \
  grep -qF 'rtk proxy git log --first-parent' "$C"

# --- section 2.5: an integration test hits a real engine ------------------
assert_ok "section 2.5 requires Testcontainers PostgreSQL" -- \
  grep -qF 'Testcontainers PostgreSQL' "$C"
assert_ok "section 2.5 rejects H2 with ddl-auto as an integration test" -- \
  grep -qE 'H2 with `ddl-auto: create-drop`.*is\s*\*\*not\*\*|ddl-auto: create-drop' "$C"

# --- section 4: the pre-authorised profile commands ----------------------
assert_ok "section 4 pre-authorises the two claude-profile commands" -- \
  grep -qF '/home/selim/.local/bin/claude-profile claude' "$C"
assert_ok "section 4 defers the self-initiated switch to section 14" -- \
  grep -qF 'see §14' "$C"

# --- section 7: the guards that are not the agent ------------------------
assert_ok "section 7 names the plugin git guard" -- \
  grep -qF 'git guard hook' "$C"
assert_ok "section 7 states that no repository has branch protection" -- \
  grep -qF '**No branch protection**' "$C"
assert_ok "section 7 states the red-PR rule that replaces it" -- \
  grep -qF 'never merge a pull request whose CI is red' "$C"
assert_ok "section 7 makes develop the GitHub default branch" -- \
  grep -qF '**GitHub default branch**' "$C"
assert_ok "section 7 states the expand/contract rule" -- \
  grep -qF '**Migrations — expand then contract**' "$C"
assert_ok "section 7 names the label the contract migration needs" -- \
  grep -qF 'schema-contract' "$C"
# The workflow that enforces it must exist under that exact name.
assert_file "$REPO_ROOT/.github/workflows/migrations-immutable.yml" \
  "the workflow section 7 cites exists"

# --- section 9: what a session reads, and what it must not re-read -------
assert_ok "section 9 forbids re-reading the conventions under Claude Code" -- \
  grep -qF 'do not re-read `CONVENTIONS.md`' "$C"
assert_ok "section 9 scopes the lots read to the status table" -- \
  grep -qF 'not the whole file' "$C"

# --- section 12: the contracts the workflows enforce ---------------------
assert_ok "section 12 mandates the Gate parameters table" -- \
  grep -qF '### Gate parameters' "$C"
# The eleven parameters, spelled as harness-invariants.yml greps for them.
for p in Stack "Validation command" "Coverage tool" "Coverage threshold" \
         "Coverage exclusions" "Migrations directory" "Lots file" \
         "Frontend backend pair" "Health path" "Dist forbidden pattern" "Image name"; do
  assert_ok "section 12 lists the '$p' parameter" -- grep -qF "\`$p\`" "$C"
done
assert_ok "section 12 requires n/a rather than an omitted row" -- \
  grep -qF 'never** an omitted row' "$C"
assert_ok "section 12 names the mirror hook, not the removed user-level one" -- \
  grep -qF '`mirror-sync` hook' "$C"
assert_eq "" "$(grep -n 'sync-claude-agents.sh' "$C" || true)" \
  "section 12 no longer points at the retired user-level mirror hook"
assert_ok "section 12 puts generic skills in the plugin" -- \
  grep -qF 'shipped by the `claude-harness` **plugin**' "$C"
# The claim the old master made that contradicted the plugin: skills "never
# stored outside the project or shared globally". The plugin does exactly that.
assert_eq "" "$(grep -n 'never stored outside the project' "$C" || true)" \
  "section 12 no longer forbids sharing skills globally"
assert_ok "section 12 points non-Claude agents at the local clone" -- \
  grep -qF 'ENV/projets/claude-harness/plugins/claude-harness/skills' "$C"
assert_ok "section 12 names the workflow that verifies propagation" -- \
  grep -qF 'harness-invariants.yml' "$C"

# --- section 13: the gate the skills implement ---------------------------
assert_ok "section 13 states the four-step gate order" -- \
  grep -qF 'lot-test  →  lot-review  →  lot-audit  →  lot-ship' "$C"
assert_ok "section 13 restricts lot-review to the claude profile" -- \
  grep -qF '**`claude` profile only**' "$C"
# Every skill named in section 13 must be a skill the plugin actually ships.
for s in lot-test lot-review lot-audit lot-ship harness-sync integration-check \
         dep-update bootstrap-project i-have-adhd; do
  assert_ok "section 13 names the shipped skill $s" -- grep -qF "$s" "$C"
  assert_file "$REPO_ROOT/plugins/claude-harness/skills/$s/SKILL.md" \
    "the plugin ships the $s skill section 13 names"
done

# --- section 14: the routing, and why it is a stop -----------------------
assert_ok "section 14 records that the switch does not move the running session" -- \
  grep -qF 'The switch does not move the running session' "$C"
assert_ok "section 14 forbids a self-initiated switch" -- \
  grep -qF '**The agent never switches profile on its own initiative.**' "$C"
assert_ok "section 14 places the stop before lot-review" -- \
  grep -qF 'before** `lot-review`' "$C"
assert_ok "section 14 names the runtime signal lot-review checks" -- \
  grep -qF 'ANTHROPIC_BASE_URL' "$C"
# The skill must actually perform that check, or section 14 is a promise only.
assert_ok "lot-review checks ANTHROPIC_BASE_URL as section 14 claims" -- \
  grep -qF 'ANTHROPIC_BASE_URL' \
  "$REPO_ROOT/plugins/claude-harness/skills/lot-review/SKILL.md"

# --- the master is English only (section 11 applies to itself) -----------
assert_eq "" "$(grep -cE '\b(le |la |les |une |des |dans |pour |avec )' "$C" \
  | grep -v '^0$' || true)" \
  "the master carries no French prose"

finish
