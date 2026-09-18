#!/usr/bin/env bash
# Checks the plugin skills against the lot 2 validation criteria: valid
# frontmatter, no hard-coded validation command or coverage threshold, no
# legacy skill/ path, no sprint chaining, and a documented gate order.
set -uo pipefail
. "$(dirname "$0")/lib.sh"

SKILLS="$REPO_ROOT/plugins/claude-harness/skills"

# Skills that drive the lot gate. They must read everything from the repo's
# Gate parameters. dep-update is excluded from the command check: its whole job
# is to drive a package manager, selected by Stack. i-have-adhd is an output
# style, generic and unrelated to any gate.
GATE_SKILLS="lot-test lot-review lot-audit lot-ship harness-sync integration-check"
ALL_SKILLS="$GATE_SKILLS dep-update i-have-adhd"

for skill in $ALL_SKILLS; do
  file="$SKILLS/$skill/SKILL.md"
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

# The gate skills must actually read the parameters they refuse to hard-code.
for skill in lot-test lot-ship dep-update integration-check; do
  assert_ok "$skill reads the Gate parameters" -- \
    grep -q 'Gate parameters' "$SKILLS/$skill/SKILL.md"
done

# --- sprint chaining is gone (finding #4, "stop after PR") ---------------
assert_eq "absent" "$([ -d "$SKILLS/sprint" ] && echo present || echo absent)" \
  "the sprint skill is not shipped"
assert_ok "lot-ship stops after the PR" -- grep -q 'Stop after PR' "$SKILLS/lot-ship/SKILL.md"
# harness-sync names the phrase because it is the drift detector for it.
assert_eq "" "$(grep -rn 'chain the next lot' "$SKILLS" | grep -v '/harness-sync/' || true)" \
  "no skill chains the next lot"

# --- the gate order is documented identically everywhere -----------------
for skill in lot-test lot-audit lot-ship; do
  assert_ok "$skill documents the four-step gate order" -- \
    grep -qF 'lot-review' "$SKILLS/$skill/SKILL.md"
done
assert_ok "lot-audit refuses to run before lot-review" -- \
  grep -q 'lot-N-review.md' "$SKILLS/lot-audit/SKILL.md"

# --- lot 2b: the review skill and its profile guard ----------------------
REVIEW="$SKILLS/lot-review/SKILL.md"
# It must refuse to run under any profile but claude, on a runtime signal
# rather than on trust: the mid-session profile switch does not move the model.
assert_ok "lot-review checks ANTHROPIC_BASE_URL" -- \
  grep -q 'ANTHROPIC_BASE_URL' "$REVIEW"
assert_ok "lot-review names the deepseek endpoint it rejects" -- \
  grep -q 'api.deepseek.com' "$REVIEW"
assert_ok "lot-review tells the user to open a new session" -- \
  grep -q 'claude-profile claude' "$REVIEW"
assert_ok "lot-review forbids switching the profile itself" -- \
  grep -q 'Never attempt the switch yourself' "$REVIEW"
# It drives the generic review skill with both flags.
assert_ok "lot-review invokes the code-review skill" -- \
  grep -q 'Skill(code-review)' "$REVIEW"
assert_ok "lot-review posts inline comments and applies fixes" -- \
  grep -q -- '--comment --fix' "$REVIEW"
# Its deliverable is what lot-audit gates on, and it must be verifiable.
assert_ok "lot-review writes its deliverable" -- \
  grep -q 'lot-N-review.md' "$REVIEW"
assert_ok "lot-review records the reviewed SHA" -- \
  grep -q 'Reviewed at' "$REVIEW"
# It must not take over the next gate steps.
assert_ok "lot-review hands over instead of auditing" -- \
  grep -q 'Do not run the audit from this skill' "$REVIEW"
assert_eq "" "$(grep -n 'gh pr create' "$REVIEW" || true)" \
  "lot-review does not open the PR"
# harness-sync must enforce the new gate order and the deliverable ordering.
assert_ok "harness-sync checks the review deliverable precedes the audit one" -- \
  grep -q 'lot-N-review.md' "$SKILLS/harness-sync/SKILL.md"
assert_ok "harness-sync checks the documented gate order" -- \
  grep -qF 'lot-test → lot-review → lot-audit → lot-ship' "$SKILLS/harness-sync/SKILL.md"

# --- corrections the lot 2 table requires --------------------------------
# Finding #6: the security step calls the skill, not a non-existent subagent.
assert_ok "lot-audit invokes the security-review skill" -- \
  grep -q 'Skill(security-review)' "$SKILLS/lot-audit/SKILL.md"
assert_eq "" "$(grep -n 'subagent_type' "$SKILLS/lot-audit/SKILL.md" || true)" \
  "lot-audit no longer launches a security-review subagent"
# The checklist path must resolve from the skill directory.
assert_file "$SKILLS/lot-audit/checklists.md" "lot-audit ships its checklists"
assert_ok "lot-audit links its checklists" -- \
  grep -qF '(checklists.md)' "$SKILLS/lot-audit/SKILL.md"
# Finding #7: exclusions are reviewed, not trusted.
assert_ok "lot-audit reviews the coverage exclusions" -- \
  grep -q 'Coverage exclusions' "$SKILLS/lot-audit/SKILL.md"
# Finding #9 and P5-#8: migrations added only, expand/contract enforced.
assert_ok "lot-audit checks migration status A" -- \
  grep -q 'expand/contract' "$SKILLS/lot-audit/SKILL.md"
# The report must carry the harness SHA that produced it.
assert_ok "lot-audit report template carries the harness ref" -- \
  grep -q 'Harness ref' "$SKILLS/lot-audit/SKILL.md"
# Finding #3: a frontend PR needs its integration deliverable.
assert_ok "lot-ship requires the integration report on a frontend" -- \
  grep -q 'lot-0-integration.md' "$SKILLS/lot-ship/SKILL.md"
assert_ok "integration-check produces that deliverable" -- \
  grep -q 'lot-0-integration.md' "$SKILLS/integration-check/SKILL.md"
# P5-#11: no green light while a check is red.
assert_ok "lot-ship watches the CI checks" -- \
  grep -q 'gh pr checks --watch' "$SKILLS/lot-ship/SKILL.md"
# P5-#14: history reads bypass the rtk filter.
for skill in lot-audit lot-ship harness-sync; do
  assert_ok "$skill reads history through rtk proxy" -- \
    grep -q 'rtk proxy git log' "$SKILLS/$skill/SKILL.md"
done
# P6-D10 and P6-D14: lots file status table, memory freshness.
assert_ok "harness-sync checks the lots file status table" -- \
  grep -qF 'Statut' "$SKILLS/harness-sync/SKILL.md"
assert_ok "harness-sync checks memory freshness" -- \
  grep -q '60 days' "$SKILLS/harness-sync/SKILL.md"
# The marketplace ref is the single most dangerous thing to omit.
assert_ok "harness-sync requires the marketplace ref main" -- \
  grep -q '"ref": "main"' "$SKILLS/harness-sync/SKILL.md"
# i-have-adhd stays user-invoked only.
assert_ok "i-have-adhd is never model-invoked" -- \
  grep -q '^disable-model-invocation: true' "$SKILLS/i-have-adhd/SKILL.md"

finish
