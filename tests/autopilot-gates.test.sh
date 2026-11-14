#!/usr/bin/env bash
# The autopilot's gate steps: the lot's diff, the census rows, the development's
# close, what lot-test may commit and a finding that needs a decision (lots 29,
# 36), split from the lot 29 suite by lot 37; its fakes and fixture live in
# tests/autopilot-lib.sh.
. "$(dirname "$0")/autopilot-lib.sh"

# --- a review fix outside the lot's diff ----------------------------------
R=$(fixture outside harness)
cat >> "$R.scen/review.sh" <<'EOF'
echo x > other.txt && git add other.txt && git commit -qm "fix(5): apply the lot review findings"
EOF
assert_eq 1 "$(pilot "$R")" "a fix outside the diff stops the run"

R=$(fixture outsideblocked harness)
cat >> "$R.scen/review.sh" <<'EOF'
echo x > other.txt && git add other.txt && git commit -qm "feat(5): extend the lot"
EOF
echo blocked > "$R.scen/review.status"
assert_eq 1 "$(pilot "$R")" "a blocked lot-review with a commit outside the diff stops the run"
assert_eq review "$(state "$R" resume)" "the out-of-diff commit is not skipped by resuming at lot-audit"
assert_contains "$(state "$R" reason)" "other.txt" "any commit type outside the diff is named"
assert_eq "start dev test review " "$(calls "$R")" "the stop comes right after lot-review"
assert_contains "$(state "$R" reason)" "other.txt" "the reason names the file"

# --- the census rows of a gate report (lot 36) ----------------------------
R=$(fixture censusreview harness)
cat >> "$R.scen/review.sh" <<'EOF'
printf '| `docs/audits/lot-5-review.md` | Lot 5 code-review report |\n' >> CLAUDE.md
printf '| `docs/audits/lot-5-review.md` | Lot 5 code-review report |\n' >> AGENTS.md
git add CLAUDE.md AGENTS.md && git commit -qm "docs(5): add the census rows"
EOF
assert_eq 0 "$(pilot "$R")" "a review may add the census rows of its report"
assert_eq "start dev test review audit ship " "$(calls "$R")" \
  "the census rows do not stop the run"

R=$(fixture censusmodify harness)
cat >> "$R.scen/review.sh" <<'EOF'
sed -i 's/| `true` |/| `false` |/' CLAUDE.md
git add CLAUDE.md && git commit -qm "fix(5): touch a line of CLAUDE.md"
EOF
assert_eq 1 "$(pilot "$R")" "a review that modifies another line of CLAUDE.md stops the run"
assert_contains "$(state "$R" reason)" "CLAUDE.md" "the reason names the modified file"

R=$(fixture censusother harness)
cat >> "$R.scen/review.sh" <<'EOF'
printf '| `README.md` | Project readme |\n' >> CLAUDE.md
git add CLAUDE.md && git commit -qm "docs(5): add a census row for another document"
EOF
assert_eq 1 "$(pilot "$R")" "a row naming a document outside docs/audits/ stops the run"
assert_eq "start dev test review " "$(calls "$R")" "no lot-audit after a non-census addition"
assert_contains "$(state "$R" reason)" "CLAUDE.md" "the reason names the file"

# A removed line starting with "--" reads "---" in the diff, like a file header.
R=$(fixture censusdashes harness)
printf -- '-- a note\n' >> "$R/CLAUDE.md"
git -C "$R" commit -qam "chore: seed a dashed line"
git -C "$R" push -q origin develop
cat >> "$R.scen/review.sh" <<'EOF'
sed -i '/^-- a note$/d' CLAUDE.md
printf '| `docs/audits/lot-5-review.md` | Lot 5 code-review report |\n' >> CLAUDE.md
git add CLAUDE.md && git commit -qm "docs(5): add the census row"
EOF
assert_eq 1 "$(pilot "$R")" "a removed line starting with -- next to a census row stops the run"
assert_contains "$(state "$R" reason)" "CLAUDE.md" "the reason names the file"

# The real census row goes inside the table, not at the end of the file.
R=$(fixture censusinsert harness)
cp "$R/CLAUDE.md" "$R/AGENTS.md"
git -C "$R" add AGENTS.md
git -C "$R" commit -qm "chore: seed the mirror"
git -C "$R" push -q origin develop
cat >> "$R.scen/review.sh" <<'EOF'
for f in CLAUDE.md AGENTS.md; do
  sed -i '/^| `Lots file`/i | `docs/audits/lot-5-review.md` | Lot 5 code-review report |' "$f"
done
git add CLAUDE.md AGENTS.md && git commit -qm "docs(5): add the census rows"
EOF
assert_eq 0 "$(pilot "$R")" "census rows inserted inside the table pass"
assert_eq "start dev test review audit ship " "$(calls "$R")" \
  "the insertion does not stop the run"

# --- the close of the development -----------------------------------------
R=$(fixture dirty harness)
echo 'echo x > stray.txt' >> "$R.scen/dev.sh"
assert_eq 1 "$(pilot "$R")" "a dirty tree after the development stops the run"
assert_eq "start dev " "$(calls "$R")" "no lot-test on a dirty tree"
assert_eq dev "$(state "$R" resume)" "the stop resumes at the development"

R=$(fixture unscoped harness)
sed -i 's/feat(5): add a/feat: add a/' "$R.scen/dev.sh"
assert_eq 1 "$(pilot "$R")" "a development without a lot-scoped commit stops the run"
assert_eq "start dev " "$(calls "$R")" "no lot-test without a commit scoped to the lot"

R=$(fixture red harness)
sed -i 's/| `true` |/| `false` |/' "$R/CLAUDE.md"
git -C "$R" commit -qam "chore: red gate" && git -C "$R" push -q origin develop
assert_eq 1 "$(pilot "$R")" "a red Validation command after the development stops the run"
assert_eq "start dev " "$(calls "$R")" "no lot-test on a red Validation command"
assert_contains "$(state "$R" reason)" "Validation command" "the reason names the Validation command"

# --- what lot-test may commit ---------------------------------------------
R=$(fixture testscope harness)
cat > "$R.scen/test.sh" <<'EOF'
echo b > src/b.txt && git add src && git commit -qm "test(5): complete the lot coverage"
EOF
assert_eq 1 "$(pilot "$R")" "a lot-test commit outside the test files stops the run"
assert_eq "start dev test " "$(calls "$R")" "no lot-review after it"
assert_contains "$(state "$R" reason)" "src/b.txt" "the reason names the file"

# Lot 36: the census row of a friction report is an addition lot-test may make.
R=$(fixture testcensus harness)
cat > "$R.scen/test.sh" <<'EOF'
mkdir -p tests docs/audits && echo t > tests/a.test.sh && echo f > docs/audits/lot-5-friction.md
printf '| `docs/audits/lot-5-friction.md` | Lot 5 friction record |\n' >> CLAUDE.md
printf '| `docs/audits/lot-5-friction.md` | Lot 5 friction record |\n' >> AGENTS.md
git add tests docs CLAUDE.md AGENTS.md && git commit -qm "test(5): complete the lot coverage"
EOF
assert_eq 0 "$(pilot "$R")" "lot-test may add the census rows of its friction report"
assert_eq "start dev test review audit ship " "$(calls "$R")" \
  "the census rows do not stop the run"

R=$(fixture testcensusmodify harness)
cat > "$R.scen/test.sh" <<'EOF'
mkdir -p tests && echo t > tests/a.test.sh
sed -i 's/| `true` |/| `false` |/' CLAUDE.md
git add tests CLAUDE.md && git commit -qm "test(5): complete the lot coverage"
EOF
assert_eq 1 "$(pilot "$R")" "lot-test cannot modify another line of CLAUDE.md"
assert_eq "start dev test " "$(calls "$R")" "no lot-review after it"
assert_contains "$(state "$R" reason)" "CLAUDE.md" "the reason names the modified file"

R=$(fixture testblocked harness)
echo blocked > "$R.scen/test.status"
assert_eq 1 "$(pilot "$R")" "a blocked lot-test stops the run"
assert_eq "start dev test " "$(calls "$R")" "a blocked lot-test opens no fix session"
assert_eq test "$(state "$R" resume)" "the stop resumes at lot-test"

# --- a missing report, a finding that needs a decision --------------------
R=$(fixture noreport harness)
: > "$R.scen/review.sh"
assert_eq 1 "$(pilot "$R")" "a lot-review without its committed report stops the run"
assert_eq "start dev test review " "$(calls "$R")" "no lot-audit without the review report"
assert_contains "$(state "$R" reason)" "lot-5-review.md" "the reason names the report"

R=$(fixture decision harness)
cat > "$R.scen/test.sh" <<'EOF'
mkdir -p tests docs/audits && echo t > tests/a.test.sh && echo f > docs/audits/lot-5-friction.md
git add tests docs && git commit -qm "test(5): complete the lot coverage"
EOF
echo blocked > "$R.scen/review.status"
assert_eq 1 "$(pilot "$R")" "a finding that needs a decision stops the run"
assert_eq "start dev test review " "$(calls "$R")" "test files and the friction entry pass the lot-test check"
assert_eq audit "$(state "$R" resume)" "once the owner decided, --resume goes on with lot-audit"
assert_eq 2 "$(pilot "$R")" "a stopped run refuses a fresh launch"
: > "$R.scen/calls.log"
assert_eq 0 "$(pilot "$R" --resume)" "--resume finishes the lot after the decision"
assert_eq "audit ship " "$(calls "$R")" "lot-review is not run again"

# --- the questions, readable in a terminal (lot 29) ------------------------
R=$(fixture layout harness)
echo blocked > "$R.scen/start.status"
printf '%s' '["Which lot?", "Which branch?\n(a) feat/lot-5-x\n(b) feat/lot-5-y"]' \
  > "$R.scen/start.questions"
assert_eq 1 "$(pilot "$R")" "a blocked lot-start stops the run"
assert_contains "$(cat "$R.out")" $'Questions:\n  1. Which lot?\n\n  2. Which branch?\n     (a) feat/lot-5-x\n     (b) feat/lot-5-y' \
  "each question is numbered on its own line, its options indented below it"
assert_eq 1 "$(grep -c 'Which lot?' "$R.out")" "each question is printed once"
assert_eq 0 "$(state "$R" reason | grep -c 'Which')" "the questions are no longer copied into the reason"
assert_contains "$(tail -1 "$R.out")" "--resume --answer" "the answer command closes the message"
assert_contains "$(cat "$R.scen/notify.log")" "  2. Which branch?" "the notification has the same layout"

R=$(fixture auditquestion harness)
: > "$R.scen/audit.sh"
echo blocked > "$R.scen/audit.status"
echo '["The Validation command is red: how to proceed?"]' > "$R.scen/audit.questions"
assert_eq 1 "$(pilot "$R")" "a blocked lot-audit without its committed report stops the run"
assert_contains "$(state "$R" reason)" "lot-5.md is not committed" "the reason names the report"
assert_contains "$(state "$R" questions)" "how to proceed?" "the audit's question survives the report check"
assert_eq blocked "$(state "$R" status)" "the audit's status survives the report check"
assert_eq audit "$(state "$R" resume)" "the report check resumes at the audit"
assert_contains "$(cat "$R.out")" "  1. The Validation command is red: how to proceed?" \
  "the audit's question is shown"
assert_contains "$(tail -1 "$R.out")" "Settle them, then: autopilot.py --resume" \
  "a gate stop is settled by the owner, then resumed"

R=$(fixture auditokquestion harness)
: > "$R.scen/audit.sh"
echo '["Le rapport est-il à commiter ?"]' > "$R.scen/audit.questions"
assert_eq 1 "$(pilot "$R")" "an ok lot-audit with questions and no committed report stops the run"
assert_eq blocked "$(state "$R" status)" "questions make the report stop blocked whatever the status"

finish
