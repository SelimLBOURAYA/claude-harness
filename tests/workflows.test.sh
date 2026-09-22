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
# spotless, prettier, eslint, dependency-check when no NVD key is configured,
# and the lot 18 branch: shellcheck (no script, not installed) and YAML (no
# file, PyYAML unavailable).
assert_eq "8" "$(grep -c 'skipped:' "$WF/lint.yml")" \
  "each optional lint step reports an explicit skip"
# The audit is non-blocking at the *step* level. On the job, continue-on-error
# still publishes a check run with conclusion "failure", so the pull request
# shows a red check for a signal declared informative - and §7 says a red pull
# request is never merged.
assert_eq "" "$(grep -n '^    continue-on-error' "$WF/lint.yml" || true)" \
  "lint carries no job-level continue-on-error"
assert_eq "2" "$(grep -c '^        continue-on-error: true' "$WF/lint.yml")" \
  "both audit steps are non-blocking"

# --- P5-#15: the bundle is checked for real ------------------------------
assert_ok "frontend-dist requires an entry point" -- \
  grep -q "name 'index.html'" "$WF/frontend-dist.yml"
# Report-only is opt-in and defaults off: a caller that says nothing is gated.
assert_ok "frontend-dist enforces by default" -- \
  bash -c "grep -A9 '^      enforce:' '$WF/frontend-dist.yml' | grep -q 'default: true'"
assert_ok "report-only downgrades the annotation rather than skipping" -- \
  grep -q 'level=warning' "$WF/frontend-dist.yml"

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

# Dependabot names its own branches and that prefix is not configurable, so the
# workflow exempts them by name rather than by regex: without the exemption every
# weekly dependency PR is red.
assert_ok "branch-naming exempts dependabot branches" -- \
  grep -qF 'dependabot/*)' "$WF/branch-naming.yml"
for b in dependabot/github_actions/actions/checkout-5 \
         dependabot/npm_and_yarn/vite-5.4.2 \
         dependabot/maven/org.springframework.boot-3.3.4; do
  case "$b" in
    dependabot/*) assert_eq "exempt" "exempt" "$b is exempt from the branch regexes" ;;
    *) assert_eq "exempt" "checked" "$b is exempt from the branch regexes" ;;
  esac
done
assert_eq "" "$(grep -n 'accepts the chore/ form' "$REPO_ROOT/templates/dependabot.yml" || true)" \
  "the dependabot template no longer claims the chore/ prefix renames its branches"

# --- the deliverables workflow expands a lot range the same way ---------
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

# --- a report is in scope when its lot number is in the declared range ---
# seq only emits plain integers, so lot 2b never appears in the expansion of
# feat/lot-0-6-*. Reproduce the workflow's membership test on the real shapes.
in_scope() {  # in_scope <declared lots> <report path>
  local lots="$1" f="$2" n base
  case "$f" in */lot-0-integration.md) printf 'skipped'; return ;; esac
  n=$(basename "$f" .md | sed -E 's/^lot-([0-9]+[a-z]?)(-review)?$/\1/')
  base=${n%%[a-z]}
  case " $lots " in
    *" $n "* | *" $base "*) printf 'in' ;;
    *) printf 'out' ;;
  esac
}
assert_eq "in" "$(in_scope "0 1 2 3 4 5 6" docs/audits/lot-2b.md)" \
  "a lettered lot inside the declared range is in scope"
assert_eq "in" "$(in_scope "0 1 2 3 4 5 6" docs/audits/lot-2b-review.md)" \
  "its review report is in scope too"
assert_eq "in" "$(in_scope "0 1 2 3 4 5 6" docs/audits/lot-3.md)" \
  "a plain lot inside the declared range is in scope"
assert_eq "out" "$(in_scope "0 1 2" docs/audits/lot-7.md)" \
  "a lot outside the declared range is rejected"
assert_eq "out" "$(in_scope "0 1 2" docs/audits/lot-7b.md)" \
  "a lettered lot outside the declared range is rejected"
# The integration report belongs to no lot: it is the integration-check
# deliverable and every frontend branch carries it.
assert_eq "skipped" "$(in_scope "3" docs/audits/lot-0-integration.md)" \
  "the integration report is never treated as an out-of-scope lot report"
assert_ok "lot-deliverables exempts the integration report from the scope check" -- \
  grep -qF '*/lot-0-integration.md) continue' "$WF/lot-deliverables.yml"

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
# The harness repository is private, so harness-invariants cannot check out the
# conventions master with the caller's own github.token. The secret must be
# passed for real, not left as a commented-out suggestion.
assert_ok "the caller template passes the harness read token" -- \
  grep -qF 'harness_token: ${{ secrets.HARNESS_READ_TOKEN }}' "$TPL/ci-caller.yml"
assert_eq "" "$(grep -n '# *harness_token:' "$TPL/ci-caller.yml" || true)" \
  "the harness read token is not commented out"
assert_ok "the README documents how to issue that token" -- \
  grep -qF 'HARNESS_READ_TOKEN' "$REPO_ROOT/README.md"
assert_ok "the README documents the reusable-workflow access level" -- \
  grep -qF 'access_level=user' "$REPO_ROOT/README.md"
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

# --- lot 17: a coverage threshold must measure something -----------------
# The two steps are exercised for real, not grepped: the shell they run is
# extracted from the workflow and executed against fixture repositories. A
# grep would have passed on all three of the repositories whose coverage
# figure turned out to measure nothing.
COVWORK=$(mktemp -d)
trap 'rm -rf "$COVWORK"' EXIT

extract_step_from() {
  python3 - "$1" "$2" <<'PYEOF'
import re, sys
wf = open(sys.argv[1]).read()
body = re.search(r'\n      - name: ' + re.escape(sys.argv[2]) + r'\n(.*?)(?=\n      - name: |\Z)',
                 wf, re.S).group(1)
run = re.search(r'(?:^|\n)        run: \|\n(.*)', body, re.S).group(1)
# The block scalar ends at the first line indented less than its own body, which
# is how a step that is the last one of its job stops before the next job's
# header instead of swallowing it.
lines = []
for line in run.split('\n'):
    if line.strip() and not line.startswith(' ' * 10):
        break
    lines.append(line[10:] if line.startswith(' ' * 10) else line)
print('\n'.join(lines))
PYEOF
}

extract_step() { extract_step_from "$WF/harness-invariants.yml" "$1"; }

extract_step "The coverage gate has something to measure" > "$COVWORK/subject.sh"
extract_step "No coverage exclusion covers a business package" > "$COVWORK/excl.sh"
assert_ok "the coverage-subject step has an extractable script" -- test -s "$COVWORK/subject.sh"
assert_ok "the business-package step has an extractable script" -- test -s "$COVWORK/excl.sh"

# claude_md <dir> <stack> <threshold cell> <exclusions cell>
claude_md() {
  mkdir -p "$1"
  {
    echo '## Gate parameters'
    echo ''
    echo '| Parameter | Value |'
    echo '|---|---|'
    echo "| \`Stack\` | $2 |"
    echo "| \`Coverage threshold\` | $3 |"
    echo "| \`Coverage exclusions\` | $4 |"
  } > "$1/CLAUDE.md"
}

# run_step <script> <dir> [INFRA]  : echoes the exit status
run_step() {
  ( cd "$2" && INFRA="${3-config,configuration,dto,dtos,mapper,mappers,generated}" \
      bash "$1" > /dev/null 2>&1; echo $? )
}

SUBJ="$COVWORK/subject.sh"
EXCL="$COVWORK/excl.sh"

# elya's shape: 0.80 declared, every source file covered by an exclusion, so
# jacoco:check analysed a bundle of zero classes and passed.
D="$COVWORK/empty-scope"
claude_md "$D" '`backend`' '`0.80`' '`com/elya/config/**`, `com/elya/ElyaApplication.class`'
mkdir -p "$D/src/main/java/com/elya/config"
touch "$D/src/main/java/com/elya/ElyaApplication.java" \
      "$D/src/main/java/com/elya/config/FlywayConfig.java"
assert_eq "1" "$(run_step "$SUBJ" "$D")" \
  "a threshold above zero with every source file excluded fails"

# One class outside the patterns is enough for the gate to mean something.
mkdir -p "$D/src/main/java/com/elya/journal"
touch "$D/src/main/java/com/elya/journal/EntryService.java"
assert_eq "0" "$(run_step "$SUBJ" "$D")" \
  "a threshold above zero passes as soon as one source file is in scope"

# A declared 0 is honest, not a violation: mpf carries it with its reason.
D="$COVWORK/zero"
claude_md "$D" '`frontend`' '`0` lines — see the ratchet note' '(none)'
assert_eq "0" "$(run_step "$SUBJ" "$D")" "a declared threshold of 0 is accepted"

D="$COVWORK/na"
claude_md "$D" '`harness`' 'n/a' '(none)'
assert_eq "0" "$(run_step "$SUBJ" "$D")" "a threshold of n/a is accepted"

# A stack whose source layout the step does not know is skipped, never failed.
D="$COVWORK/unknown-stack"
claude_md "$D" '`harness`' '`0.80`' '(none)'
assert_eq "0" "$(run_step "$SUBJ" "$D")" "an unknown stack is skipped, not failed"

# A repository that declares a real threshold and has no source at all.
D="$COVWORK/no-source"
claude_md "$D" '`backend`' '`0.80`' '(none)'
assert_eq "1" "$(run_step "$SUBJ" "$D")" "a threshold above zero with no source file fails"

# The kb shape: the ratchet parenthesis must not be read as the threshold.
D="$COVWORK/ratchet"
claude_md "$D" '`backend`' '`0.70` (ratchet, target `0.80`)' '`com/slim/kb/config/**`'
mkdir -p "$D/src/main/java/com/slim/kb/quote"
touch "$D/src/main/java/com/slim/kb/quote/QuoteService.java"
assert_eq "0" "$(run_step "$SUBJ" "$D")" "the first backticked figure is the threshold"

# --- the exclusions themselves -------------------------------------------
# meal-planner-backend's shape before lot 9: 0.80 measured around most of the
# business code.
D="$COVWORK/business-excluded"
claude_md "$D" '`backend`' '`0.80`' '`com/mealplanner/auth/**`, `com/mealplanner/**/config/**`'
assert_eq "1" "$(run_step "$EXCL" "$D")" "excluding a business package fails"

D="$COVWORK/infra-only"
claude_md "$D" '`backend`' '`0.80`' \
  '`com/mealplanner/**/config/**`, `com/mealplanner/**/dto/**`, `com/mealplanner/common/ApiError.class`'
assert_eq "0" "$(run_step "$EXCL" "$D")" \
  "configuration, dto and a named single class are legitimate exclusions"

# The exemption exists, but it is named in the caller and lands in a diff.
assert_eq "0" "$(run_step "$EXCL" "$COVWORK/business-excluded" "config,auth")" \
  "a package named in coverage_infra_packages is accepted"

D="$COVWORK/no-exclusion"
claude_md "$D" '`frontend`' '`79` lines' '(none declared in `angular.json`)'
assert_eq "0" "$(run_step "$EXCL" "$D")" "a repository with no exclusion passes"

# The whole application excluded under one wildcard is the same fiction.
D="$COVWORK/everything"
claude_md "$D" '`backend`' '`0.80`' '`com/elya/**`'
assert_eq "1" "$(run_step "$EXCL" "$D")" "excluding the whole application fails"

# The input exists and carries the default the steps rely on.
assert_ok "harness-invariants declares coverage_infra_packages" -- \
  grep -q '^      coverage_infra_packages:' "$WF/harness-invariants.yml"
assert_ok "the caller template documents the coverage exemption input" -- \
  grep -q 'coverage_infra_packages' "$TPL/ci-caller.yml"


# --- the conventions master when it cannot be read -----------------------
# A Dependabot pull request is not exposed to the repository secret store, so
# harness_token is empty and github.token cannot check out the private harness
# repository: the checkout fails with "repository not found" and every
# Dependabot PR of the portfolio went red on it (control-2026-09-20.md, C1).
# The step is run for real against git fixtures, because the whole question is
# what `git diff` says about a base commit that may or may not be fetched.
extract_step "CONVENTIONS.md matches the harness master" > "$COVWORK/conv.sh"
assert_ok "the conventions-master step has an extractable script" -- \
  test -s "$COVWORK/conv.sh"

# conv_repo <dir> <touches CONVENTIONS.md: yes|no>  : echoes the base SHA
conv_repo() {
  mkdir -p "$1"
  git -C "$1" init -q -b develop
  git -C "$1" config user.email ci@example.invalid
  git -C "$1" config user.name CI
  printf 'master text\n' > "$1/CONVENTIONS.md"
  git -C "$1" add -A
  git -C "$1" commit -qm base
  base=$(git -C "$1" rev-parse HEAD)
  if [ "$2" = yes ]; then
    printf 'master text, edited locally\n' > "$1/CONVENTIONS.md"
  else
    printf '1.18.48\n' > "$1/pom.xml"
  fi
  git -C "$1" add -A
  git -C "$1" commit -qm head
  echo "$base"
}

# with_master <dir> <content>
with_master() {
  mkdir -p "$1/.harness-master"
  printf '%s\n' "$2" > "$1/.harness-master/CONVENTIONS.md"
}

# run_conv <dir> <base sha>  : echoes the exit status
run_conv() {
  ( cd "$1" && BASE_SHA="${2-}" CONVENTIONS_REF=main \
      bash "$COVWORK/conv.sh" > /dev/null 2>&1; echo $? )
}

# The nominal path is unchanged: master readable, copy compared to it.
D="$COVWORK/conv-match"; BASE=$(conv_repo "$D" no)
with_master "$D" 'master text'
assert_eq "0" "$(run_conv "$D" "$BASE")" "a copy identical to a readable master passes"

D="$COVWORK/conv-drift"; BASE=$(conv_repo "$D" yes)
with_master "$D" 'master text'
assert_eq "1" "$(run_conv "$D" "$BASE")" "a copy that drifted from a readable master fails"

# The Dependabot shape: no master, and a diff that cannot touch CONVENTIONS.md.
D="$COVWORK/conv-unreadable-untouched"; BASE=$(conv_repo "$D" no)
assert_eq "0" "$(run_conv "$D" "$BASE")" \
  "an unreadable master passes when the change leaves CONVENTIONS.md alone"

# The one shape that must still fail: the copy is edited and nothing can check it.
D="$COVWORK/conv-unreadable-touched"; BASE=$(conv_repo "$D" yes)
assert_eq "1" "$(run_conv "$D" "$BASE")" \
  "an unreadable master fails when the change edits CONVENTIONS.md"

# No base SHA means no pull request, so the secret was available and its absence
# is a real fault, not the Dependabot exemption.
D="$COVWORK/conv-unreadable-push"; BASE=$(conv_repo "$D" no)
assert_eq "1" "$(run_conv "$D" "")" \
  "an unreadable master fails outside a pull request, where no exemption applies"

# The exemption never covers an absent copy.
D="$COVWORK/conv-missing"; BASE=$(conv_repo "$D" no)
rm "$D/CONVENTIONS.md"
assert_eq "1" "$(run_conv "$D" "$BASE")" "a missing CONVENTIONS.md fails whatever the master"

# The checkout must be allowed to fail, or the step above never runs.
assert_ok "the conventions-master checkout is not fatal on its own" -- \
  grep -q '^        continue-on-error: true' "$WF/harness-invariants.yml"


# --- lot 18: lint.yml has a branch for `other` and `harness` -------------
# P5-#21: both stacks were accepted by this workflow and matched no step, so
# `deployment` and `summerize-youtube` ran a lint job that checked nothing. The
# two steps are extracted and executed, for the same reason as the coverage
# ones: a grep cannot tell a check that runs from a check that matches no file.
assert_ok "lint runs shellcheck on other and harness" -- \
  grep -q "if: inputs.stack == 'other' || inputs.stack == 'harness'" "$WF/lint.yml"
assert_eq "2" "$(grep -c "if: inputs.stack == 'other' || inputs.stack == 'harness'" "$WF/lint.yml")" \
  "both new steps carry the stack condition"
assert_ok "the harness CI exercises its own lint branch" -- \
  grep -q 'uses: ./.github/workflows/lint.yml' "$REPO_ROOT/.github/workflows/ci.yml"

extract_step_from "$WF/lint.yml" "ShellCheck" > "$COVWORK/shellcheck.sh"
extract_step_from "$WF/lint.yml" "YAML syntax" > "$COVWORK/yamlcheck.sh"
assert_ok "the shellcheck step has an extractable script" -- test -s "$COVWORK/shellcheck.sh"
assert_ok "the YAML step has an extractable script" -- test -s "$COVWORK/yamlcheck.sh"

# run_lint <script> <dir>  : echoes the exit status
run_lint() {
  ( cd "$2" && GITHUB_STEP_SUMMARY="$2/summary.md" bash "$1" > /dev/null 2>&1; echo $? )
}

# A repository with nothing to check skips, it does not fail: `deployment`
# before its stacks are written is exactly that shape.
D="$COVWORK/lint-empty"; mkdir -p "$D"
assert_eq "0" "$(run_lint "$COVWORK/yamlcheck.sh" "$D")" "no YAML file is a skip"
assert_eq "0" "$(run_lint "$COVWORK/shellcheck.sh" "$D")" "no shell script is a skip"

D="$COVWORK/lint-yaml-ok"; mkdir -p "$D/stacks"
printf 'services:\n  db:\n    image: postgres:17\n' > "$D/stacks/compose.yml"
printf 'a: 1\n---\nb: 2\n' > "$D/multi.yaml"
assert_eq "0" "$(run_lint "$COVWORK/yamlcheck.sh" "$D")" \
  "valid YAML passes, multi-document files included"

# The failure this branch exists to catch: a compose file nobody can parse.
D="$COVWORK/lint-yaml-broken"; mkdir -p "$D"
printf 'services:\n  db:\n   image: [unclosed\n' > "$D/compose.yml"
assert_eq "1" "$(run_lint "$COVWORK/yamlcheck.sh" "$D")" "unparseable YAML fails"

# The ShellCheck binary is not in the harness dependency budget, and the
# interesting half of the step is which files it hands over, not the findings.
# (A comment opening with the tool's lowercase name is read as a directive and
# fails to parse, SC1073 - which is how the CI caught this file.)
# A stub on PATH records the argument list, so the discovery logic is exercised
# on every machine: the step that checks nothing is the failure being fixed.
STUB="$COVWORK/stub-bin"; mkdir -p "$STUB"
cat > "$STUB/shellcheck" <<'STUBEOF'
#!/usr/bin/env bash
for arg in "$@"; do
  case "$arg" in --*) continue ;; esac
  printf '%s\n' "$arg"
done | sort > "$SHELLCHECK_ARGV"
exit "${SHELLCHECK_EXIT:-0}"
STUBEOF
chmod +x "$STUB/shellcheck"

# run_stubbed <dir> <stub exit>  : echoes the step's exit status
run_stubbed() {
  ( cd "$1" && PATH="$STUB:$PATH" GITHUB_STEP_SUMMARY="$1/summary.md" \
      SHELLCHECK_ARGV="$1/argv.txt" SHELLCHECK_EXIT="$2" \
      bash "$COVWORK/shellcheck.sh" > /dev/null 2>&1; echo $? )
}

D="$COVWORK/lint-discovery"; mkdir -p "$D/scripts" "$D/.git"
printf '#!/usr/bin/env bash\ntrue\n' > "$D/scripts/deploy.sh"
printf '#!/usr/bin/env bash\ntrue\n' > "$D/hook"; chmod +x "$D/hook"
printf '#!/usr/bin/env python3\n' > "$D/tool.py"; chmod +x "$D/tool.py"
printf 'plain text\n' > "$D/README.md"
printf '#!/usr/bin/env bash\ntrue\n' > "$D/.git/hooks-sample.sh"
assert_eq "0" "$(run_stubbed "$D" 0)" "the step passes when shellcheck is happy"
assert_eq "./hook
./scripts/deploy.sh" "$(cat "$D/argv.txt" 2>/dev/null)" \
  "shellcheck receives the .sh files and the shell entry points, and nothing else"
assert_eq "1" "$(run_stubbed "$D" 1)" "a shellcheck finding fails the step"

if command -v shellcheck > /dev/null; then
  D="$COVWORK/lint-sh-ok"; mkdir -p "$D"
  printf '#!/usr/bin/env bash\nset -eu\necho "ok"\n' > "$D/good.sh"
  assert_eq "0" "$(run_lint "$COVWORK/shellcheck.sh" "$D")" "a clean script passes"

  # SC2164, a warning: `cd` with no `|| exit`. It must be a warning-level check
  # and not SC2086, which is info and is filtered out by --severity=warning -
  # the fixture that got this wrong passed locally and failed on the runner.
  D="$COVWORK/lint-sh-bad"; mkdir -p "$D"
  printf '#!/usr/bin/env bash\nunused=1\ncd /tmp\necho done\n' > "$D/bad.sh"
  assert_eq "1" "$(run_lint "$COVWORK/shellcheck.sh" "$D")" "a script with a warning fails"

  # A shell entry point without the .sh suffix is still shell: the hooks ship
  # that way, and skipping them is how a lint job checks nothing.
  D="$COVWORK/lint-sh-noext"; mkdir -p "$D"
  printf '#!/usr/bin/env bash\nunused=1\ncd /tmp\necho done\n' > "$D/hook"
  chmod +x "$D/hook"
  assert_eq "1" "$(run_lint "$COVWORK/shellcheck.sh" "$D")" \
    "an executable shell script without a .sh suffix is checked too"
else
  echo "  (skipped: shellcheck not installed, the shell lint is not executed)"
fi

# --- lot 20: the plugin version moves with the plugin content -------------
# Extracted and run for real, like the coverage steps above. A grep for
# "version" would pass on a step whose comparison never fires.
extract_step "A change under plugins/ carries a version bump" > "$COVWORK/bump.sh"
assert_ok "the version-bump step has an extractable script" -- test -s "$COVWORK/bump.sh"

BUMPWORK=$(mktemp -d)
trap 'rm -rf "$COVWORK" "$BUMPWORK"' EXIT

# write_manifests <repo> <version> : the shape of the real manifests, where the
# marketplace carries its own version under metadata and the plugin's under
# plugins[0].
write_manifests() {
  cat > "$1/.claude-plugin/marketplace.json" <<EOF
{"name": "claude-harness", "metadata": {"version": "$2"},
 "plugins": [{"name": "claude-harness", "version": "$2"}]}
EOF
  cat > "$1/plugins/claude-harness/.claude-plugin/plugin.json" <<EOF
{"name": "claude-harness", "version": "$2"}
EOF
}

B="$BUMPWORK/repo"
mkdir -p "$B/plugins/claude-harness/hooks" "$B/plugins/claude-harness/.claude-plugin" "$B/.claude-plugin"
git -C "$B" init -q -b develop
git -C "$B" config user.email test@example.com
git -C "$B" config user.name Test
write_manifests "$B" 1.0.0
printf 'one\n' > "$B/plugins/claude-harness/hooks/a.sh"
git -C "$B" add -A && git -C "$B" commit -qm "feat: first"
C1=$(git -C "$B" rev-parse HEAD)

printf 'two\n' >> "$B/plugins/claude-harness/hooks/a.sh"
git -C "$B" commit -qam "feat: a hook change with no bump"
C2=$(git -C "$B" rev-parse HEAD)

printf 'three\n' >> "$B/plugins/claude-harness/hooks/a.sh"
write_manifests "$B" 1.0.1
git -C "$B" commit -qam "feat: a hook change with the bump"
C3=$(git -C "$B" rev-parse HEAD)

write_manifests "$B" 1.0.2
git -C "$B" commit -qam "docs: a version bump on its own"
C4=$(git -C "$B" rev-parse HEAD)

printf 'four\n' >> "$B/plugins/claude-harness/hooks/a.sh"
sed -i 's/"version": "1.0.2"/"version": "1.1.0"/' "$B/.claude-plugin/marketplace.json"
git -C "$B" commit -qam "feat: a bump the plugin manifest did not follow"
C5=$(git -C "$B" rev-parse HEAD)

# run_bump <head-ref> <base-sha> : sets BUMP (its output) and BUMP_RC.
# A command substitution would run this in a subshell and lose both.
run_bump() {
  git -C "$B" -c advice.detachedHead=false switch -q --detach "$1"
  BUMP=$(cd "$B" && BASE_SHA="$2" bash "$COVWORK/bump.sh" 2>&1)
  BUMP_RC=$?
}

expect_bump() { # expect_bump <exit> <head> <base> <label>
  run_bump "$2" "$3"
  assert_eq "$1" "$BUMP_RC" "$4"
}

expect_bump 1 "$C2" "$C1" "a plugins/ change with no bump fails the step"
assert_contains "$BUMP" "leaves the version at 1.0.0" "the failure names the stuck version"
assert_contains "$BUMP" "::error::" "the failure is an annotation"

expect_bump 0 "$C3" "$C2" "the same change with the bump passes"
assert_contains "$BUMP" "version 1.0.0 -> 1.0.1" "the pass reports the move"

expect_bump 0 "$C3" "$C1" "a pull request spanning both passes once the bump is in"
expect_bump 0 "$C4" "$C3" "a version-only change passes"
assert_contains "$BUMP" "version 1.0.1 -> 1.0.2" "the version-only change reports its move"
expect_bump 0 "$C4" "$C4" "an unchanged tree passes"
assert_contains "$BUMP" "nothing under plugins/" "an unchanged tree says so"

expect_bump 1 "$C5" "$C4" "a bump the manifest did not follow fails"
assert_contains "$BUMP" "version fields disagree" "the failure names the disagreement"

git -C "$B" -c advice.detachedHead=false switch -q --detach "$C4"
write_manifests "$B" 1.0.1
printf 'five\n' >> "$B/plugins/claude-harness/hooks/a.sh"
git -C "$B" commit -qam "feat: a change that moves the version backwards"
C6=$(git -C "$B" rev-parse HEAD)
expect_bump 1 "$C6" "$C4" "a version moved backwards fails"
assert_contains "$BUMP" "moves the version backwards, 1.0.2 -> 1.0.1" "the failure names the regression"

# Run against a consistent tree: a disagreeing tree fails on that first, which
# would make these two assertions pass for the wrong reason.
expect_bump 0 "$C4" "" "no base commit: skipped, not failed"
assert_contains "$BUMP" "::warning::" "no base commit: said out loud"
expect_bump 0 "$C4" "0000000000000000000000000000000000000000" \
  "an unreachable base commit: skipped, not failed"
assert_contains "$BUMP" "is unreachable" "an unreachable base commit: said out loud"

# A consuming repository has no plugin tree: the step must not fail there.
N="$BUMPWORK/consumer"
mkdir -p "$N"
git -C "$N" init -q -b develop
git -C "$N" config user.email test@example.com
git -C "$N" config user.name Test
printf 'x\n' > "$N/file"
git -C "$N" add -A && git -C "$N" commit -qm "feat: consumer"
NOBASE=$(git -C "$N" rev-parse HEAD)
CONSUMER=$(cd "$N" && BASE_SHA="$NOBASE" bash "$COVWORK/bump.sh" 2>&1; echo "|$?")
assert_eq "0" "${CONSUMER##*|}" "a repository with no plugin tree skips"
assert_contains "$CONSUMER" "not the harness repository" "and says why it skipped"

finish
