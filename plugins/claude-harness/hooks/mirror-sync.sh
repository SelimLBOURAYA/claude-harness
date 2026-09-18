#!/usr/bin/env bash
# PostToolUse hook: keeps AGENTS.md byte-identical to CLAUDE.md.
#
# Extends the previous Edit/Write-only hook (finding #18) to Bash, so a shell
# edit (cp, mv, sed -i, a redirection, a heredoc) no longer slips past the
# mirror invariant of CONVENTIONS.md section 12.
#
# Edit/Write  : the edited file is authoritative, it is copied over its sibling.
# Bash        : the tool does not tell us which file was written, so the most
#               recently modified of the pair wins, as section 12 prescribes for
#               a divergence found after the fact.
set -uo pipefail

payload=$(cat)

read -r tool file cwd <<EOF
$(printf '%s' "$payload" | python3 -c '
import json, sys
try:
    d = json.load(sys.stdin)
except Exception:
    print(". . .")
    sys.exit(0)
tool = d.get("tool_name") or "."
inp = d.get("tool_input") or {}
resp = d.get("tool_response") or {}
path = inp.get("file_path") or (resp.get("filePath") if isinstance(resp, dict) else "") or "."
cwd = d.get("cwd") or "."
print(tool, path, cwd)
')
EOF

[ "$tool" = "." ] && exit 0

# sync <source> <destination>: copy only when they actually differ.
sync() {
  [ -f "$1" ] || return 0
  [ -f "$2" ] || return 0
  cmp -s "$1" "$2" && return 0
  cp "$1" "$2" || return 0
  printf '{"systemMessage": "%s synced from %s (mirror invariant, CONVENTIONS.md section 12)"}\n' \
    "$(basename "$2")" "$(basename "$1")"
}

case "$tool" in
  Edit | Write | MultiEdit | NotebookEdit)
    [ -f "$file" ] || exit 0
    dir=$(dirname "$file")
    case "$(basename "$file")" in
      CLAUDE.md) sync "$file" "$dir/AGENTS.md" ;;
      AGENTS.md) sync "$file" "$dir/CLAUDE.md" ;;
    esac
    ;;

  Bash)
    command=$(printf '%s' "$payload" | python3 -c '
import json, sys
try:
    print((json.load(sys.stdin).get("tool_input") or {}).get("command") or "")
except Exception:
    pass
')
    # Only react to commands that could have touched the mirrored pair.
    case "$command" in
      *CLAUDE.md* | *AGENTS.md*) ;;
      *) exit 0 ;;
    esac

    dir=$cwd
    [ -d "$dir" ] || exit 0
    root=$(git -C "$dir" rev-parse --show-toplevel 2>/dev/null) && dir=$root

    claude="$dir/CLAUDE.md"
    agents="$dir/AGENTS.md"
    [ -f "$claude" ] && [ -f "$agents" ] || exit 0
    cmp -s "$claude" "$agents" && exit 0

    if [ "$claude" -nt "$agents" ]; then
      sync "$claude" "$agents"
    elif [ "$agents" -nt "$claude" ]; then
      sync "$agents" "$claude"
    else
      # Same mtime but different content: refuse to guess, surface it.
      printf '{"systemMessage": "CLAUDE.md and AGENTS.md diverge with identical mtimes; resolve manually (CONVENTIONS.md section 12)."}\n'
    fi
    ;;
esac

exit 0
