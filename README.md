# claude-harness

Central agentic harness for the portfolio. One repo holds the skills, the hooks, the
reusable CI workflows and the project skeleton; the 8 consuming repos install it as a
Claude Code plugin instead of duplicating it.

- **Marketplace**: this repo (`.claude-plugin/marketplace.json`)
- **Plugin**: `plugins/claude-harness/`
- **Conventions master**: [`CONVENTIONS.md`](CONVENTIONS.md)
- **Plan**: [`dev-plan.md`](dev-plan.md)

## Prerequisites

The repo is **private**. Claude Code clones it with your git credential helper, so
authenticate once:

```bash
gh auth login          # choose HTTPS, and accept "configure git with your credentials"
gh auth setup-git
```

Without this, the marketplace add and the background auto-update both fail with a
credential prompt that never reaches you.

## Installation

Always pin the ref to `main`. The default branch of this repo is `develop`, so a
declaration without a ref would make every merge to `develop` immediately active in
all consuming repos.

### Interactive

```
/plugin marketplace add SelimLBOURAYA/claude-harness@main
/plugin install claude-harness@claude-harness
```

### User level (`~/.claude/settings.json`)

Recommended: the git guard then also covers sessions opened at
`~/ENV/projets` and from the IDEs.

```json
{
  "extraKnownMarketplaces": {
    "claude-harness": {
      "source": {
        "source": "github",
        "repo": "SelimLBOURAYA/claude-harness",
        "ref": "main"
      }
    }
  },
  "enabledPlugins": {
    "claude-harness@claude-harness": true
  }
}
```

### Project level (`.claude/settings.json`)

Same block, committed in each repo, for traceability and so a fresh clone is
harnessed without user-level setup.

## Update

```
/plugin marketplace update claude-harness
```

Only commits already promoted to `main` are picked up. Promotion `develop` → `main`
is manual and done by the repo owner.

## Uninstallation

```
/plugin uninstall claude-harness@claude-harness
/plugin marketplace remove claude-harness
```

Then drop the `extraKnownMarketplaces` and `enabledPlugins` entries from the
settings file you added them to.

## Non-Claude agents

Cursor, DeepClaude/OpenRouter and any agent that does not load Claude Code plugins
read the procedures directly from the local clone:

```
~/ENV/projets/claude-harness/plugins/claude-harness/skills/<name>/SKILL.md
```

Each consuming repo's `CLAUDE.md` points there in its Skills section. Blocking
invariants are **also** enforced by the reusable CI workflows, which are the only
agent-agnostic guard.

## Gate parameters

Every consuming repo carries a `## Gate parameters` section in its `CLAUDE.md`
(therefore in `AGENTS.md`). The skills read it instead of hard-coding commands or
thresholds. Contract:

| Parameter | Meaning | Example |
|---|---|---|
| `Stack` | `backend`, `frontend`, `infra` or `harness` — selects the skill branches | `backend` |
| `Validation command` | The validation gate, run before every commit | `./mvnw verify` |
| `Coverage tool` | Where the coverage gate is wired | `JaCoCo (pom.xml)` |
| `Coverage threshold` | Current ratchet value, never lowered | `0.70` |
| `Coverage exclusions` | Explicit list, empty by default — reviewed at every audit | `config/**`, `dto/**` |
| `Migrations directory` | Path checked by `migrations-immutable.yml` | `src/main/resources/db/changelog/changes/` |
| `Lots file` | Planning file, must start with a `\| Lot \| Branche \| Statut \|` table | `lots.md` |
| `Frontend backend pair` | For a frontend, the repo it is smoke-tested against | `kreadevis-backend` |
| `Health path` | Health endpoint used by `image-smoke.yml` | `/actuator/health` |
| `Dist forbidden pattern` | String that must not appear in a production build | `localhost:8080` |
| `Image name` | GHCR image published by `image-publish.yml` | `ghcr.io/selimlbouraya/kreadevis-backend` |

Parameters that do not apply to a stack are filled with `n/a`, never removed — a
missing line is a drift that `harness-sync` and `harness-invariants.yml` report.

## Skills

| Skill | Role |
|---|---|
| `lot-test` | Tests written and green, coverage gate at the repo threshold |
| `lot-review` | Code review of the lot, inline PR comments, applied fixes (`claude` profile only) |
| `lot-audit` | Security, performance and architecture audit → `docs/audits/lot-N.md` |
| `lot-ship` | Commits, push, PR to `develop`, then stop until merge |
| `harness-sync` | Detects and fixes drift between docs, skills and reality |
| `integration-check` | Manual front ↔ real backend smoke → `docs/audits/lot-0-integration.md` |
| `dep-update` | Patch/minor applied, major proposed |
| `bootstrap-project` | Generates a harnessed repository from `templates/project/` |
| `i-have-adhd` | Focus aid, user-invoked only |

Gate, mandatory in order: `lot-test → lot-review → lot-audit → lot-ship`.

## Hooks

| Hook | Event | Role |
|---|---|---|
| `git-guard.py` | `PreToolUse` on `Bash` | Denies pushes to `main`, force pushes, `--no-verify`, `reset --hard`, remote branch deletion, `gh pr create` without `--base develop`, and `gh pr merge`. Gate deliverables are not its business: `lot-deliverables.yml` owns that rule, and owns it alone. Asks for confirmation on every other push or PR creation, and on anything it cannot parse. |
| `mirror-sync.sh` | `PostToolUse` on `Edit`, `Write`, `Bash` | Keeps `AGENTS.md` byte-identical to `CLAUDE.md`, including after shell edits (`cp`, `mv`, `sed -i`, redirections). |

The guard is intentionally conservative: an unparseable command produces a
confirmation prompt, never a silent allow.

## Reusable CI workflows

Called with `workflow_call` from each repo's `.github/workflows/ci.yml`. Start from
[`templates/ci-caller.yml`](templates/ci-caller.yml).

| Workflow | Checks |
|---|---|
| `harness-invariants.yml` | Mirror, marketplace ref `main`, `CONVENTIONS.md` = master, no `skill/`, census ⇔ skills, lots file status table |
| `commit-format.yml` | Conventional Commits, ASCII title without U+2014 |
| `branch-naming.yml` | `feat/lot-N-slug`, `fix/`, `chore/`, `docs/`; PR base `develop` |
| `migrations-immutable.yml` | Migration files added only, destructive changes marked `contract` |
| `lot-deliverables.yml` | `docs/audits/lot-N.md` present, one lot per PR, lots file touched on status lines only |
| `image-smoke.yml` | Built image started with compose, waits `healthy`, curls the health path |
| `image-publish.yml` | Build, trivy scan, GHCR push (`dev`/`sha-` on `develop`, `latest`/`sha-` on `main`) |
| `frontend-dist.yml` | Production bundle free of the forbidden pattern, `index.html` present |
| `lint.yml` | Prettier/ng lint or Spotless, plus a non-blocking dependency audit |

Access is granted through **Settings → Actions → General → Access →
"Accessible from repositories owned by the user"**. All consuming repos must be
private: GitHub does not let a public repo call a private repo's reusable workflow.

## Development

```bash
./tests/run.sh
```

Runs every `tests/*.test.sh`. Required green before each commit. Dependencies are
limited to `bash`, `python3` and `jq` on purpose — adding one requires approval
(§4 of `CONVENTIONS.md`).
