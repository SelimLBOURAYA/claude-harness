#!/usr/bin/env bash
# Validation gate of claude-harness.
# Runs every tests/*.test.sh at once and reports a single pass/fail verdict.
# Each suite's output is buffered, then printed in file order (lot 37): the
# suites are independent, so their order does not change the verdict.
# Dependencies are deliberately limited to bash, python3 and jq.
set -uo pipefail

cd "$(dirname "$0")/.." || exit 2
root=$(pwd)

# An autopilot session sets HARNESS_AUTOPILOT=1, which turns the git guard's
# `ask` into `deny`, and a deepseek one ANTHROPIC_BASE_URL, which the autopilot
# refuses: the suites set them themselves where they test them (lot 29).
unset HARNESS_AUTOPILOT ANTHROPIC_BASE_URL

red=$'\033[31m'; green=$'\033[32m'; dim=$'\033[2m'; off=$'\033[0m'
[ -t 1 ] || { red=""; green=""; dim=""; off=""; }

missing=""
for dep in python3 jq git; do
  command -v "$dep" >/dev/null 2>&1 || missing="$missing $dep"
done
if [ -n "$missing" ]; then
  echo "${red}missing dependencies:$missing${off}" >&2
  exit 2
fi

shopt -s nullglob
suite_list=("$root"/tests/*.test.sh)
shopt -u nullglob
if [ "${#suite_list[@]}" -eq 0 ]; then
  echo "${red}no test suite found in tests/${off}" >&2
  exit 2
fi

buffers=$(mktemp -d)
trap 'rm -rf "$buffers"' EXIT

for suite in "${suite_list[@]}"; do
  name=$(basename "$suite" .test.sh)
  (
    bash "$suite" > "$buffers/$name.out" 2>&1
    printf '%s\n' "$?" > "$buffers/$name.code"
  ) &
done
wait

suites=0
failed=0
failed_names=""
for suite in "${suite_list[@]}"; do
  name=$(basename "$suite" .test.sh)
  suites=$((suites + 1))
  printf '%s>> %s%s\n' "$dim" "$name" "$off"
  cat "$buffers/$name.out" 2>/dev/null
  code=$(cat "$buffers/$name.code" 2>/dev/null || echo 1)
  if [ "$code" -eq 0 ]; then
    printf '%s   ok  %s%s\n' "$green" "$name" "$off"
  else
    printf '%s   FAIL %s%s\n' "$red" "$name" "$off"
    failed=$((failed + 1))
    failed_names="$failed_names $name"
  fi
done

echo
if [ "$failed" -ne 0 ]; then
  echo "${red}${failed}/${suites} suite(s) failed:${failed_names}${off}" >&2
  exit 1
fi

echo "${green}${suites}/${suites} suite(s) passed${off}"
