#!/usr/bin/env bash
# SessionStart hook (startup, resume, clear, compact): re-injects the real state
# of the repository into the session, as additionalContext.
#
# The lot 19 incident started from a compaction summary taken for the truth and
# a status table nobody checked against git. This hook puts the facts in front
# of the model before its first action: repository, branch, working tree, the
# last merges on develop, the lot lock, and the status table.
#
# Under the deepseek profile (runtime signal: ANTHROPIC_BASE_URL is set, the same
# one lot-review checks), the imperative rules of rules/deepseek.json are added.
#
# Never blocks: a missing repository, lots file or table degrades the output,
# and the hook always exits 0. The output is capped at CAP characters (~2K tokens).
set -uo pipefail

CAP=9000
TABLE_CAP=2500
here=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
rules="$here/../rules/deepseek.json"

payload=$(cat)
source=$(printf '%s' "$payload" | jq -r '.source // "startup"' 2>/dev/null || echo startup)
cwd=$(printf '%s' "$payload" | jq -r '.cwd // ""' 2>/dev/null || true)
[ -n "$cwd" ] || cwd=$(pwd)

out="# Harness state (SessionStart: $source)"$'\n'

# Lot 20: the plugin the session actually runs can lag behind main, and a hook
# that was never installed writes nothing - which reads exactly like a guard
# that found nothing to report. The verdict goes first, before the state below,
# so a stale harness is the first line the agent reads. Silent when it cannot
# be established (offline, no clone, a development checkout).
currency=$(python3 "$here/plugin-currency.py" 2>/dev/null || true)
if [ -n "$currency" ]; then
  out+=$'\n'"$currency"$'\n'
fi

root=$(python3 "$here/lotfile.py" root "$cwd" 2>/dev/null || true)
if [ -n "$root" ]; then
  branch=$(git -C "$root" rev-parse --abbrev-ref HEAD 2>/dev/null || echo "?")
  status=$(git -C "$root" status --short 2>/dev/null | head -15)
  ref=develop
  git -C "$root" rev-parse -q --verify origin/develop >/dev/null 2>&1 && ref=origin/develop
  commits=$(git -C "$root" log --first-parent --oneline -10 "$ref" 2>/dev/null || true)
  lock=$(python3 "$here/lotfile.py" lock "$root" 2>/dev/null | tr '\n' ' ')
  table=$(python3 "$here/lotfile.py" table "$root" 2>/dev/null || true)
  lots=$(python3 "$here/lotfile.py" lots-file "$root" 2>/dev/null || true)

  out+="Repository: $root"$'\n'
  out+="Branch: $branch"$'\n'
  out+="Lot lock: ${lock:-none confirmed}"$'\n'
  out+=$'\n'"## git status --short"$'\n'"${status:-(clean)}"$'\n'
  out+=$'\n'"## Last 10 first-parent commits of $ref"$'\n'"${commits:-(no $ref branch)}"$'\n'
  # The table gets a budget of its own, so a long one never pushes the rules
  # below out of the global cap.
  if [ "${#table}" -gt "$TABLE_CAP" ]; then
    table="${table:0:$TABLE_CAP}"$'\n'"[table truncated at $TABLE_CAP characters: read the lots file]"
  fi
  if [ -n "$table" ]; then
    out+=$'\n'"## Status table of ${lots#"$root"/} (not yet synchronised with git)"$'\n'"$table"$'\n'
  else
    out+=$'\n'"## Status table"$'\n'"(no lots file or no status table found)"$'\n'
  fi
else
  out+="Directory: $cwd (not a git repository)"$'\n'
fi

out+=$'\n'"## Before any write"$'\n'
out+="1. Read CLAUDE.md (Gate parameters, Skills, Project documents), the status table and the current lot section only, and README.md quick start."$'\n'
out+="2. Never infer the next lot: invoke claude-harness:lot-start. It syncs the status table with git and stops on any ambiguity."$'\n'
out+="3. Ask every ambiguity in one batch before writing code, or state \"no ambiguity\" with the criteria restated."$'\n'
out+="4. On a feat/lot-N-* branch, writes are denied until the user types \`lot-start confirm N\`."$'\n'
out+="5. Implement strictly the confirmed lot, then stop at the gate: lot-test, lot-review, lot-audit, lot-ship."$'\n'

if [ "$source" = "compact" ]; then
  out+=$'\n'"## You are resuming from a compaction summary"$'\n'
  out+="The summary is not a source of truth. Re-anchor on the state above, and re-read the current lot section, before any write."$'\n'
fi

if [ -n "${ANTHROPIC_BASE_URL:-}" ] && [ -f "$rules" ]; then
  card=$(jq -r '.rules[] | "- \(.id): \(.rule)"' "$rules" 2>/dev/null || true)
  if [ -n "$card" ]; then
    out+=$'\n'"## deepseek profile: imperative rules"$'\n'
    out+="$(jq -r '.precedence' "$rules" 2>/dev/null)"$'\n'"$card"$'\n'
  fi
fi

if [ "${#out}" -gt "$CAP" ]; then
  out="${out:0:$CAP}"$'\n'"[truncated at $CAP characters]"
fi

jq -nc --arg c "$out" \
  '{hookSpecificOutput: {hookEventName: "SessionStart", additionalContext: $c}}'
