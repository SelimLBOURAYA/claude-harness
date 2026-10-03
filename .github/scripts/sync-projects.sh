#!/usr/bin/env bash
# Propagates the harness-managed files listed in projects.json to every project
# of the portfolio, as one pull request per project against its base branch.
#
# A project already byte-identical gets no branch, and an open sync pull request
# left over from an earlier master is closed. A project that differs gets the
# dedicated branch rebuilt from its base branch and force-pushed: the branch
# belongs to this script, so a stale earlier sync is replaced, never stacked.
#
# The pull request is then merged at once (lot 23, CONVENTIONS.md section 7), but
# only when it is the token account's own, carries nothing but the synced files,
# and its head is the commit this run pushed. No wait for the checks: the projects
# call the harness workflows at @main, so a red the sync pull request shows is
# already red on their develop, and the merge only brings the copy up to date.
# Anything else leaves the pull request open and fails the project.
#
# Usage: sync-projects.sh [project...]   (default: every project of projects.json)
# Env:   SYNC_TOKEN       token with contents + pull-requests write on the projects
#        SYNC_REMOTE_BASE clone base, default https://github.com/<owner> (tests: a local dir)
#        SYNC_SOURCE_SHA  harness commit the files come from, quoted in the PR
#        SYNC_MERGE_DELAY seconds between merge attempts, default 5 (tests: 0)
set -uo pipefail

root=$(cd "$(dirname "$0")/../.." && pwd)
manifest="$root/projects.json"
branch=chore/sync-harness-files
title="docs: sync harness-managed files with the harness master"

owner=$(jq -r '.owner' "$manifest")
base=$(jq -r '.base_branch' "$manifest")
mapfile -t files < <(jq -r '.synced_files[]' "$manifest")
mapfile -t known < <(jq -r '.projects[]' "$manifest")
if [ "$#" -gt 0 ]; then
  for p in "$@"; do
    case " ${known[*]} " in
      *" $p "*) ;;
      *) echo "::error::$p is not listed in projects.json"; exit 2 ;;
    esac
  done
  projects=("$@")
else
  projects=("${known[@]}")
fi

source_sha=${SYNC_SOURCE_SHA:-$(git -C "$root" rev-parse HEAD)}
if [ -n "${SYNC_REMOTE_BASE:-}" ]; then
  remote_base=$SYNC_REMOTE_BASE
else
  : "${SYNC_TOKEN:?SYNC_TOKEN is required to push to the projects}"
  remote_base="https://x-access-token:${SYNC_TOKEN}@github.com/$owner"
fi

work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT

# open_pr <repo> : number of the open sync pull request, empty when there is none
open_pr() {
  gh pr list --repo "$1" --head "$branch" --base "$base" --state open \
    --json number --jq '.[0].number // empty'
}

# The account behind the token: a sync pull request it did not open is not merged.
sync_login=$(gh api user --jq '.login' 2>/dev/null || true)
synced_json=$(jq -c '.synced_files' "$manifest")

# merge_pr <repo> <number> <pushed sha> : merges the sync pull request when it is
# the token account's, touches only the synced files, and still heads at the
# commit this run pushed. Retried a few times: GitHub computes the mergeability
# of a pull request that was just pushed asynchronously.
merge_pr() {
  local repo=$1 number=$2 head=$3 view author extra attempt
  if [ -z "$sync_login" ]; then
    echo "::error::$repo: cannot read the token account (gh api user): sync PR #$number left open"
    return 1
  fi
  view=$(gh pr view "$number" --repo "$repo" --json author,files) || {
    echo "::error::$repo: cannot read sync PR #$number"; return 1; }
  author=$(jq -r '.author.login // ""' <<<"$view")
  if [ "$author" != "$sync_login" ]; then
    echo "::error::$repo: sync PR #$number is by '$author', not by the token account '$sync_login': left open"
    return 1
  fi
  extra=$(jq -r --argjson synced "$synced_json" \
    '[.files[].path | select(. as $p | $synced | index($p) | not)] | join(" ")' <<<"$view")
  if [ -n "$extra" ]; then
    echo "::error::$repo: sync PR #$number touches files outside synced_files ($extra): left open"
    return 1
  fi
  for attempt in 1 2 3; do
    if gh pr merge "$number" --repo "$repo" --merge --delete-branch --match-head-commit "$head"; then
      echo "   merged sync PR #$number"
      return 0
    fi
    [ "$attempt" -lt 3 ] && sleep "${SYNC_MERGE_DELAY:-5}"
  done
  echo "::error::$repo: cannot merge sync PR #$number at $head: left open"
  return 1
}

pr_body() {
  cat <<EOF
## Summary
- Re-copies the harness-managed files from \`claude-harness@${source_sha:0:7}\` (\`main\`): $(printf '`%s` ' "${files[@]}")
- Opened by the \`sync-projects\` workflow of \`claude-harness\`; the files are never hand-edited here (CONVENTIONS.md section 12)

## Test plan
- [ ] \`harness-invariants\` green on this pull request
- [ ] Validation gate green on this pull request
EOF
}

failed=""
for project in "${projects[@]}"; do
  repo="$owner/$project"
  dir="$work/$project"
  echo "== $repo"

  if ! git clone -q --depth 1 --branch "$base" "$remote_base/$project.git" "$dir"; then
    echo "::error::$repo: cannot clone branch $base"
    failed="$failed $project"
    continue
  fi

  for f in "${files[@]}"; do
    mkdir -p "$(dirname "$dir/$f")"
    cp "$root/$f" "$dir/$f"
    git -C "$dir" add -- "$f"
  done

  if git -C "$dir" diff --cached --quiet; then
    echo "   up to date"
    number=$(open_pr "$repo") || { failed="$failed $project"; continue; }
    if [ -n "$number" ]; then
      gh pr close "$number" --repo "$repo" --delete-branch \
        --comment "Superseded: \`$base\` already matches the harness master." \
        || failed="$failed $project"
      echo "   closed stale sync PR #$number"
    fi
    continue
  fi

  git -C "$dir" switch -q -c "$branch"
  git -C "$dir" -c user.name="claude-harness-sync" \
    -c user.email="41898282+github-actions[bot]@users.noreply.github.com" \
    commit -q -m "$title" -m "Source: claude-harness@$source_sha"
  if ! git -C "$dir" push -q --force origin "$branch"; then
    echo "::error::$repo: cannot push $branch"
    failed="$failed $project"
    continue
  fi

  head=$(git -C "$dir" rev-parse HEAD)

  number=$(open_pr "$repo") || { failed="$failed $project"; continue; }
  if [ -n "$number" ]; then
    echo "   updated sync PR #$number"
  elif url=$(gh pr create --repo "$repo" --base "$base" --head "$branch" \
         --title "$title" --body "$(pr_body)"); then
    url=${url##*$'\n'}   # the pull request URL is the last line
    number=${url##*/}
    echo "   opened sync PR #$number"
  else
    echo "::error::$repo: cannot open the pull request"
    failed="$failed $project"
    continue
  fi

  merge_pr "$repo" "$number" "$head" || failed="$failed $project"
done

if [ -n "$failed" ]; then
  echo "::error::sync failed for:$failed"
  exit 1
fi
