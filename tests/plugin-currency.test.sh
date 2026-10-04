#!/usr/bin/env bash
# The SessionStart hook must say when the installed plugin is not the version
# main declares, because a hook that was never installed writes nothing - the
# exact silence a satisfied guard produces. Versions only (lot 24).
set -uo pipefail
. "$(dirname "$0")/lib.sh"

MODULE="$REPO_ROOT/plugins/claude-harness/hooks/plugin-currency.py"
WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT

MP=claude-harness
PLUGIN=claude-harness
VPATH=1.0.0
PLUGINS="$WORK/plugins"
VERSION_DIR="$PLUGINS/cache/$MP/$PLUGIN/$VPATH"
CLONE="$PLUGINS/marketplaces/$MP"

# The installed copy holds the real hooks and rules, as an installation does.
mkdir -p "$VERSION_DIR" "$CLONE/.claude-plugin"
cp -r "$REPO_ROOT/plugins/claude-harness/hooks" "$VERSION_DIR/hooks"
cp -r "$REPO_ROOT/plugins/claude-harness/rules" "$VERSION_DIR/rules"

marketplaces() { # marketplaces <install-location>
  cat > "$PLUGINS/known_marketplaces.json" <<EOF
{"$MP": {"source": {"ref": "main"}, "installLocation": "$1", "autoUpdate": true}}
EOF
}
declares() { # declares <version> [plugin name] : the marketplace clone's manifest
  cat > "$CLONE/.claude-plugin/marketplace.json" <<EOF
{"name": "$MP", "plugins": [
  {"name": "other", "source": "./plugins/other", "version": "9.9.9"},
  {"name": "${2:-$PLUGIN}", "source": "./plugins/$PLUGIN", "version": "$1"}]}
EOF
}
# check [--plugin-root DIR] : the module's verdict, empty when it has none.
# The root is explicit here, where the module's own default is what the hook
# exercises further down.
check() { python3 "$MODULE" --plugins-dir "$PLUGINS" --plugin-root "$VERSION_DIR" "$@" 2>&1; }

# --- a lagging installation is named --------------------------------------
marketplaces "$CLONE"
declares 1.1.0
out=$(check)
assert_contains "$out" "⚠ The installed \`$PLUGIN\` plugin is $VPATH" "stale: names the installed version"
assert_contains "$out" "while \`main\` declares 1.1.0" "stale: names the version main declares"
assert_contains "$out" "lot-start" "stale: says which guards may be missing"
assert_contains "$out" "marketplace update" "stale: says how to fix it"
assert_eq "1" "$(printf '%s\n' "$out" | wc -l | tr -d ' ')" "stale: one line"

# --- the same version as main says nothing --------------------------------
declares "$VPATH"
assert_eq "" "$(check)" "current: no warning"
# The version of another plugin of the same marketplace is not this one's.
declares 1.1.0 someone-else
assert_eq "" "$(check)" "a version declared for another plugin is ignored"

# --- never a guess, never a block ----------------------------------------
declares 1.1.0
assert_eq "" "$(check --plugin-root "$REPO_ROOT/plugins/claude-harness")" \
  "a development checkout is not an installation"
marketplaces "$PLUGINS/absent"
assert_eq "" "$(check)" "no marketplace clone: silent"
marketplaces "$CLONE"
printf '{"name": "%s", "plugins": [{"name": "%s"}]}\n' "$MP" "$PLUGIN" \
  > "$CLONE/.claude-plugin/marketplace.json"
assert_eq "" "$(check)" "no version declared: silent"
printf 'not json at all\n' > "$CLONE/.claude-plugin/marketplace.json"
assert_eq "" "$(check)" "unreadable marketplace.json: silent"
declares 1.1.0
printf 'not json at all\n' > "$PLUGINS/known_marketplaces.json"
assert_eq "" "$(check)" "unreadable known_marketplaces.json: silent"
rm "$PLUGINS/known_marketplaces.json"
assert_eq "" "$(check)" "no known_marketplaces.json: silent"
marketplaces "$CLONE"
# The same fixture, read as an installation: the warning is back, so the
# silences above are verdicts and not a check that never fires.
assert_contains "$(check)" "⚠" "the stale fixture still warns when it is installed"

# --- the Harness ref of the reports: the version of the copy that ran -----
assert_eq "$VPATH" "$(check --installed-version)" "installed-version: the installed copy's version"
assert_eq "" "$(check --installed-version --plugin-root "$REPO_ROOT/plugins/claude-harness")" \
  "installed-version: nothing for a development checkout"

# --- the SessionStart hook puts it first ----------------------------------
# The state re-injection needs a harnessed repository to print its sections.
REPO="$WORK/repo"
mkdir -p "$REPO"
git -C "$REPO" init -q -b develop
git -C "$REPO" config user.email test@example.com
git -C "$REPO" config user.name Test
printf '# P\n\n## Gate parameters\n\n| Parameter | Value |\n|---|---|\n| `Lots file` | `lots.md` |\n' > "$REPO/CLAUDE.md"
git -C "$REPO" add -A
git -C "$REPO" commit -qm "docs: seed the repository"

context() { # context <cwd> [HARNESS_PLUGINS_DIR]
  jq -nc --arg d "$1" '{hook_event_name:"SessionStart", source:"startup", cwd:$d}' \
    | env -u ANTHROPIC_BASE_URL HARNESS_PLUGINS_DIR="${2:-$PLUGINS}" \
        bash "$VERSION_DIR/hooks/session-context.sh"
}
text() { printf '%s' "$1" | jq -r '.hookSpecificOutput.additionalContext'; }

body=$(text "$(context "$REPO")")
assert_contains "$body" "⚠ The installed" "hook: the warning is re-injected"
assert_eq "1" "$(printf '%s' "$body" | grep -c '⚠')" "hook: one warning line, not a paragraph"
first=$(printf '%s' "$body" | grep -n '⚠' | head -1 | cut -d: -f1)
repo=$(printf '%s' "$body" | grep -n 'Repository:' | head -1 | cut -d: -f1)
assert_eq "yes" "$([ "$first" -lt "$repo" ] && echo yes || echo no)" \
  "hook: the warning comes before the state"

declares "$VPATH"
body=$(text "$(context "$REPO")")
assert_eq "" "$(printf '%s' "$body" | grep '⚠' || true)" "hook: a current plugin warns nothing"

# The hook finds the module beside itself, so the installed copy is what runs.
assert_ok "the hook calls the check that ships in its own tree" -- \
  grep -qF 'plugin-currency.py' "$VERSION_DIR/hooks/session-context.sh"

finish
