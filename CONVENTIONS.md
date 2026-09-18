# Personal coding conventions

Cross-cutting rules applied to **all** my projects. Loaded automatically via `~/.claude/CLAUDE.md` (so visible in every Claude Code session, including when the model is routed via DeepClaude / OpenRouter).

**Master and copies**: `~/.claude/coding-conventions.md` is the **master**. Every project carries a byte-identical versioned copy at `CONVENTIONS.md` (repo root) so the rules are visible to teammates and to agents that only read repository files. Any edit to the master MUST be propagated to every project's `CONVENTIONS.md` (see §12); copies never diverge — project-specific needs go to the project's `CLAUDE.md`, not to a forked copy.

A project's `CLAUDE.md` MUST NOT reduplicate these rules; it references `CONVENTIONS.md` and focuses on what is specific to the project (stack, data model, lots, project-specific secrets).

---

## 1. Domain model

### Business behavior on the entity rather than a utility class

When business logic has **no external dependency beyond the entity** (no repository, no injected service, no I/O — only the entity's internal state and its loaded associations), place it as an **instance method on the entity** rather than in a separate utility class (`XxxTotals`, `XxxHelper`, `XxxUtils`…).

**Example**: `quote.recomputeTotals()` rather than `QuoteTotals.recompute(quote)`.

**Why**: preference for a rich domain model (tell-don't-ask). Avoids the proliferation of anemic utility classes (`final` + private constructor for 15 lines), keeps behavior close to the state it manipulates, improves readability.

**How to apply**:
- For any new business logic on an entity, **first** consider an instance method; create a utility class/service only if an external dependency is required (repository, injected service, transaction, security, I/O).
- Computation constants (e.g. `HUNDRED` for a VAT calculation) MAY remain `private static final` in the entity.
- Applies to **new** methods; do not refactor existing code en masse unless explicitly asked.
- If the project's entities are currently anemic (just `@Getter @Setter` Lombok), enriching incrementally is fine; signal to the user if the addition creates a strong inconsistency with the rest of the project.

---

## 2. Lot / ticket workflow

1. **Refresh the lots/tickets file first** (`lots.md`, `LOTS.md`, `TODO.md`…). Cross-check with `git log --oneline` and the codebase: mark finished lots with their commit SHA + a short "Done" summary, mark resolved "Known issues", verify the section of the upcoming lot still reflects reality. Separate commit `docs: sync lots.md status` **before** any implementation.
2. Read the lot section. If a criterion is ambiguous, **stop and ask** before coding.
3. Create the branch `feat/lot-[N]-[short-description]` from `develop` (see §7 — branching model).
4. Implement **strictly** the lot scope. Anything beyond → suggestion in the PR description for a dedicated lot.
5. **Write the lot's tests alongside the code**: every new/modified public service method has at least one unit test; every new endpoint has an integration test. Tests are part of the lot scope, **not** a later lot.
6. The **validation gate** (`./mvnw verify`, `npm test`, etc. — see project `CLAUDE.md`) MUST pass **green** before each commit. A red test blocks the commit — fix the code or remove the feature, **never** skip the test.
7. Commits in small logical chunks with **Conventional Commits** messages (`feat:`, `fix:`, `refactor:`, `test:`, `chore:`, `docs:`) — short messages.
8. Before opening the PR: run the validation gate one last time. PR rejected if the suite is red.
9. Open the PR to `develop` and **stop**. Do not start the next lot until the PR is merged.

---

## 3. Forbidden patterns (cross-cutting)

- Hard-coded identifiers, API keys, passwords, absolute paths in code (always via env vars / config)
- `System.out.println` / `console.log` left in code — use the project logger
- Silent `catch (Exception e)` — at minimum log with context, ideally rethrow typed
- Commented-out code left in commits
- `@Disabled`, `@Ignore`, `test.skip`, or removing an assertion to make a build pass — a red test is fixed, not masked
- Adding a public service method without an associated unit test in the same commit
- Adding a new REST endpoint without an associated integration test in the same commit
- Returning JPA/ORM entities from controllers — always via DTO
- Branching from `main`, pushing to `main`, or opening a PR to `main` — the promotion path is `develop` → `main`, user-only (§7)
- Field injection (`@Autowired` on a field) — always constructor injection
- Lombok `@Data` on an entity with relations (use `@Getter @Setter @EqualsAndHashCode(of = "id")`)

---

## 4. Ask before doing

Stop and ask for explicit confirmation **before**:
- Adding a dependency not present in `pom.xml` / `package.json`
- Modifying the data model (new entity, column, FK, migration)
- Adding a new top-level package / new module
- Touching files outside the current lot scope
- Any decision with **security** or **data-loss** impact
- Force-push, destructive reset, remote branch deletion

**Exception — LLM profile switch**: running `/home/selim/.local/bin/claude-profile claude` (exclusively for review requests) or `/home/selim/.local/bin/claude-profile deepseek` (for delegated coding tasks) is **pre-authorized** and does not require a confirmation prompt each time. Invoking one of these two exact commands *is* the explicit instruction — no separate "are you sure you want to switch LLM" step. Any other way of changing the active model/provider (editing `settings.json` directly, a different script, a third profile) still falls under this section and requires confirmation.

---

## 5. Secrets / environment

- `.env` listed in `.gitignore` from the very first commit — `.env.example` is the committed template
- All secrets read via `${ENV_VAR}` placeholders in config (`application.yaml`, etc.) — **no default value** for secrets
- **Fail fast** at startup if a required secret is missing (`@Validated` on `@ConfigurationProperties` for Spring, equivalent for other stacks)

---

## 6. REST architecture (backend side)

- Pure REST API, no server-side rendering (JSP, server-side Thymeleaf, etc.)
- `@RestController` only on the web layer
- DTOs strictly separated from JPA entities — no entity returned by a controller
- MapStruct (or equivalent) for entity ↔ DTO conversions
- Layering **Repository → Service → Controller**, no layer-skipping
- Validation via `jakarta.validation` on DTOs
- Centralised errors via `@RestControllerAdvice` (Spring) — RFC 7807 Problem Details response when possible
- Soft delete via a `deleted` flag + `@SQLRestriction("deleted = false")` rather than physical deletion

---

## 7. Commits, branches, PRs

- **Branching model** (decision 2026-09-17) — two long-lived branches:
  - `main` = **production**. Prod deployments and prod image tags come from it. The agent **never** branches from it, never opens a PR to it, never pushes to it.
  - `develop` = **integration**. Every lot/ticket/chore branch is created from `develop`, every PR targets `develop`, dev builds and dev image tags come from it.
  - The `develop` → `main` promotion is done by the **user only**. If a project has no `develop` branch, create it from `main` (`git switch -c develop main && git push -u origin develop`) and say so, rather than falling back to `main`.
  - **CI**: the validation gate runs on `develop`, on `main` and on every PR targeting them. When a project publishes images, `main` feeds the **production** tags (`latest` + short SHA) and `develop` feeds the **dev** tags (`dev` + short SHA); a dev tag is never deployed to production.
  - Exception — a production hotfix explicitly requested on `main`: branch `fix/[short-description]` from `main`, PR to `main`, and tell the user the same fix must be replayed on `develop`.
- **Commits**: Conventional Commits, short messages, in **English**.
  - Format: `<type>(<scope>): <message>` — `type` ∈ `feat | fix | refactor | test | chore | docs`.
  - `scope` = lot number when the commit is part of a lot (e.g. `feat(12): split quote totalPrice into HT/VAT/TTC`). For cross-cutting chores (gitignore, deps, CI…), scope omitted (`chore: ...`).
- **Branches**: one branch per lot/ticket — `feat/lot-[N]-[short-description]` (flat, **no** sub-version `N.M`), branched from `develop`. For a cross-cutting chore: `chore/[short-description]`, also from `develop`.
- **PRs**:
  - Opened against `develop` after explicit user approval, never auto-merged.
  - **Title**: same format as the main commit (`<type>(<lot>): <message>`).
  - **Body**: exactly two sections — `## Summary` (bullets describing the changes) then `## Test plan` (`- [ ]` checklist of local verifications, ticked if already passed). No additional section unless it adds real info (e.g. `## DB migration` when there is a changeset).
- Prefer creating a **new commit** rather than amending an existing one (unless explicitly asked).
- Never use `--no-verify` or skip hooks without explicit agreement: if a hook fails, investigate and fix.

---

## 8. Versioned / ignored files

- **Versioned project documentation**: `CLAUDE.md`, `AGENTS.md`, `CONVENTIONS.md`, `LOTS.md`/`lots.md`/`dev-plan.md`, `README.md`, `security.md`, and any root `.md` describing the project are **committed** — this is the doc shared by the team and by every Claude session.
- **Only `*.local.md` files are ignored** (personal per-machine overrides, e.g. `CLAUDE.local.md`). This rule appears explicitly in each project's `.gitignore`:
  ```
  # Personal overrides only
  *.local.md
  ```
- **Never** add `CLAUDE.md`, `LOTS.md`, `AGENTS.md` (or equivalents) to `.gitignore`. If this is the case in an existing project, fix it on first intervention.

---

## 9. Session startup (agent framing — all projects)

At every session startup, the agent (Claude Code or other) MUST silently:

1. Read the project's `CONVENTIONS.md` (versioned copy of this file — cross-cutting rules) then `CLAUDE.md` — stack, architecture, project-specific secrets, documents census
2. Read the lots file (`lots.md` / `LOTS.md` / `dev-plan.md`) if present — specifications and status
3. **Identify the project's skills**: note every skill listed in `CLAUDE.md`'s "Skills" table — its name, trigger condition, and any gate it forms (e.g., `lot-test → lot-audit → lot-ship`). These skills MUST be invoked via the `Skill` tool at their trigger moment (§13).
4. `git log --oneline -10`
5. `git status`
6. `git branch --show-current`

Then summarize in **exactly 3 lines**:
- **Current lot**: which lot is active or next
- **State**: what is done, what is in progress, any uncommitted work
- **Next action**: the first thing about to be done, including which skill to invoke next

Do not start the user's request before this sequence completes.

**Do not include a build/compile** in this sequence — it is expensive at every session start for uncertain benefit. Build runs on demand, or via the validation gate before commit. If a project genuinely needs a project-specific startup check, it adds it in its project `AGENTS.md`.

---

## 10. Pre-commit gate (all projects)

Before staging or committing, the agent MUST:

1. **Re-read** the project memory — all `feedback_*.md` files — via the memory system
2. **Verify** each rule against the staged diff
3. **Confirm**: commit message in English, Conventional Commits format (`<type>(<scope>): <message>`), no ambiguous non-ASCII character (em dash U+2014 → use en dash U+2013 for fallbacks and separators)
4. **Validation gate green** — exact command defined in the project `CLAUDE.md` (`./mvnw verify`, `npm test`, etc.)
5. **Mirror & copies check** (§12): if `CLAUDE.md` or `AGENTS.md` is in the staged diff, `cmp CLAUDE.md AGENTS.md` MUST be silent; if `CONVENTIONS.md` is staged, it MUST be identical to the master `~/.claude/coding-conventions.md`
6. **Skill deliverables**: if the project defines a skill gate (LOTD or equivalent) and the branch matches a lot/ticket pattern (`feat/lot-*`), verify that the current step's skill deliverable exists — e.g., `docs/audits/lot-XX.md` for `lot-audit`. A missing deliverable blocks the commit. If unsure which step you are at, invoke the next ungated skill to find out.

**Why**: in-session context compression may demote these rules. This section stays in always-loaded docs and MUST be re-read before every commit. Past violations (French commit messages, rule drift, em dash in templates) confirmed that without an explicit reminder, the agent drifts.

---

## 11. Language of instruction documents — English only

All agent-facing instruction documents MUST be written in **English**. Scope:

- `~/.claude/CLAUDE.md`, `~/.claude/coding-conventions.md`, `~/.claude/RTK.md`, and any other always-loaded file under `~/.claude/`
- Per-project `CLAUDE.md`, `AGENTS.md`
- Memory files: `MEMORY.md`, `feedback_*.md`, `user_*.md`, `project_*.md`, `reference_*.md`
- Project skeleton templates in `~/.claude/templates/`

**Why**:
- BPE tokenizers (Claude, GPT, DeepSeek) tokenize English ~25–30% more efficiently than French → significant always-loaded token savings.
- Cross-model instruction-following degrades noticeably on non-English instructions, especially on DeepSeek-family models used via DeepClaude / OpenRouter routing.
- Mixed-language files perform worse than monolingual ones — half-French half-English is the worst case.

**How to apply**:
- When editing any of the above documents, keep all new content in English. Translate any French fragment you encounter while there.
- When the user provides feedback in French (the user speaks French), the rule extracted into a memory file MUST be written in English. The original French quote MAY be preserved in a `> Original (FR): "…"` blockquote when nuance would be lost otherwise.
- When creating a new project from the skeleton template, fill `{{placeholders}}` in English.

**Out of scope**:
- `lots.md` / `LOTS.md` / `dev-plan.md` / `TODO.md` — internal planning docs, not loaded as instructions. These MUST be written in **French** (decision 2026-07-10): they are owner-facing planning documents, read and reviewed by the user, not agent instructions. Technical identifiers (endpoints, column names, branch names, code blocks, SQL) stay in English. When editing one of these files, translate any English prose you encounter while there.
- PR bodies, commit message bodies — MAY stay French; commit titles are already English (§7)
- Project-facing `README.md` — choose per project audience
- User-facing chat: the agent responds in the user's language (French if the user writes in French)

---

## 12. Canonical project documentation set & AGENTS.md mirror

### Mandatory document set

Every project MUST have, at the repo root:

| Document | Role |
|---|---|
| `CLAUDE.md` | Project-specific conventions + the **documents census** (below) |
| `AGENTS.md` | **Byte-identical mirror** of `CLAUDE.md` |
| `CONVENTIONS.md` | Versioned copy of the master `~/.claude/coding-conventions.md` |
| `lots.md` / `LOTS.md` / `dev-plan.md` | Planning: lots and tickets, in **French** (§11) |
| `README.md` | Presentation and quick start |

### Documents census (frozen requirement)

`CLAUDE.md` MUST contain a `## Project documents` section listing **every useful document** of the project: the mandatory set above, the skills (`.claude/skills/*/SKILL.md` — the directory the Claude Code harness scans for project-scoped skills, versioned in the repo like any other project document, never stored outside the project or shared globally), the audit reports (`docs/audits/`), and any project-specific doc (`security.md`, prompt files…). Any document added to the project is added to the census **in the same commit**. Because `AGENTS.md` mirrors `CLAUDE.md`, the census is guaranteed identical in both.

### Mirror invariant `AGENTS.md` = `CLAUDE.md`

- Any edit to one file is replicated **byte for byte** to the other, in the same change — the two files are never allowed to diverge.
- Enforced automatically in Claude Code by the user-level hook `~/.claude/hooks/sync-claude-agents.sh` (PostToolUse on Edit/Write). Outside Claude Code (manual edits, other agents), replicate with `cp` immediately after editing.
- Verified by the pre-commit gate (§10 item 5): `cmp CLAUDE.md AGENTS.md` MUST be silent whenever either file is staged.
- If a divergence is found (external edit), the most recently modified file wins — check `git log` / mtime before overwriting, and surface the divergence to the user.

### Master propagation

After any edit to the master `~/.claude/coding-conventions.md`:
1. Copy it to **every** project's `CONVENTIONS.md` (`cp` — copies stay byte-identical to the master).
2. Commit in each affected repo: `chore: sync CONVENTIONS.md with master`.

The reverse path is forbidden: never edit a project's `CONVENTIONS.md` directly — edit the master, then propagate.

---

## 13. Skill invocation (all projects)

When a project defines **skills** in its `CLAUDE.md` (typically in a "Skills" table with trigger conditions), the agent MUST invoke them via the **`Skill` tool** at the prescribed moments. A skill is a packaged set of instructions — invoking it loads its detailed procedure into the agent's context. The one-line description in `CLAUDE.md` is a **reminder**, not a substitute for the skill file.

### Why

Skills contain **detailed checklists, matrices, and procedures** that the summary table in `CLAUDE.md` does not capture. Executing a skill "from memory" without invoking the `Skill` tool skips these details. Past sessions on kreadevis-backend confirmed that the agent misses mandatory steps (business-rule test matrix, JaCoCo HTML report inspection, security-review subagent launch, architecture audit checklist, audit report writing) when it does not load the skill file.

### How to apply

- **Identify the gate**: read the project's `CLAUDE.md` "Skills" table. If it defines a gate (e.g., `lot-test → lot-audit → lot-ship`), these steps are **mandatory in order**.
- **Invoke at the trigger moment**: when a skill's trigger condition is met (e.g., "lot code complete" for `lot-test`, "after lot-test" for `lot-audit`), invoke `Skill` with that skill name **before** doing any of the work the skill covers.
- **Never skip a gate step**: each lot/ticket gets its own invocation of every gate skill, even if the previous lot passed. A green `lot-audit` on lot 15 does not excuse skipping it on lot 16.
- **Skill instructions take precedence**: when a loaded skill contradicts the agent's default approach, the skill wins. The skill file is the procedure; the agent's memory is fallible.
- **Deliverables are proof**: a gate skill produces a deliverable (e.g., `docs/audits/lot-XX.md` for `lot-audit`). A missing deliverable means the skill was not invoked — the pre-commit gate (§10 item 6) blocks the commit.
