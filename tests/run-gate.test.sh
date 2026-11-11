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

# --- a red suite still turns the gate red -----------------------------------
printf 'exit 1\n' > "$WORK/tests/red.test.sh"
HARNESS_AUTOPILOT=1 bash "$WORK/tests/run.sh" > "$WORK/red.out" 2>&1
assert_eq 1 "$?" "a red suite still turns the gate red"
assert_contains "$(cat "$WORK/red.out")" "1/2 suite(s) failed: red" "the red suite is named"

finish
