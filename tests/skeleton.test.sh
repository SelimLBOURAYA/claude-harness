#!/usr/bin/env bash
# Checks the lot 4 validation criterion the way it can be checked without a
# GitHub runner: a repository generated from templates/project satisfies, file
# by file, every rule harness-invariants.yml enforces.
set -uo pipefail
. "$(dirname "$0")/lib.sh"

SK="$REPO_ROOT/templates/project"
TPL="$REPO_ROOT/templates"

# --- the mandatory document set (section 12) -----------------------------
for f in CLAUDE.md AGENTS.md README.md lots.md .gitignore .env.example \
         .claude/settings.json; do
  assert_file "$SK/$f" "the skeleton ships $f"
done
# CONVENTIONS.md is deliberately NOT here: it is copied from the harness master
# at bootstrap time, so the skeleton cannot hold a copy that drifts from it.
assert_eq "absent" "$([ -f "$SK/CONVENTIONS.md" ] && echo present || echo absent)" \
  "the skeleton does not carry its own CONVENTIONS.md"
BOOTSTRAP="$REPO_ROOT/plugins/claude-harness/skills/bootstrap-project/SKILL.md"
# Read from ref main, never from the clone's working tree: harness-invariants.yml
# compares against main, so a clone on a lot branch would seed a copy CI rejects.
assert_ok "the bootstrap skill reads CONVENTIONS.md from ref main" -- \
  grep -qF 'git -C "$HARNESS" show main:CONVENTIONS.md > CONVENTIONS.md' "$BOOTSTRAP"
assert_eq "" "$(grep -n 'cp "\$HARNESS/CONVENTIONS.md"' "$BOOTSTRAP" || true)" \
  "the bootstrap skill never copies CONVENTIONS.md from the working tree"

# --- the mirror invariant holds in the skeleton itself -------------------
assert_ok "the skeleton CLAUDE.md and AGENTS.md are byte-identical" -- \
  cmp -s "$SK/CLAUDE.md" "$SK/AGENTS.md"

# --- gate parameters: every row present ---------------------------------
assert_ok "the skeleton declares a Gate parameters section" -- \
  grep -q '^## Gate parameters' "$SK/CLAUDE.md"
for p in Stack "Validation command" "Coverage tool" "Coverage threshold" \
         "Coverage exclusions" "Migrations directory" "Lots file" \
         "Frontend backend pair" "Health path" "Dist forbidden pattern" "Image name"; do
  assert_ok "the skeleton declares the '$p' row" -- \
    grep -qF "| \`$p\`" "$SK/CLAUDE.md"
done
# The workflow reads these exact labels; a renamed row is a silent gap.
WF_PARAMS=$(sed -n '/for p in Stack/,/done/p' "$REPO_ROOT/.github/workflows/harness-invariants.yml")
for p in Stack "Lots file" "Image name"; do
  assert_ok "harness-invariants and the skeleton agree on '$p'" -- \
    grep -qF "\"$p\"" <<< "$WF_PARAMS$(printf '\n"Stack"')"
done

# --- the plugin declaration, and the ref that makes it safe --------------
S="$SK/.claude/settings.json"
assert_ok "the skeleton settings are valid JSON" -- python3 -m json.tool "$S"
assert_eq "main" "$(jq -r '.extraKnownMarketplaces["claude-harness"].source.ref' "$S")" \
  "the skeleton pins the marketplace to ref main"
assert_eq "github" "$(jq -r '.extraKnownMarketplaces["claude-harness"].source.source' "$S")" \
  "the skeleton declares a github marketplace source"
assert_eq "true" "$(jq -r '.enabledPlugins["claude-harness@claude-harness"]' "$S")" \
  "the skeleton enables the plugin"

# --- section 8: the documentation is versioned, the secrets are not ------
for doc in 'CLAUDE.md' 'AGENTS.md' 'CONVENTIONS.md' 'lots.md'; do
  assert_eq "" "$(grep -nE "^/?$doc$" "$SK/.gitignore" || true)" \
    "the skeleton .gitignore never ignores $doc"
done
assert_ok "the skeleton ignores .env" -- grep -qx '\.env' "$SK/.gitignore"
assert_ok "the skeleton ignores only local markdown overrides" -- \
  grep -qx '\*\.local\.md' "$SK/.gitignore"
# Section 5: a template, not a secret store.
assert_eq "" "$(grep -nE '^(DB_PASSWORD|DB_USERNAME|API_KEY|.*SECRET.*|.*TOKEN.*)=.+' "$SK/.env.example" || true)" \
  "the skeleton .env.example carries no value for any secret"

# --- P6-D10: the lots file opens with the status table -------------------
first_table=$(grep -n '^|' "$SK/lots.md" | head -1)
assert_ok "the skeleton lots file has a table" -- test -n "$first_table"
case "${first_table#*:}" in
  *Lot*Branche*Statut*) assert_eq "ok" "ok" "the skeleton lots file opens with | Lot | Branche | Statut |" ;;
  *) assert_eq "ok" "wrong table" "the skeleton lots file opens with | Lot | Branche | Statut |" ;;
esac
assert_ok "the skeleton lots file documents the status legend" -- \
  grep -q '⬜' "$SK/lots.md"
# P6-D5: no calendar commitment, and the template says why.
assert_ok "the skeleton lots file forbids dates" -- \
  grep -q 'Pas de dates' "$SK/lots.md"

# --- the drift the audit found must not come back ------------------------
# Finding #1: skills live in .claude/skills/, never in skill/.
assert_eq "" "$(grep -rnE '(^|[^.a-z/])skill/[a-z-]+/' "$SK" || true)" \
  "the skeleton references no legacy skill/ path"
# Finding #25 and section 7: no lot-XX-slug, no branching from main.
assert_eq "" "$(grep -rn 'lot-XX' "$SK" || true)" \
  "the skeleton uses lot-N, never lot-XX"
assert_eq "" "$(grep -rnE 'from `?main`?|base: *main|switch -c [a-z/-]+ main' "$SK" \
  | grep -v 'develop' || true)" \
  "the skeleton never branches from main"
assert_ok "the skeleton states that promotion is user-only" -- \
  grep -q 'user-only' "$SK/CLAUDE.md"
# P6-D3: non-Claude agents are told where the procedures are.
assert_ok "the skeleton points non-Claude agents at the local clone" -- \
  grep -q 'ENV/projets/claude-harness/plugins/claude-harness/skills' "$SK/CLAUDE.md"
# Lot 20: the subset that is wrong is the one under a stale plugin. A generated
# repository must say that a missing skill stops the session, not that the clone
# is a fallback for it.
assert_ok "the skeleton stops on a stale plugin" -- \
  grep -qF 'A stale plugin stops the session' "$SK/CLAUDE.md"
assert_ok "the skeleton says which symptom to watch for" -- \
  grep -qF 'Unknown skill' "$SK/CLAUDE.md"
assert_ok "the skeleton sends to the marketplace refresh" -- \
  grep -qF 'plugin marketplace update claude-harness' "$SK/CLAUDE.md"
# The gate order is the same one the skills implement.
assert_ok "the skeleton documents the four-step gate order" -- \
  grep -qF 'lot-test → lot-review → lot-audit → lot-ship' "$SK/CLAUDE.md"

# --- P5-#18: the image ships the artefact the tests ran on ---------------
assert_file "$SK/Dockerfile" "the skeleton ships a backend Dockerfile"
assert_ok "the Dockerfile copies the built jar instead of rebuilding it" -- \
  grep -q 'COPY --chown=app:app target/\*.jar' "$SK/Dockerfile"
# A build stage would produce a different jar from the tested one; the template
# must not reintroduce one.
assert_eq "" "$(grep -nE 'skipTests|mvnw +package|FROM .*AS +build' "$SK/Dockerfile" \
  | grep -v '^[0-9]*:#' || true)" \
  "the Dockerfile has no build stage recompiling an untested jar"
assert_ok "the Dockerfile explains why there is no build stage" -- \
  grep -q 'DIFFERENT jar' "$SK/Dockerfile"
assert_ok "the Dockerfile runs as a non-root user" -- grep -q '^USER app' "$SK/Dockerfile"
assert_ok "the Dockerfile declares a healthcheck with a start period" -- \
  grep -q 'start-period=' "$SK/Dockerfile"
# Section 2.5: the smoke test runs against a real database.
assert_file "$SK/compose.ci.yml" "the skeleton ships the CI compose file"
assert_ok "the compose file starts a real PostgreSQL" -- \
  grep -q 'image: postgres:' "$SK/compose.ci.yml"
assert_ok "the compose file takes the image under test from the environment" -- \
  grep -q 'image: \${IMAGE:?' "$SK/compose.ci.yml"

# --- the CI caller is not duplicated inside the skeleton -----------------
# One source of truth: the bootstrap skill copies templates/ci-caller.yml in.
# A second copy under templates/project/ would drift from it within one lot.
assert_eq "absent" \
  "$([ -f "$SK/.github/workflows/ci.yml" ] && echo present || echo absent)" \
  "the skeleton holds no second copy of the CI caller"
assert_ok "the bootstrap skill installs the CI caller" -- \
    grep -qE 'ci-caller.yml" +\.github/workflows/ci\.yml' "$BOOTSTRAP"
assert_ok "the bootstrap skill installs dependabot" -- \
  grep -qE 'dependabot.yml" +\.github/dependabot\.yml' "$BOOTSTRAP"
# P6-D9: the image jobs ship commented out, enabled by the project's image lot.
assert_eq "" "$(grep -nE '^  image-(publish|smoke):' "$TPL/ci-caller.yml" || true)" \
  "the caller template leaves the image jobs commented out"
assert_ok "the caller template says which lot enables them" -- \
  grep -q 'image lot' "$TPL/ci-caller.yml"

# --- no placeholder syntax leaks into a rule ----------------------------
# Every {{PLACEHOLDER}} must be upper case and self-describing: a lower-case one
# reads like real content and survives the bootstrap unnoticed.
assert_eq "" "$(grep -rhoE '\{\{[a-z][A-Za-z_]*\}\}' "$SK" "$TPL/ci-caller.yml" \
  | grep -v '{{slug}}' | sort -u || true)" \
  "every placeholder is upper case, except the documented {{slug}}"
assert_ok "the bootstrap skill checks that no placeholder survives" -- \
  grep -qF "grep -rn '{{'" \
  "$REPO_ROOT/plugins/claude-harness/skills/bootstrap-project/SKILL.md"

# --- the skeleton parses --------------------------------------------------
if python3 -c 'import yaml' 2>/dev/null; then
  # One file, so no loop: a double-quoted single-element `for` runs once anyway
  # and reads as if it iterated (SC2066).
  assert_ok "compose.ci.yml parses as YAML" -- \
    python3 -c 'import sys,yaml; yaml.safe_load(open(sys.argv[1]))' "$SK/compose.ci.yml"
fi

finish
