#!/usr/bin/env bash
# Lot 20: the SessionStart hook must say when the installed plugin lags behind
# main, because a hook that was never installed writes nothing at all - the
# exact silence a satisfied guard produces.
set -uo pipefail
. "$(dirname "$0")/lib.sh"

HOOK="$REPO_ROOT/plugins/claude-harness/hooks/session-context.sh"
MODULE="$REPO_ROOT/plugins/claude-harness/hooks/plugin-currency.py"
WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT

MP=claude-harness
PLUGIN=claude-harness
VPATH=1.0.0
PLUGINS="$WORK/plugins"
VERSION_DIR="$PLUGINS/cache/$MP/$PLUGIN/$VPATH"

# A marketplace clone whose origin is a local bare repository: the check is a
# real `git ls-remote`, and it runs offline.
REMOTE="$WORK/remote.git"
git init -q --bare -b main "$REMOTE"
SEED="$WORK/seed"
git init -q -b main "$SEED"
git -C "$SEED" config user.email test@example.com
git -C "$SEED" config user.name Test
printf 'one\n' > "$SEED/file"
git -C "$SEED" add -A
git -C "$SEED" commit -qm "feat: first"
git -C "$SEED" remote add origin "$REMOTE"
git -C "$SEED" push -q origin main
OLD=$(git -C "$SEED" rev-parse HEAD)
printf 'two\n' >> "$SEED/file"
git -C "$SEED" commit -qam "feat: second"
git -C "$SEED" push -q origin main
NEW=$(git -C "$SEED" rev-parse HEAD)

mkdir -p "$PLUGINS/marketplaces/$MP"
git clone -q "$REMOTE" "$PLUGINS/marketplaces/$MP"

# The installed copy holds the real hooks and rules, as an installation does.
mkdir -p "$VERSION_DIR"
cp -r "$REPO_ROOT/plugins/claude-harness/hooks" "$VERSION_DIR/hooks"
cp -r "$REPO_ROOT/plugins/claude-harness/rules" "$VERSION_DIR/rules"

marketplaces() { # marketplaces <install-location>
  cat > "$PLUGINS/known_marketplaces.json" <<EOF
{"$MP": {"source": {"ref": "main"}, "installLocation": "$1"}}
EOF
}
installed() { # installed <sha>
  cat > "$PLUGINS/installed_plugins.json" <<EOF
{"version": 2, "plugins": {"$PLUGIN@$MP": [
  {"scope": "user", "installPath": "$VERSION_DIR", "version": "$VPATH",
   "installedAt": "2026-09-22T14:50:33.580Z", "gitCommitSha": "$1"}]}}
EOF
}
# check [--plugin-root DIR] : the module's verdict, empty when it has none.
# The root is explicit here, where the module's own default is what the hook
# exercises further down.
check() { python3 "$MODULE" --plugins-dir "$PLUGINS" --plugin-root "$VERSION_DIR" "$@" 2>&1; }

# --- a lagging installation is named --------------------------------------
marketplaces "$PLUGINS/marketplaces/$MP"
installed "$OLD"
out=$(check)
assert_contains "$out" "⚠ The installed \`$PLUGIN\` plugin is $VPATH" "stale: names the version"
assert_contains "$out" "${OLD:0:7}" "stale: names the installed SHA"
assert_contains "$out" "2026-09-22" "stale: names the installation date"
assert_contains "$out" "while \`main\` is at ${NEW:0:7}" "stale: names main's SHA"
assert_contains "$out" "lot-start" "stale: says which guards may be missing"
assert_contains "$out" "marketplace update" "stale: says how to fix it"

# --- the same installation as main says nothing ---------------------------
installed "$NEW"
assert_eq "" "$(check)" "current: no warning"
# A short installed SHA against the full remote line is still the same commit.
installed "${NEW:0:9}"
assert_eq "" "$(check)" "current: a short SHA is not a lag"

# --- never a guess, never a block ----------------------------------------
installed "$OLD"
marketplaces "$PLUGINS/absent"
assert_eq "" "$(check)" "no marketplace clone: silent"
marketplaces "$PLUGINS/marketplaces/$MP"
git -C "$PLUGINS/marketplaces/$MP" remote set-url origin "$WORK/no-such-remote.git"
assert_eq "" "$(check)" "unreachable remote: silent"
git -C "$PLUGINS/marketplaces/$MP" remote set-url origin "$REMOTE"
rm "$PLUGINS/installed_plugins.json"
assert_eq "" "$(check)" "no installed_plugins.json: silent"
installed "$OLD"
python3 - "$PLUGINS/installed_plugins.json" <<'PY'
import json, sys
path = sys.argv[1]
data = json.load(open(path))
del data["plugins"]["claude-harness@claude-harness"][0]["gitCommitSha"]
json.dump(data, open(path, "w"))
PY
assert_eq "" "$(check)" "no recorded SHA: silent"
installed "$OLD"
assert_eq "" "$(check --plugin-root "$REPO_ROOT/plugins/claude-harness")" \
  "a development checkout is not an installation"
printf 'not json at all\n' > "$PLUGINS/installed_plugins.json"
assert_eq "" "$(check)" "unreadable installed_plugins.json: silent"
mv "$PLUGINS/known_marketplaces.json" "$PLUGINS/known_marketplaces.json.bak"
installed "$OLD"
assert_eq "" "$(check)" "no known_marketplaces.json: silent"
mv "$PLUGINS/known_marketplaces.json.bak" "$PLUGINS/known_marketplaces.json"
# The same fixture, read as an installation: the warning is back, so the
# silences above are verdicts and not a check that never fires.
assert_contains "$(check)" "⚠" "the stale fixture still warns when it is installed"

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

installed "$NEW"
body=$(text "$(context "$REPO")")
assert_eq "" "$(printf '%s' "$body" | grep '⚠' || true)" "hook: a fresh plugin warns nothing"

# The hook finds the module beside itself, so the installed copy is what runs.
assert_ok "the hook calls the check that ships in its own tree" -- \
  grep -qF 'plugin-currency.py' "$VERSION_DIR/hooks/session-context.sh"

finish
