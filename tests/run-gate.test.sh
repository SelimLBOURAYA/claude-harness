#!/usr/bin/env bash
# Exercises the validation gate itself (lot 29): run.sh copied beside a probe
# suite in a scratch repository, so the real suites never run twice.
set -uo pipefail
. "$(dirname "$0")/lib.sh"

WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT

mkdir -p "$WORK/tests"
cp "$REPO_ROOT/tests/run.sh" "$WORK/tests/run.sh"
cat > "$WORK/tests/probe.test.sh" <<'EOF'
printf 'HARNESS_AUTOPILOT=%s ANTHROPIC_BASE_URL=%s\n' \
  "${HARNESS_AUTOPILOT-unset}" "${ANTHROPIC_BASE_URL-unset}"
[ -z "${HARNESS_AUTOPILOT+x}" ] && [ -z "${ANTHROPIC_BASE_URL+x}" ]
EOF

# --- an autopilot or deepseek session's environment never reaches a suite ---
out=$(HARNESS_AUTOPILOT=1 ANTHROPIC_BASE_URL=https://api.deepseek.com/anthropic \
  bash "$WORK/tests/run.sh" 2>&1)
assert_eq 0 "$?" "the gate is green under HARNESS_AUTOPILOT=1 and ANTHROPIC_BASE_URL"
assert_contains "$out" "HARNESS_AUTOPILOT=unset ANTHROPIC_BASE_URL=unset" \
  "the suites run without HARNESS_AUTOPILOT and ANTHROPIC_BASE_URL"

out=$(env -u HARNESS_AUTOPILOT -u ANTHROPIC_BASE_URL bash "$WORK/tests/run.sh" 2>&1)
assert_eq 0 "$?" "the gate is green without them"

out=$(HARNESS_AUTOPILOT=1 ANTHROPIC_BASE_URL=https://api.deepseek.com/anthropic \
  bash -c '. "$1/tests/lib.sh"; printf "%s %s" "${HARNESS_AUTOPILOT-unset}" "${ANTHROPIC_BASE_URL-unset}"' \
  _ "$REPO_ROOT")
assert_eq "unset unset" "$out" "a suite run alone does not inherit them either"

# --- a red suite still turns the gate red, with its own output -------------
cat > "$WORK/tests/red.test.sh" <<'EOF'
echo OUT-red
exit 1
EOF
HARNESS_AUTOPILOT=1 bash "$WORK/tests/run.sh" > "$WORK/red.out" 2>&1
assert_eq 1 "$?" "a red suite still turns the gate red"
assert_contains "$(cat "$WORK/red.out")" "OUT-red" "the red suite's own output is still shown"
assert_contains "$(cat "$WORK/red.out")" "1/2 suite(s) failed: red" "the red suite is named"

# --- the output keeps the file order (lot 37) ------------------------------
# alpha finishes last but prints first: the suites are buffered, then shown in
# the order the glob gives, so a reader sees the same layout as before.
ORDER="$WORK/order"
mkdir -p "$ORDER/tests"
cp "$REPO_ROOT/tests/run.sh" "$ORDER/tests/run.sh"
printf 'sleep 0.3\nprintf "OUT-alpha\\n"\n' > "$ORDER/tests/alpha.test.sh"
printf 'printf "OUT-beta\\n"\n' > "$ORDER/tests/beta.test.sh"
out=$(bash "$ORDER/tests/run.sh" 2>&1)
assert_eq 0 "$?" "two green suites pass"
assert_contains "$out" $'>> alpha\nOUT-alpha\n   ok  alpha\n>> beta\nOUT-beta\n   ok  beta' \
  "each suite's output is printed under its name, in file order"
assert_contains "$out" "2/2 suite(s) passed" "the verdict is unchanged"

# --- the suites run at once (lot 37) ---------------------------------------
# Each suite waits for the other's marker: sequential execution would time out.
PAR="$WORK/par"
mkdir -p "$PAR/tests" "$PAR/barrier"
cp "$REPO_ROOT/tests/run.sh" "$PAR/tests/run.sh"
for pair in "a b" "b a"; do
  set -- $pair
  cat > "$PAR/tests/$1.test.sh" <<EOF
touch "\$BARRIER/$1"
n=0
while [ ! -e "\$BARRIER/$2" ] && [ \$n -lt 50 ]; do sleep 0.1; n=\$((n + 1)); done
[ -e "\$BARRIER/$2" ]
EOF
done
BARRIER="$PAR/barrier" bash "$PAR/tests/run.sh" > "$PAR/out" 2>&1
assert_eq 0 "$?" "the suites run in parallel: each one finds the other's marker"
assert_contains "$(cat "$PAR/out")" "2/2 suite(s) passed" "the two suites are green"

# --- a gate that runs nothing is an error (lot 37) -------------------------
# The suites are launched before the verdict now; an empty tests/ directory must
# still stop the gate instead of passing it with nothing run.
EMPTY="$WORK/empty"
mkdir -p "$EMPTY/tests"
cp "$REPO_ROOT/tests/run.sh" "$EMPTY/tests/run.sh"
out=$(bash "$EMPTY/tests/run.sh" 2>&1)
assert_eq 2 "$?" "a gate with no suite fails"
assert_contains "$out" "no test suite found" "and says that no suite was found"

finish
