#!/usr/bin/env bash
# Minimal assertion helpers shared by the test suites.
# Sourced, never executed directly. No dependency beyond bash and coreutils.

REPO_ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
export REPO_ROOT

_tests_run=0
_tests_failed=0

# assert_eq <expected> <actual> <label>
assert_eq() {
  _tests_run=$((_tests_run + 1))
  if [ "$1" = "$2" ]; then
    return 0
  fi
  _tests_failed=$((_tests_failed + 1))
  printf '     x %s\n       expected: %s\n       actual:   %s\n' "$3" "$1" "$2" >&2
}

# assert_contains <haystack> <needle> <label>
assert_contains() {
  _tests_run=$((_tests_run + 1))
  case "$1" in
    *"$2"*) return 0 ;;
  esac
  _tests_failed=$((_tests_failed + 1))
  printf '     x %s\n       %s does not contain: %s\n' "$3" "$(printf '%.200s' "$1")" "$2" >&2
}

# assert_ok <label> -- <command...>   : command must exit 0
assert_ok() {
  local label="$1"; shift
  [ "${1:-}" = "--" ] && shift
  _tests_run=$((_tests_run + 1))
  local out
  if out=$("$@" 2>&1); then
    return 0
  fi
  _tests_failed=$((_tests_failed + 1))
  printf '     x %s\n       command failed: %s\n       %s\n' "$label" "$*" "$out" >&2
}

# assert_file <path> <label>
assert_file() {
  _tests_run=$((_tests_run + 1))
  if [ -f "$1" ]; then
    return 0
  fi
  _tests_failed=$((_tests_failed + 1))
  printf '     x %s\n       missing file: %s\n' "$2" "$1" >&2
}

# finish : prints the suite tally and sets the exit status
finish() {
  if [ "$_tests_failed" -ne 0 ]; then
    printf '     %d/%d assertion(s) failed\n' "$_tests_failed" "$_tests_run" >&2
    exit 1
  fi
  printf '     %d assertion(s)\n' "$_tests_run"
  exit 0
}
