#!/usr/bin/env bash
# Validation gate of claude-harness.
# Runs every tests/*.test.sh and reports a single pass/fail verdict.
# Dependencies are deliberately limited to bash, python3 and jq.
set -uo pipefail

cd "$(dirname "$0")/.." || exit 2
root=$(pwd)

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

suites=0
failed=0
failed_names=""

shopt -s nullglob
for suite in "$root"/tests/*.test.sh; do
  name=$(basename "$suite" .test.sh)
  suites=$((suites + 1))
  printf '%s>> %s%s\n' "$dim" "$name" "$off"
  if bash "$suite"; then
    printf '%s   ok  %s%s\n' "$green" "$name" "$off"
  else
    printf '%s   FAIL %s%s\n' "$red" "$name" "$off"
    failed=$((failed + 1))
    failed_names="$failed_names $name"
  fi
done
shopt -u nullglob

echo
if [ "$suites" -eq 0 ]; then
  echo "${red}no test suite found in tests/${off}" >&2
  exit 2
fi

if [ "$failed" -ne 0 ]; then
  echo "${red}${failed}/${suites} suite(s) failed:${failed_names}${off}" >&2
  exit 1
fi

echo "${green}${suites}/${suites} suite(s) passed${off}"
