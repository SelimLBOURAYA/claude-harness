#!/usr/bin/env bash
# The sync-projects workflow propagates the harness-managed files to every
# project as a pull request: one per stale project, none for an up-to-date one,
# never a second one, and a stale one closed once the project caught up. Runs
# offline against local bare repositories and a recording `gh` stub.
set -uo pipefail
. "$(dirname "$0")/lib.sh"

SCRIPT="$REPO_ROOT/.github/scripts/sync-projects.sh"
WF="$REPO_ROOT/.github/workflows/sync-projects.yml"
MANIFEST="$REPO_ROOT/projects.json"
WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT

# --- manifest ---------------------------------------------------------------
assert_file "$MANIFEST" "projects.json is shipped"
assert_eq "develop" "$(jq -r '.base_branch' "$MANIFEST")" "projects are synced against develop"
assert_eq "CONVENTIONS.md" "$(jq -r '.synced_files[0]' "$MANIFEST")" "CONVENTIONS.md is a synced file"
assert_eq "" "$(jq -r '.projects[] | select(. == "claude-harness")' "$MANIFEST")" \
  "the harness does not sync onto itself"
for f in $(jq -r '.synced_files[]' "$MANIFEST"); do
  assert_file "$REPO_ROOT/$f" "synced file $f exists in the harness"
done

# --- workflow ---------------------------------------------------------------
assert_file "$WF" "sync-projects.yml is shipped"
assert_eq "contents: read" "$(sed -n '/^permissions:/{n;s/^ *//p;}' "$WF")" \
  "sync-projects keeps its own token read-only"
assert_ok "sync-projects runs on main only" -- grep -q "github.ref == 'refs/heads/main'" "$WF"
assert_ok "sync-projects triggers on a master change" -- grep -q '^      - CONVENTIONS.md' "$WF"
assert_ok "sync-projects writes with the dedicated secret" -- grep -q 'secrets.HARNESS_SYNC_TOKEN' "$WF"
assert_eq "" "$(grep -nE '^\s*uses:' "$WF" \
  | grep -vE 'uses: *[A-Za-z0-9._/-]+@[0-9a-f]{40} +# v[0-9]+\.[0-9]+\.[0-9]+' || true)" \
  "sync-projects pins every action by SHA"
assert_eq "" "$(grep -n 'inputs.projects' "$WF" | grep -v 'PROJECTS:' || true)" \
  "the dispatch input reaches the script through env, never inline"

# --- behaviour --------------------------------------------------------------
# A copy of the harness with a two-project manifest, so that the real script
# runs against local remotes.
H="$WORK/harness"
mkdir -p "$H/.github/scripts"
cp "$SCRIPT" "$H/.github/scripts/"
printf 'master v2\n' > "$H/CONVENTIONS.md"
jq -n '{owner:"me", base_branch:"develop", synced_files:["CONVENTIONS.md"], projects:["stale","fresh"]}' \
  > "$H/projects.json"
git init -q "$H" && git -C "$H" add -A \
  && git -C "$H" -c user.email=t@e -c user.name=T commit -qm "feat: harness"

REMOTES="$WORK/remotes"
mkdir -p "$REMOTES"
seed() { # seed <project> <conventions content>
  local s="$WORK/seed-$1"
  git init -q -b develop "$s"
  printf '%s\n' "$2" > "$s/CONVENTIONS.md"
  git -C "$s" add -A
  git -C "$s" -c user.email=t@e -c user.name=T commit -qm "feat: seed"
  git init -q --bare -b develop "$REMOTES/$1.git"
  git -C "$s" push -q "$REMOTES/$1.git" develop
}
seed stale "master v1"
seed fresh "master v2"

# gh stub: records every call; `pr list` answers from $WORK/open-<repo-name>,
# `api user` with $GH_LOGIN, `pr view` with $GH_PR_AUTHOR and $GH_PR_FILES, and
# `pr merge` fails when $GH_MERGE_FAIL is set (a head that moved, say).
mkdir -p "$WORK/bin"
cat > "$WORK/bin/gh" <<'EOF'
#!/usr/bin/env bash
echo "$*" >> "$GH_LOG"
case "$1 $2" in
  "pr list") repo=$4; f="$GH_STATE/open-${repo#*/}"; [ -f "$f" ] && cat "$f" ;;
  "api user") printf '%s\n' "${GH_LOGIN-sync-bot}" ;;
  "pr create") echo "Creating pull request" >&2; echo "https://github.com/$4/pull/12" ;;
  "pr view") files='[{"path":"CONVENTIONS.md"}]'
             printf '{"author":{"login":"%s"},"files":%s}\n' \
               "${GH_PR_AUTHOR:-sync-bot}" "${GH_PR_FILES:-$files}" ;;
  "pr merge") [ -z "${GH_MERGE_FAIL:-}" ] || exit 1 ;;
esac
exit 0
EOF
chmod +x "$WORK/bin/gh"

run_sync() {
  GH_LOG="$WORK/gh.log" GH_STATE="$WORK" PATH="$WORK/bin:$PATH" SYNC_MERGE_DELAY=0 \
    SYNC_REMOTE_BASE="$REMOTES" bash "$H/.github/scripts/sync-projects.sh" "$@" > "$WORK/out.log" 2>&1
}
pushed() { git --git-dir="$REMOTES/$1.git" rev-parse chore/sync-harness-files; }

: > "$WORK/gh.log"
assert_ok "a first sync succeeds" -- run_sync
branch_file() { git --git-dir="$REMOTES/$1.git" show chore/sync-harness-files:CONVENTIONS.md 2>/dev/null; }
assert_eq "master v2" "$(branch_file stale)" "the stale project gets the master on the sync branch"
assert_eq "" "$(git --git-dir="$REMOTES/fresh.git" branch --list chore/sync-harness-files)" \
  "an up-to-date project gets no branch"
assert_eq "master v1" "$(git --git-dir="$REMOTES/stale.git" show develop:CONVENTIONS.md)" \
  "develop itself is never written"
assert_eq "1" "$(grep -c '^pr create' "$WORK/gh.log")" "exactly one pull request is opened"
assert_contains "$(grep -m1 '^pr list' "$WORK/gh.log")" "--base develop" \
  "only a sync pull request against the base branch is picked up"
assert_contains "$(grep '^pr create' "$WORK/gh.log")" "--repo me/stale --base develop --head chore/sync-harness-files" \
  "the pull request targets develop of the stale project"
assert_eq "docs: sync harness-managed files with the harness master" \
  "$(git --git-dir="$REMOTES/stale.git" log -1 --format=%s chore/sync-harness-files)" \
  "the sync commit follows Conventional Commits"
assert_contains "$(grep '^pr merge' "$WORK/gh.log")" \
  "pr merge 12 --repo me/stale --merge --delete-branch --match-head-commit $(pushed stale)" \
  "the new pull request is merged at once, pinned to the pushed commit"
assert_eq "1" "$(grep -c '^pr merge' "$WORK/gh.log")" "only the stale project's pull request is merged"

# A second run while the pull request is still open refreshes it, never duplicates it.
printf '7\n' > "$WORK/open-stale"
: > "$WORK/gh.log"
assert_ok "a second sync succeeds" -- run_sync
assert_eq "0" "$(grep -c '^pr create' "$WORK/gh.log")" "an open sync pull request is not duplicated"
assert_contains "$(grep '^pr merge' "$WORK/gh.log")" "pr merge 7 --repo me/stale" \
  "the refreshed pull request is merged"

# The merge is refused, the pull request left open and the project failed, when
# the pull request is not the token account's, carries another file, can no
# longer be merged at the pushed head, or the token account cannot be read.
refused() { # refused <label> <reason in the log> ; the caller sets the stub env
  assert_eq "1" "$rc" "$1 fails the run"
  assert_contains "$(cat "$WORK/out.log")" "$2" "$1 is reported"
  assert_contains "$(cat "$WORK/out.log")" "sync failed for: stale" "$1 names the project"
}
: > "$WORK/gh.log"; GH_PR_AUTHOR=someone run_sync; rc=$?
refused "another author" "is by 'someone', not by the token account 'sync-bot': left open"
assert_eq "0" "$(grep -c '^pr merge' "$WORK/gh.log")" "a pull request by another author is never merged"
: > "$WORK/gh.log"; GH_PR_FILES='[{"path":"CONVENTIONS.md"},{"path":"ci.yml"}]' run_sync; rc=$?
refused "an extra file" "touches files outside synced_files (ci.yml): left open"
assert_eq "0" "$(grep -c '^pr merge' "$WORK/gh.log")" "a pull request with another file is never merged"
: > "$WORK/gh.log"; GH_MERGE_FAIL=1 run_sync; rc=$?
refused "a moved head" "cannot merge sync PR #7 at $(pushed stale): left open"
assert_eq "3" "$(grep -c '^pr merge' "$WORK/gh.log")" "the merge is retried, then given up"
: > "$WORK/gh.log"; GH_LOGIN='' run_sync; rc=$?
refused "an unreadable token account" "cannot read the token account"
assert_eq "0" "$(grep -c '^pr merge' "$WORK/gh.log")" "no merge without the token account"

# Once the project caught up, its leftover sync pull request is closed.
git clone -q "$REMOTES/stale.git" "$WORK/merge" 2>/dev/null
git -C "$WORK/merge" checkout -q develop
printf 'master v2\n' > "$WORK/merge/CONVENTIONS.md"
git -C "$WORK/merge" -c user.email=t@e -c user.name=T commit -qam "docs: merged"
git -C "$WORK/merge" push -q origin develop
: > "$WORK/gh.log"
assert_ok "a sync after the merge succeeds" -- run_sync
assert_contains "$(cat "$WORK/gh.log")" "pr close 7 --repo me/stale --delete-branch" \
  "the superseded sync pull request is closed"

# Only listed projects can be targeted, and one failing project fails the run.
assert_eq "2" "$(run_sync unknown; echo $?)" "an unlisted project is refused"
rm -rf "$REMOTES/fresh.git"
assert_eq "1" "$(run_sync; echo $?)" "an unreachable project fails the run"
assert_contains "$(cat "$WORK/out.log")" "sync failed for: fresh" "the failing project is named"

finish
