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

# Census completeness: every shipped SKILL.md is listed in CLAUDE.md.
while IFS= read -r skill; do
  rel=${skill#"$REPO_ROOT/"}
  assert_ok "census lists $rel" -- grep -qF "$rel" "$REPO_ROOT/CLAUDE.md"
done < <(find "$REPO_ROOT/plugins" -name SKILL.md 2>/dev/null | sort)

finish
