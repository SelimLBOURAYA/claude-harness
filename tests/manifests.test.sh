#!/usr/bin/env bash
# Checks the plugin distribution manifests and the repo documentation invariants.
set -uo pipefail
. "$(dirname "$0")/lib.sh"

mk="$REPO_ROOT/.claude-plugin/marketplace.json"
pl="$REPO_ROOT/plugins/claude-harness/.claude-plugin/plugin.json"

assert_file "$mk" "marketplace manifest exists"
assert_file "$pl" "plugin manifest exists"
assert_ok "marketplace manifest is valid JSON" -- jq -e . "$mk"
assert_ok "plugin manifest is valid JSON" -- jq -e . "$pl"

assert_eq "claude-harness" "$(jq -r '.name' "$mk")" "marketplace name"
assert_eq "claude-harness" "$(jq -r '.name' "$pl")" "plugin name"
assert_eq "$(jq -r '.plugins[0].name' "$mk")" "$(jq -r '.name' "$pl")" "marketplace entry and plugin manifest agree on the name"
assert_eq "./plugins/claude-harness" "$(jq -r '.plugins[0].source' "$mk")" "marketplace points at the plugin directory"
assert_eq "1" "$(jq -r '.plugins | length' "$mk")" "exactly one plugin is published"

# The plugin source declared by the marketplace must exist and carry its manifest.
src=$(jq -r '.plugins[0].source' "$mk")
assert_file "$REPO_ROOT/${src#./}/.claude-plugin/plugin.json" "declared plugin source resolves"

# Hook wiring (lot 1, lot 19): every hook script is wired, and every wired
# script exists.
hj="$REPO_ROOT/plugins/claude-harness/hooks/hooks.json"
assert_ok "hooks.json is valid JSON" -- jq -e . "$hj"
wired() { # wired <event> <matcher> <script>
  jq -e --arg e "$1" --arg m "$2" --arg s "$3" \
    '.hooks[$e] | any(.[]; (.matcher // "") == $m and any(.hooks[]; .command | contains($s)))' "$hj"
}
assert_ok "git guard on PreToolUse Bash" -- wired PreToolUse Bash git-guard.py
assert_ok "lot write lock on PreToolUse writes" -- \
  wired PreToolUse "Edit|Write|MultiEdit|NotebookEdit" lot-lock-guard.py
assert_ok "lot confirmation on UserPromptSubmit" -- wired UserPromptSubmit "" lot-confirm.sh
assert_ok "state re-injection on SessionStart" -- \
  wired SessionStart "startup|resume|clear|compact" session-context.sh
assert_ok "mirror on PostToolUse" -- wired PostToolUse "Edit|Write|MultiEdit|Bash" mirror-sync.sh
while IFS= read -r script; do
  assert_file "$REPO_ROOT/plugins/claude-harness/hooks/$script" "wired hook $script exists"
done < <(jq -r '.hooks[][].hooks[].command' "$hj" | grep -oE 'hooks/[a-z-]+\.(py|sh)' | sed 's#hooks/##' | sort -u)
# Helpers called by a wired hook rather than declared in hooks.json itself.
HELPERS="lotfile.py plugin-currency.py"
for script in "$REPO_ROOT"/plugins/claude-harness/hooks/*.py "$REPO_ROOT"/plugins/claude-harness/hooks/*.sh; do
  name=$(basename "$script")
  case " $HELPERS " in *" $name "*) continue ;; esac
  assert_ok "hook script $name is wired" -- grep -qF "hooks/$name" "$hj"
done
# An exception list on its own would hide an orphaned helper: each one must be
# reachable from some other file of the hooks tree.
for name in $HELPERS; do
  assert_ok "$name is called from the hooks tree" -- \
    grep -rlF "$name" "$REPO_ROOT/plugins/claude-harness/hooks" | grep -qv "/$name$"
done

# The lock is local state: never versioned, here or in a generated repository.
assert_ok "this repository ignores the lot lock" -- grep -qx '\.claude/current-lot' "$REPO_ROOT/.gitignore"
assert_ok "the skeleton ignores the lot lock" -- \
  grep -qx '\.claude/current-lot' "$REPO_ROOT/templates/project/.gitignore"

# Mandatory document set (CONVENTIONS.md §12).
for doc in CLAUDE.md AGENTS.md CONVENTIONS.md README.md dev-plan.md; do
  assert_file "$REPO_ROOT/$doc" "$doc is present"
done

# Mirror invariant CLAUDE.md = AGENTS.md (CONVENTIONS.md §12).
assert_ok "CLAUDE.md and AGENTS.md are byte-identical" -- \
  cmp -s "$REPO_ROOT/CLAUDE.md" "$REPO_ROOT/AGENTS.md"

# Gate parameters section is mandatory and is what the skills read.
assert_ok "CLAUDE.md declares its Gate parameters" -- \
  grep -q '^## Gate parameters' "$REPO_ROOT/CLAUDE.md"

# Skills live in the plugin, never in a legacy skill/ directory (finding #1).
assert_eq "absent" "$([ -d "$REPO_ROOT/skill" ] && echo present || echo absent)" \
  "no legacy skill/ directory"

# Census completeness (CONVENTIONS.md §12). harness-invariants.yml only scans
# .claude/skills and docs/audits, which is right for a consuming repo and blind
# here: the harness ships its skills from plugins/ and its skeleton from
# templates/. Every tracked markdown file must appear in the census, whatever
# directory it lives in.
while IFS= read -r doc; do
  rel=${doc#"$REPO_ROOT/"}
  assert_ok "census lists $rel" -- grep -qF "$rel" "$REPO_ROOT/CLAUDE.md"
done < <(find "$REPO_ROOT" -name '*.md' -not -path "$REPO_ROOT/.git/*" | sort)

finish
