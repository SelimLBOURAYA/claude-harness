#!/usr/bin/env bash
# Checks the lot 3 validation criteria on the reusable CI workflows: every
# workflow is callable, every action is pinned by SHA with its version comment,
# permissions are read-only except where publishing needs more, and the branch
# naming regex accepts the shapes the convention allows.
set -uo pipefail
. "$(dirname "$0")/lib.sh"

WF="$REPO_ROOT/.github/workflows"
TPL="$REPO_ROOT/templates"

WORKFLOWS="harness-invariants commit-format branch-naming migrations-immutable
           lot-deliverables image-smoke frontend-dist image-publish lint"

for name in $WORKFLOWS; do
  file="$WF/$name.yml"
  assert_file "$file" "$name.yml is shipped"
  [ -f "$file" ] || continue

  # Reusable: a workflow a project cannot call is dead weight here.
  assert_ok "$name is callable with workflow_call" -- grep -q '^  workflow_call:' "$file"
  assert_eq "$name" "$(sed -n 's/^name: *//p' "$file" | head -1)" \
    "$name declares its own name"

  # P5-#9: least privilege at the top of every workflow.
  assert_ok "$name declares a permissions block" -- grep -q '^permissions:' "$file"
  assert_eq "contents: read" "$(sed -n '/^permissions:/{n;s/^ *//p;}' "$file")" \
    "$name is read-only by default"

  # Every third-party action pinned to a 40-hex commit, never to a tag: a tag
  # moves, and a moved tag is someone else's code running with our token.
  unpinned=$(grep -nE '^\s*uses:' "$file" \
    | grep -vE 'uses: *[A-Za-z0-9._/-]+@[0-9a-f]{40} +# v[0-9]+\.[0-9]+\.[0-9]+' || true)
  assert_eq "" "$unpinned" "$name pins every action by SHA with its version comment"
done

# The caller template runs actions directly too, and they are pinned the same way.
assert_eq "" "$(grep -nE '^\s*(- )?uses: *actions/|^\s*# *(- )?uses: *actions/' "$TPL/ci-caller.yml" \
  | grep -vE 'uses: *[A-Za-z0-9._/-]+@[0-9a-f]{40} +# v[0-9]+\.[0-9]+\.[0-9]+' || true)" \
  "the caller template pins every action by SHA, commented lines included"

# --- publishing is the only job allowed to widen the token ---------------
for name in $WORKFLOWS; do
  file="$WF/$name.yml"
  [ -f "$file" ] || continue
  [ "$name" = "image-publish" ] && continue
  assert_eq "" "$(grep -n 'packages: *write\|contents: *write\|id-token:' "$file" || true)" \
    "$name never asks for a write scope"
done
# And there it is scoped to the job, not to the workflow.
assert_eq "" "$(sed -n '/^jobs:/q;p' "$WF/image-publish.yml" | grep -vE '^\s*#' \
  | grep -n 'packages: *write' || true)" \
  "image-publish does not grant packages: write workflow-wide"
assert_ok "image-publish grants packages: write on the publish job" -- \
  grep -q '^      packages: write' "$WF/image-publish.yml"
# Section 7: dev tags and prod tags come from their own branch, and nothing else
# publishes at all.
assert_ok "image-publish only runs on main and develop" -- \
  grep -q "refs/heads/main' || github.ref == 'refs/heads/develop'" "$WF/image-publish.yml"
assert_ok "image-publish tags latest from main only" -- \
  grep -qF "value=latest,enable=\${{ github.ref == 'refs/heads/main' }}" "$WF/image-publish.yml"
assert_ok "image-publish tags dev from develop only" -- \
  grep -qF "value=dev,enable=\${{ github.ref == 'refs/heads/develop' }}" "$WF/image-publish.yml"
# On a pull request the image is built and handed over, never pushed.
assert_ok "image-publish builds without pushing off a push event" -- \
  grep -q "if: github.event_name != 'push'" "$WF/image-publish.yml"
assert_eq "1" "$(grep -c '^          push: true' "$WF/image-publish.yml")" \
  "image-publish pushes from exactly one job"
assert_ok "image-publish hands the built image to the smoke test" -- \
  grep -q 'docker save' "$WF/image-publish.yml"
# P5-#18: the image embeds the artefact the tests ran on.
assert_ok "image-publish can embed the tested artefact" -- \
  grep -q '^      artifact_name:' "$WF/image-publish.yml"
assert_ok "image-smoke loads that image instead of rebuilding one" -- \
  grep -q 'docker load' "$WF/image-smoke.yml"
assert_ok "image-smoke tears the stack down with its volumes" -- \
  grep -q 'down -v' "$WF/image-smoke.yml"
assert_ok "image-smoke prints the logs on failure" -- \
  grep -q 'logs --no-color' "$WF/image-smoke.yml"
# P6-D9: OCI provenance labels on both paths.
for label in org.opencontainers.image.revision org.opencontainers.image.source; do
  assert_eq "2" "$(grep -c "$label" "$WF/image-publish.yml")" \
    "image-publish sets $label on the built and on the published image"
done
# P6-D12: the scan reports, it does not gate, until the first go-live.
assert_ok "image-publish scans the published image" -- \
  grep -q 'trivy-action' "$WF/image-publish.yml"
assert_ok "the scan is non-blocking for now" -- \
  grep -q 'exit-code: "0"' "$WF/image-publish.yml"

# --- P5-#8: a destructive migration must declare itself ------------------
for change in dropColumn dropTable renameColumn renameTable addNotNullConstraint; do
  assert_ok "migrations-immutable knows about $change" -- \
    grep -q "$change" "$WF/migrations-immutable.yml"
done
assert_ok "migrations-immutable requires a contract marker" -- \
  grep -q 'contract marker' "$WF/migrations-immutable.yml"
assert_ok "migrations-immutable requires the contract label on the PR" -- \
  grep -q 'contract_label' "$WF/migrations-immutable.yml"
assert_ok "migrations-immutable is skipped when there are no migrations" -- \
  grep -q "inputs.migrations_dir != 'n/a'" "$WF/migrations-immutable.yml"

# --- P5-#21 and P6-D12: lint degrades to a visible skip, never a silence --
# No "|| true": a check that swallows its own failure is a green badge on an
# unchecked repository.
assert_eq "" "$(grep -n '|| true' "$WF/lint.yml" || true)" \
  "lint never swallows a failure"
for tool in spotless prettier "npm audit" dependency-check; do
  assert_ok "lint covers $tool" -- grep -qF "$tool" "$WF/lint.yml"
done
assert_eq "3" "$(grep -c 'skipped:' "$WF/lint.yml")" \
  "each optional lint step reports an explicit skip"
assert_ok "the dependency audit is non-blocking" -- \
  grep -q 'continue-on-error: true' "$WF/lint.yml"

# --- P5-#15: the bundle is checked for real ------------------------------
assert_ok "frontend-dist requires an entry point" -- \
  grep -q "name 'index.html'" "$WF/frontend-dist.yml"

# --- no gate value hard-coded in a reusable workflow ---------------------
# The same rule as the skills: the Gate parameters table is the single source.
for name in $WORKFLOWS; do
  file="$WF/$name.yml"
  [ -f "$file" ] || continue
  assert_eq "" "$(grep -nE '\./mvnw verify|npm run build:prod' "$file" \
    | grep -v 'default:' || true)" \
    "$name does not hard-code a project validation command"
done
for input in health_path forbidden_pattern image_name migrations_dir; do
  assert_ok "$input is an input, not a constant" -- \
    grep -rq "^      $input:" "$WF"
done

# --- branch-naming accepts exactly the documented shapes ----------------
# The regexes are read out of the workflow so the test cannot drift from it.
LOT_RE=$(sed -n "s/^ *lot='\(.*\)'$/\1/p" "$WF/branch-naming.yml")
CHORE_RE=$(sed -n "s/^ *chore='\(.*\)'$/\1/p" "$WF/branch-naming.yml")
assert_ok "the lot branch regex was extracted" -- test -n "$LOT_RE"
assert_ok "the chore branch regex was extracted" -- test -n "$CHORE_RE"

accepts() {  # accepts <branch> <label>
  if printf '%s' "$1" | grep -qE "$LOT_RE" || printf '%s' "$1" | grep -qE "$CHORE_RE"; then
    assert_eq "accepted" "accepted" "$2"
  else
    assert_eq "accepted" "rejected" "$2"
  fi
}
rejects() {
  if printf '%s' "$1" | grep -qE "$LOT_RE" || printf '%s' "$1" | grep -qE "$CHORE_RE"; then
    assert_eq "rejected" "accepted" "$2"
  else
    assert_eq "rejected" "rejected" "$2"
  fi
}

accepts "feat/lot-12-quote-totals"            "a plain lot branch is accepted"
accepts "feat/lot-2b-review-gate"             "a lettered lot branch is accepted"
# The branch this very PR is on: one PR delivering a range of lots.
accepts "feat/lot-0-6-harness-foundation"     "a lot range branch is accepted"
accepts "chore/gitignore-idea"                "a chore branch is accepted"
accepts "fix/token-in-clear"                  "a hotfix branch is accepted"
accepts "docs/sync-conventions"               "a docs branch is accepted"
rejects "feat/lot-2.1-subversion"             "a sub-version lot number is rejected"
rejects "feature/lot-3-thing"                 "an unknown prefix is rejected"
rejects "feat/lot-3"                          "a lot branch with no description is rejected"
rejects "feat/lot-3-Quote-Totals"             "an upper-case description is rejected"
rejects "feat/quote-totals"                   "a feat branch outside a lot is rejected"

# --- the deliverables workflow expands a lot range the same way ---------
RANGE_SED=$(sed -n 's/.*sed -nE .\(.*\). *$/\1/p' "$WF/lot-deliverables.yml" | head -1)
assert_ok "lot-deliverables extracts both ends of a range" -- \
  grep -qF '([0-9]+[a-z]?)(-([0-9]+[a-z]?))?' "$WF/lot-deliverables.yml"
assert_ok "lot-deliverables treats lot-2b as one lot, not a range" -- \
  grep -q 'last" -gt "\$first' "$WF/lot-deliverables.yml"
assert_ok "lot-deliverables blocks on an unresolved Critical row" -- \
  grep -q 'critical' "$WF/lot-deliverables.yml"
# Same rule as the hook: the severity is the row's first cell, so a summary
# table header naming a Critical column does not block the PR.
assert_ok "lot-deliverables anchors Critical to the first cell" -- \
  grep -qF '^\|[^|a-zA-Z0-9]*critical' "$WF/lot-deliverables.yml"

# --- the caller template ------------------------------------------------
assert_file "$TPL/ci-caller.yml" "the caller template is shipped"
assert_file "$TPL/dependabot.yml" "the dependabot template is shipped"
# Every called workflow pinned to @main, for the same reason the marketplace is.
assert_eq "" "$(grep -nE 'uses: SelimLBOURAYA/claude-harness' "$TPL/ci-caller.yml" \
  | grep -v '@main$' || true)" \
  "the caller template pins every harness workflow to @main"
for name in $WORKFLOWS; do
  assert_ok "the caller template wires $name" -- \
    grep -q "workflows/$name.yml@main" "$TPL/ci-caller.yml"
done
assert_ok "the caller template runs on every branch" -- \
  grep -qF 'branches: ["**"]' "$TPL/ci-caller.yml"
assert_ok "the caller template cancels superseded runs per ref" -- \
  grep -q '^concurrency:' "$TPL/ci-caller.yml"
assert_ok "the caller template never cancels main or develop" -- \
  grep -q "cancel-in-progress: \${{ github.ref != 'refs/heads/main'" "$TPL/ci-caller.yml"
# Dependabot must not aim at main.
assert_eq "" "$(grep -n 'target-branch:' "$TPL/dependabot.yml" | grep -v 'develop' || true)" \
  "dependabot targets develop only"
assert_ok "dependabot keeps the action SHAs current" -- \
  grep -q 'package-ecosystem: github-actions' "$TPL/dependabot.yml"

# --- the harness runs its own gate --------------------------------------
assert_file "$WF/ci.yml" "the harness has its own CI"
assert_ok "the harness CI runs the validation gate" -- \
  grep -q './tests/run.sh' "$WF/ci.yml"
assert_ok "the harness CI checks the CLAUDE/AGENTS mirror" -- \
  grep -q 'cmp CLAUDE.md AGENTS.md' "$WF/ci.yml"
# Section 4: the dependency budget is asserted, not assumed.
assert_ok "the harness CI asserts its dependency budget" -- \
  grep -q 'for dep in bash python3 jq git' "$WF/ci.yml"
assert_eq "" "$(grep -nE '^\s*(- )?uses: *actions/' "$WF/ci.yml" \
  | grep -vE 'uses: *[A-Za-z0-9._/-]+@[0-9a-f]{40} +# v[0-9]+\.[0-9]+\.[0-9]+' || true)" \
  "the harness CI pins every action by SHA"

# --- the files parse as YAML --------------------------------------------
# PyYAML is not in the harness dependency budget (bash, python3, jq), so this
# check runs when it happens to be available and is skipped otherwise.
if python3 -c 'import yaml' 2>/dev/null; then
  for file in "$WF"/*.yml "$TPL/ci-caller.yml" "$TPL/dependabot.yml"; do
    assert_ok "$(basename "$file") parses as YAML" -- \
      python3 -c 'import sys,yaml; yaml.safe_load(open(sys.argv[1]))' "$file"
  done
else
  echo "  (skipped: PyYAML not installed, YAML syntax not parsed)"
fi

finish
