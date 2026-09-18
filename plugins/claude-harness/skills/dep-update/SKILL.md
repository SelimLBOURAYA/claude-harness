---
name: dep-update
description: >-
  Checks and updates a project's dependencies, applying patch and minor bumps
  and proposing majors, then validating the build before commit. Use when the
  user asks for a dependency update, wants to know what is outdated, or before
  writing a lot PR.
metadata:
  version: "2.0"
---

# Dep Update — Dependency refresh

Reports dependency status, applies **safe** updates, proposes the rest, and
validates the build before any commit. Two levels: **patch/minor** applied,
**major** proposed and never applied without explicit approval (§4 of
`CONVENTIONS.md`).

## 0. Gate parameters

`Stack` selects the toolchain below. `Validation command` is the single build
check used in Step 4. Never improvise either.

| `Stack` | Toolchain |
|---|---|
| `backend` | Maven through the repo's `./mvnw` wrapper |
| `frontend` | npm, through the repo's committed lockfile |
| `infra` / `harness` | No package manager: GitHub Actions SHAs and base images |

## Workflow

```
Task Progress:
- [ ] Step 1 — Outdated report
- [ ] Step 2 — Candidate analysis
- [ ] Step 3 — Apply the safe updates
- [ ] Step 4 — Build verification
- [ ] Step 5 — Report, then offer the commit
```

### Step 1 — Outdated report

Produce the report **without touching** the manifest.

*Maven:*

```bash
./mvnw versions:display-dependency-updates versions:display-plugin-updates \
  -DprocessDependencyManagement=false 2>&1 | tee /tmp/dep-report.txt
```

*npm:*

```bash
npm outdated || true
npm audit --audit-level=high || true
```

*Actions and base images:* list the pinned SHAs in `.github/workflows/*.yml` and
the `FROM` lines of the Dockerfiles, and compare each against its latest release.

### Step 2 — Candidate analysis

| Criterion | Rule |
|---|---|
| **Patch** (`x.y.Z`) | Apply — minimal risk |
| **Minor** (`x.Y.z`) | Apply, unless the version is managed by a BOM or by the framework's dependency set |
| **Major** (`X.y.z`) | **Propose only** — never apply without approval |
| Framework parent or CLI (Spring Boot parent, Angular) | **Propose only** — a framework bump is a lot of its own, not a chore |
| BOM-managed dependency | Do **not** pin a version in the manifest; the parent manages it. It moves when the parent moves |
| Transitive-only advisory | Fix through the direct dependency that pulls it; do not add a direct dependency just to override a version without saying so |

Adding a **new** dependency is out of this skill's scope: it requires explicit
approval (§4).

### Step 3 — Apply the safe updates

*Maven:*

```bash
./mvnw versions:use-latest-releases -DallowMajorUpdates=false -DgenerateBackupPoms=false
```

*npm:*

```bash
npm update           # respects the semver ranges in package.json
npm audit fix        # never `--force`: that pulls majors in silently
```

*Actions:* update the pinned SHA and the `# vX.Y.Z` comment **together** — a SHA
without its version comment is unreviewable.

Read the manifest before and after, and confirm only the expected lines moved. If
a BOM-managed version got pinned, remove the pin by hand. Commit the lockfile
with the manifest.

### Step 4 — Build verification

```bash
<Validation command>
```

- Green → continue.
- Red → identify the culprit, **revert that one dependency**, re-run, and record
  it in the report. Never lower a coverage threshold or skip a test to make a
  dependency bump pass.

### Step 5 — Report

```markdown
## dep-update report — YYYY-MM-DD

### Applied
| Dependency | From | To | Type |
|---|---|---|---|

### Proposed (major / framework)
| Dependency | Current | Available | Why it needs a decision |
|---|---|---|---|

### Managed by the BOM or framework (untouched)
| Dependency | Current version |
|---|---|

### Security advisories
| Advisory | Severity | Status |
|---|---|---|

### Build
- `<Validation command>`: green / red

### Reverted
| Dependency | Reason |
|---|---|
```

Then propose the commit and **wait** for confirmation:

```
chore(deps): update the patch and minor dependencies
```

Scope is `deps` for a standalone refresh, or the lot number when the refresh is
part of a lot.

## Rules

- Never bump a framework parent or CLI without explicit approval.
- Never apply a major without explicit approval.
- Never add a new dependency here — §4 applies.
- Never commit a manifest with a red build.
- Never pin a version the BOM already manages.
- A dependency you cannot identify → stop and ask.
