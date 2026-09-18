#!/usr/bin/env bash
# Exercises the CLAUDE.md <-> AGENTS.md mirror hook, including the Bash paths
# that the previous Edit/Write-only hook let through (finding #18).
set -uo pipefail
. "$(dirname "$0")/lib.sh"

HOOK="$REPO_ROOT/plugins/claude-harness/hooks/mirror-sync.sh"
WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT

# fire <json payload> : run the hook, return its stdout.
fire() {
  printf '%s' "$1" | bash "$HOOK" 2>/dev/null
}

edit_payload() {
  jq -nc --arg f "$1" '{tool_name:"Edit", tool_input:{file_path:$f}, cwd:"."}'
}

bash_payload() {
  jq -nc --arg c "$1" --arg d "$2" \
    '{tool_name:"Bash", tool_input:{command:$c}, cwd:$d}'
}

# fixture <dir> <claude content> <agents content>
fixture() {
  rm -rf "$1"; mkdir -p "$1"
  printf '%s\n' "$2" > "$1/CLAUDE.md"
  printf '%s\n' "$3" > "$1/AGENTS.md"
}

D="$WORK/repo"

# --- Edit / Write: the edited file is authoritative -----------------------
fixture "$D" "new content" "stale content"
out=$(fire "$(edit_payload "$D/CLAUDE.md")")
assert_ok "Edit on CLAUDE.md mirrors into AGENTS.md" -- cmp -s "$D/CLAUDE.md" "$D/AGENTS.md"
assert_eq "new content" "$(cat "$D/AGENTS.md")" "AGENTS.md took CLAUDE.md content"
assert_contains "$out" "AGENTS.md synced" "the sync is reported to the session"

fixture "$D" "stale content" "new content"
fire "$(edit_payload "$D/AGENTS.md")" > /dev/null
assert_eq "new content" "$(cat "$D/CLAUDE.md")" "Edit on AGENTS.md mirrors into CLAUDE.md"

# Already identical: nothing to say.
fixture "$D" "same" "same"
assert_eq "" "$(fire "$(edit_payload "$D/CLAUDE.md")")" "identical pair stays silent"

# No sibling to mirror into: the hook must not create one.
rm -rf "$D"; mkdir -p "$D"; printf 'only\n' > "$D/CLAUDE.md"
fire "$(edit_payload "$D/CLAUDE.md")" > /dev/null
assert_eq "absent" "$([ -f "$D/AGENTS.md" ] && echo present || echo absent)" \
  "no AGENTS.md is created out of thin air"

# An unrelated file is not the hook's business.
fixture "$D" "a" "b"
fire "$(edit_payload "$D/README.md")" > /dev/null
assert_eq "b" "$(cat "$D/AGENTS.md")" "an edit to another file changes nothing"

# --- Bash: the shell edits the previous hook missed -----------------------
fixture "$D" "from shell" "stale"
touch -d '2026-01-02 10:00' "$D/CLAUDE.md"
touch -d '2026-01-01 10:00' "$D/AGENTS.md"
out=$(fire "$(bash_payload "cp /tmp/x $D/CLAUDE.md" "$D")")
assert_eq "from shell" "$(cat "$D/AGENTS.md")" "cp onto CLAUDE.md is mirrored"
assert_contains "$out" "AGENTS.md synced" "the shell-driven sync is reported"

fixture "$D" "stale" "from sed"
touch -d '2026-01-01 10:00' "$D/CLAUDE.md"
touch -d '2026-01-02 10:00' "$D/AGENTS.md"
fire "$(bash_payload "sed -i 's/a/b/' $D/AGENTS.md" "$D")" > /dev/null
assert_eq "from sed" "$(cat "$D/CLAUDE.md")" "sed -i on AGENTS.md is mirrored back"

fixture "$D" "stale" "from redirect"
touch -d '2026-01-01 10:00' "$D/CLAUDE.md"
touch -d '2026-01-02 10:00' "$D/AGENTS.md"
fire "$(bash_payload "printf 'x' > AGENTS.md" "$D")" > /dev/null
assert_eq "from redirect" "$(cat "$D/CLAUDE.md")" "a redirection into AGENTS.md is mirrored"

# A command naming neither file leaves a divergence untouched: the hook reacts
# to writes, it is not a background repair job.
fixture "$D" "a" "b"
fire "$(bash_payload "npm test" "$D")" > /dev/null
assert_eq "b" "$(cat "$D/AGENTS.md")" "an unrelated command changes nothing"

# Identical mtimes with different content: refuse to guess, surface it.
fixture "$D" "left" "right"
touch -d '2026-01-01 10:00' "$D/CLAUDE.md" "$D/AGENTS.md"
out=$(fire "$(bash_payload "mv /tmp/x $D/CLAUDE.md" "$D")")
assert_contains "$out" "diverge" "an ambiguous divergence is surfaced, not resolved"
assert_eq "right" "$(cat "$D/AGENTS.md")" "no file is overwritten on a tie"

# The hook resolves the repo root, so a command run from a subdirectory still
# mirrors the pair at the top level.
fixture "$D" "root content" "stale"
touch -d '2026-01-02 10:00' "$D/CLAUDE.md"
touch -d '2026-01-01 10:00' "$D/AGENTS.md"
git -C "$D" init -q -b develop
mkdir -p "$D/src/deep"
fire "$(bash_payload "cp /tmp/x CLAUDE.md" "$D/src/deep")" > /dev/null
assert_eq "root content" "$(cat "$D/AGENTS.md")" "the pair is found from a subdirectory"

# --- a path containing a space --------------------------------------------
# The fields used to be read space-separated, so any repository under a
# directory with a space made the hook exit silently while the pair diverged.
SPACED="$WORK/my project"
fixture "$SPACED" "spaced content" "stale"
out=$(fire "$(edit_payload "$SPACED/CLAUDE.md")")
assert_eq "spaced content" "$(cat "$SPACED/AGENTS.md")" \
  "Edit mirrors when the path contains a space"
assert_contains "$out" "AGENTS.md synced" "the spaced-path sync is reported"

fixture "$SPACED" "from shell" "stale"
touch -d '2026-01-02 10:00' "$SPACED/CLAUDE.md"
touch -d '2026-01-01 10:00' "$SPACED/AGENTS.md"
fire "$(bash_payload "cp /tmp/x '$SPACED/CLAUDE.md'" "$SPACED")" > /dev/null
assert_eq "from shell" "$(cat "$SPACED/AGENTS.md")" \
  "a Bash edit mirrors when the cwd contains a space"

# --- malformed input ------------------------------------------------------
assert_eq "" "$(printf 'not json' | bash "$HOOK" 2>/dev/null)" "garbage input is ignored"
assert_eq "" "$(printf '{}' | bash "$HOOK" 2>/dev/null)" "an empty payload is ignored"

finish
