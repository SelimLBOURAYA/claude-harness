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
GATE_SKILLS="lot-start lot-test lot-review lot-audit lot-ship harness-sync integration-check"
ALL_SKILLS="$GATE_SKILLS dep-update bootstrap-project i-have-adhd"

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
# Lot 18 / C3: the skill audited whatever repository the session happened to sit
# in. `Skill(security-review)` reads the working directory and takes no path, so
# seven lots got a security step that ran against the harness clone and said
# nothing about it. The skill must resolve the repository and refuse to guess.
assert_ok "lot-audit resolves the audited repository" -- \
  grep -q 'AUDIT_REPO=$(git rev-parse --show-toplevel)' "$SKILLS/lot-audit/SKILL.md"
assert_ok "lot-audit stops when the session is in another repository" -- \
  grep -q 'Step 0b' "$SKILLS/lot-audit/SKILL.md"
assert_ok "lot-audit scopes its history read to the audited repository" -- \
  grep -qF 'rtk proxy git -C "$AUDIT_REPO" log' "$SKILLS/lot-audit/SKILL.md"
assert_ok "lot-audit scopes its diff to the audited repository" -- \
  grep -qF 'git -C "$AUDIT_REPO" diff develop...HEAD' "$SKILLS/lot-audit/SKILL.md"
assert_ok "lot-audit writes the report inside the audited repository" -- \
  grep -qF '$AUDIT_REPO/docs/audits/lot-N.md' "$SKILLS/lot-audit/SKILL.md"
# A path derived from the session's own cwd cannot contradict itself: the stop
# needs a signal the session does not control, or it is a tautology that never
# fires and lots 7-13 repeat themselves.
assert_ok "lot-audit cross-checks the branch against a lot pattern" -- \
  grep -qE "branch --show-current \| grep -qE .\^\(feat\|fix\|chore\)/lot-" \
  "$SKILLS/lot-audit/SKILL.md"
assert_ok "lot-audit cross-checks the lot section in the repo's own lots file" -- \
  grep -qF '"$AUDIT_REPO/<Lots file>"' "$SKILLS/lot-audit/SKILL.md"
# The portfolio writes LOT, Lot and lot: a matcher that stops on the *correct*
# repository is worse than no matcher.
assert_ok "the lots-file matcher is case-insensitive" -- \
  grep -qF 'grep -qiE' "$SKILLS/lot-audit/SKILL.md"
assert_ok "that matcher accepts this repository's own heading" -- \
  bash -c 'N=18; grep -qiE "(^|[^a-z])lot[ -]$N([^0-9]|$)" "$REPO_ROOT/dev-plan.md"'
assert_ok "lot-review cross-checks the branch and the lots file too" -- \
  grep -qF '^(feat|fix|chore)/lot-' "$SKILLS/lot-review/SKILL.md"
# gh resolves the repository from the cwd, never from a sibling git -C.
assert_ok "lot-review runs gh inside the reviewed repository" -- \
  grep -qF '(cd "$REVIEW_REPO" && gh pr view' "$SKILLS/lot-review/SKILL.md"

# lot-review shares the root cause and is worse: --fix writes to that directory.
assert_ok "lot-review resolves the reviewed repository" -- \
  grep -q 'REVIEW_REPO=$(git rev-parse --show-toplevel)' "$SKILLS/lot-review/SKILL.md"
assert_ok "lot-review scopes its commit to the reviewed repository" -- \
  grep -qF 'git -C "$REVIEW_REPO" commit' "$SKILLS/lot-review/SKILL.md"

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
# --- lot 19: the start of a lot is locked like its end -------------------
START="$SKILLS/lot-start/SKILL.md"
assert_file "$SKILLS/lot-start/sync-status.py" "lot-start ships its sync script"
assert_ok "lot-start resolves the repository like lot-audit" -- \
  grep -q 'LOT_REPO=$(git rev-parse --show-toplevel)' "$START"
assert_ok "lot-start syncs the table before choosing" -- grep -q 'sync-status.py' "$START"
assert_ok "lot-start reads history through rtk proxy" -- grep -q 'rtk proxy git' "$START"
assert_ok "lot-start stops on every sync stop" -- grep -q 'Any stop ends the turn' "$START"
assert_ok "lot-start asks in one batch" -- grep -q 'one batch' "$START"
assert_ok "lot-start says no ambiguity explicitly" -- grep -q 'no ambiguity' "$START"
assert_ok "lot-start ends on the confirmation phrase" -- \
  grep -qF 'confirmer avec `lot-start confirm N`' "$START"
assert_ok "lot-start never writes the lock" -- grep -q 'Never write `.claude/current-lot`' "$START"
assert_ok "lot-start commits the sync first and alone" -- \
  grep -q 'docs: sync lots file status' "$START"
assert_ok "lot-start forbids an empty commit" -- grep -q 'Never create an empty one' "$START"
assert_ok "lot-start documents the Bash limit" -- grep -q 'not a write made through' "$START"
assert_ok "lot-start documents the extended gate" -- \
  grep -qF '[lot-start]  →  development  →  lot-test' "$START"
assert_ok "CONVENTIONS section 13 carries the extended gate" -- \
  grep -qF 'lot-start  →  development  →  lot-test  →  lot-review  →  lot-audit  →  lot-ship' \
  "$REPO_ROOT/CONVENTIONS.md"
assert_ok "CONVENTIONS section 9 sends to lot-start" -- \
  grep -qF '**Starting a lot is mechanical, not prose.**' "$REPO_ROOT/CONVENTIONS.md"
assert_ok "harness-sync propagates the lock to .gitignore" -- \
  grep -qF '.claude/current-lot' "$SKILLS/harness-sync/SKILL.md"

# i-have-adhd stays user-invoked only.
assert_ok "i-have-adhd is never model-invoked" -- \
  grep -q '^disable-model-invocation: true' "$SKILLS/i-have-adhd/SKILL.md"

# --- lot 20: a skill commits the report it writes --------------------------
# The report is the proof the skill ran (section 13). Left in the working tree
# it is invisible to lot-deliverables.yml, which reads the history, and
# lot-audit's step 0 compares a SHA against a file that is not in it.
for pair in "lot-review:docs(N): add the lot review report" \
            "lot-audit:docs(N): add the lot audit report" \
            "integration-check:docs: add the integration check report"; do
  skill=${pair%%:*}
  message=${pair#*:}
  file="$SKILLS/$skill/SKILL.md"
  assert_ok "$skill commits its deliverable" -- grep -qF 'Commit the deliverable' "$file"
  assert_ok "$skill names the deliverable's commit message" -- grep -qF "$message" "$file"
  assert_ok "$skill adds the report to the census" -- grep -qF 'Project documents' "$file"
  assert_ok "$skill leaves the push to lot-ship" -- grep -qF 'the push belongs to `lot-ship`' "$file"
done

# --- lot 21: every gate skill records its own friction ---------------------
# One file per lot, one section per gate skill, one stable key per entry
# (CONVENTIONS.md section 13). A skill that does not name its section is a skill
# whose friction is lost at the section 14 session break.
C="$REPO_ROOT/CONVENTIONS.md"
assert_ok "section 13 defines the friction file" -- \
  grep -qF '### Friction: the gate reports on itself' "$C"
assert_ok "section 13 names the stable key" -- grep -qF '`<skill> / <step>`' "$C"
assert_ok "section 13 accepts None. and refuses a missing section" -- \
  grep -qF '`None.` is a valid section; a missing one is not.' "$C"
for skill in lot-start lot-test lot-review lot-audit lot-ship; do
  file="$SKILLS/$skill/SKILL.md"
  assert_ok "$skill names the friction file" -- grep -qF 'docs/audits/lot-N-friction.md' "$file"
  assert_ok "$skill names its own section" -- grep -qF "\`## $skill\`" "$file"
  assert_ok "$skill keys its entries" -- grep -qF "\`$skill / <step>\`" "$file"
  assert_ok "$skill accepts None." -- grep -qF '`None.`' "$file"
  assert_ok "$skill points to the section 13 format" -- grep -qF '§13 (« Friction »)' "$file"
done
for pair in "lot-start:docs(N): record the lot-start friction" \
            "lot-test:docs(N): record the lot-test friction" \
            "lot-ship:docs(N): record the lot-ship friction"; do
  assert_ok "${pair%%:*} commits its friction section" -- \
    grep -qF "${pair#*:}" "$SKILLS/${pair%%:*}/SKILL.md"
done
# lot-start opens the file after the sync commit, never inside it.
START_FRICTION=$(grep -n 'Open the friction file' "$START" | head -1 | cut -d: -f1)
START_SYNC=$(grep -n 'docs: sync lots file status' "$START" | head -1 | cut -d: -f1)
assert_ok "lot-start opens the friction file after the sync commit" -- \
  test "${START_FRICTION:-0}" -gt "${START_SYNC:-99999}"
# lot-ship records before it pushes, and checks the four others are there.
SHIP="$SKILLS/lot-ship/SKILL.md"
SHIP_FRICTION=$(grep -n 'Record the friction, before the push' "$SHIP" | cut -d: -f1)
SHIP_PUSH=$(grep -n '^git push -u origin' "$SHIP" | head -1 | cut -d: -f1)
assert_ok "lot-ship records its friction before the push" -- \
  test "${SHIP_FRICTION:-99999}" -lt "${SHIP_PUSH:-0}"
assert_ok "lot-ship checks the five sections" -- \
  grep -qF 'for s in lot-start lot-test lot-review lot-audit lot-ship' "$SHIP"
assert_ok "lot-ship sends post-push friction to the PR body" -- \
  grep -qF '`## Friction` section of the PR' "$SHIP"

finish
