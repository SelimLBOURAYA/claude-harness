# Personal coding conventions

Cross-cutting rules of every project; project-specific rules go to the project's
`CLAUDE.md`. Each rule has a stable identifier, from which the `deepseek` rules card
(`plugins/claude-harness/rules/deepseek.json`) is generated.

## 1. Domain model

- **CODE-2** Business logic that needs only the entity's own state and loaded associations (no repository, injected service, transaction or I/O) is an instance method of the entity, never a utility class: `quote.recomputeTotals()`, not `QuoteTotals.recompute(quote)`. New code only; refactor existing code when asked.

## 2. Lot workflow

- **LOT-1** Start every lot with the `lot-start` skill, never by inferring "the next lot" yourself. It synchronises the lots file status table with `develop` (first commit of the lot branch, `docs: sync lots file status`), creates `feat/lot-N-slug` from `develop`, and waits for the user's `lot-start confirm N` before any file is written.
- **LOT-2** A status row changes only on evidence from git: its merge on `develop`, or its audit commit. When the mapping is ambiguous, or a row is done with no merge, stop and ask; never pick a lot yourself.
- **LOT-3** Never redo work merged on `develop`: commits there scoped to the candidate lot are a question for the user.
- **LOT-4** If an acceptance criterion is ambiguous, ask all your questions in one batch before writing code; otherwise say "no ambiguity" and restate the criteria in one list.
- **LOT-5** Implement strictly the lot scope. Anything else becomes a suggestion in the PR description.
- **GATE-3** Write the lot's tests with the code: one unit test per new or modified public service method, one integration test (§2.5) per new endpoint, in the same commit.
- **GATE-1** During development, run only the targeted tests of the changed code. Run the full `Validation command` of the project `CLAUDE.md` once, before each commit.
- **GATE-2** The `Validation command` is green before every commit and before the PR. A red test is fixed, never skipped, disabled (`@Disabled`, `@Ignore`, `test.skip`) or stripped of its assertion.
- **LOT-6** One lot per session. Once `lot-ship` has merged the lot's pull request, stop: never start, prepare or test the next lot.

## 2.5 What an integration test is

- **GATE-4** A backend integration test runs on Testcontainers PostgreSQL, the production major version, with the migrations active. A `@SpringBootTest` on H2 with `ddl-auto: create-drop` and migrations disabled is not an integration test.
- **GATE-5** A frontend integration test exercises the component through its real HTTP layer, responses mocked at the transport boundary, never a stubbed service. The real backend is checked by the `integration-check` skill, whose report every frontend PR requires.

## 3. Forbidden patterns

- **CODE-1** Constructor injection only, never `@Autowired` on a field. No `System.out.println` or `console.log` left in code (use the project logger), no silent `catch` (log with context, ideally rethrow typed), no commented-out code, no hard-coded identifier, key, password or absolute path.
- **CODE-5** No Lombok `@Data` on an entity with relations: `@Getter @Setter @EqualsAndHashCode(of = "id")`.

## 4. Ask before doing

- **ASK-1** Ask for explicit confirmation before: adding a dependency absent from `pom.xml` or `package.json`; changing the data model (entity, column, foreign key, migration); adding a top-level package or module; touching files outside the lot scope; any decision with security or data-loss impact; a force-push, a destructive reset or a remote branch deletion.
- **ASK-2** Pre-authorised, without a prompt: `/home/selim/.local/bin/claude-profile claude` or `deepseek` when the user asks for that profile, and `claude plugin update claude-harness@claude-harness` at any scope. Any other change of model, provider or settings needs confirmation.

## 5. Secrets and environment

- **SEC-1** `.env` is listed in `.gitignore` from the first commit; `.env.example` is the committed template.
- **SEC-2** Secrets are read through `${ENV_VAR}` placeholders with no default value, and the application fails fast at startup when one is missing (`@Validated` `@ConfigurationProperties` on Spring).

## 6. REST architecture (backend)

- **API-1** Pure REST API: `@RestController` on the web layer only, no server-side rendering, layering Repository → Service → Controller with no layer skipped.
- **API-2** A controller never returns a JPA entity: DTOs are separate, mapped with MapStruct or an equivalent, and validated with `jakarta.validation`.
- **API-3** Errors are centralised in a `@RestControllerAdvice`, as RFC 7807 Problem Details when possible.
- **API-4** Soft delete through a `deleted` flag and `@SQLRestriction("deleted = false")`, never physical deletion.

## 7. Branches, commits, pull requests

- **GIT-1** `main` is production; `develop` is integration and the GitHub default branch. Branch from `develop` only (`feat/lot-N-slug`, flat, no `N.M`; `fix/slug`; `chore/slug`) and target `develop` with every PR. Never branch from, push to or open a PR to `main`: the `develop` → `main` promotion is the user's. A project without `develop` gets one from `main`, said to the user.
- **GIT-4** A production hotfix explicitly requested on `main`: branch `fix/slug` from `main`, PR to `main`, and tell the user to replay the fix on `develop`.
- **GIT-8** CI runs the validation gate on `develop`, `main` and every pull request to them. Images: `main` publishes `latest` and `sha-<short>`, `develop` publishes `dev` and `sha-<short>`; a `dev` tag is never deployed to production.
- **GIT-2** Commit titles: English, Conventional Commits `<type>(<scope>): <message>`, type one of `feat`, `fix`, `refactor`, `test`, `chore`, `docs`. The scope is the lot number inside a lot (`feat(12): ...`), omitted otherwise (`chore: ...`). No em dash (U+2014). New commits, never an amend unless asked; never `--no-verify`, never a force-push.
- **GIT-5** No repository has branch protection: never merge a pull request whose CI is not green. The sync pull requests (GIT-7) are the one exception.
- **GIT-6** A lot pull request targets `develop` and is opened by `lot-ship`, which merges it (`gh pr merge --merge`) once every check is green; the git guard denies any other merge. Title in the main commit's format; body `## Summary` then `## Test plan` (`- [ ]` checklist), plus a section only when it adds information (`## DB migration`).
- **GIT-7** Sync pull requests (`chore/sync-harness-files`) are merged at once by the harness `sync-projects` workflow, without waiting for their checks, only when the pull request is the sync token account's own, touches nothing but the `synced_files` of `projects.json`, and still heads at the commit the workflow pushed; any other is left open and fails the run. No agent merges one by hand.
- **CODE-3** An applied migration is immutable. Expand then contract: never drop or rename a column or table, or add `NOT NULL`, in the version whose code stops using it; the contract changeset comes in a later version, marked `contract`, its pull request labelled `schema-contract`.

## 8. Versioned and ignored files

- **DOC-3** Project documentation is committed: `CLAUDE.md`, `AGENTS.md`, `CONVENTIONS.md`, the lots file, `README.md` and any root `.md` describing the project. Only `*.local.md` files are ignored; a project ignoring a committed document is fixed on first intervention.

## 9. Session startup

- **START-1** Under Claude Code, start from the repository state the plugin's `SessionStart` hook injects at startup and after every compaction. Then read the project `CLAUDE.md` (Gate parameters, Skills, Project documents) and, once a lot is named, its section of the lots file only. Do not re-read `CONVENTIONS.md`: `~/.claude/coding-conventions.md` loads it.
- **START-2** Without that hook, run the sequence by hand: read the project `CLAUDE.md`, this file and the lots file status table, then `rtk proxy git log --first-parent --oneline -10 origin/develop` (never plain `git log`: the rtk filter hides merge commits), `git status` and `git branch --show-current`.
- **START-3** Summarize in 3 lines: current lot, state, next action with the next skill to invoke. Wait if the user named no lot. No build at startup.
- **CTX-1** A compaction summary is not a source of truth: re-anchor on the hook output (or START-2) and re-read the current lot section before the next write.
- **CTX-2** Read files by targeted range (offset and limit, grep), once; never re-read a whole unchanged file.
- **CTX-3** Before debugging a framework error, check the exact dependency versions in `pom.xml` or `package.json`.
- **CODE-4** Navigate and check code with the LSP tool (definitions, references, diagnostics) before grep or whole-file reads: `jdtls-lsp` for Java, `typescript-lsp` for TypeScript. If it is missing, ask the user to install it from `claude-plugins-official` and reopen the session.
- **PLUG-1** A stale plugin stops lot work: the `SessionStart` warning that the installed version is not the one `main` declares, an unknown `claude-harness:` skill, or a `lot-start confirm N` that writes no lock. Run `claude plugin update claude-harness@claude-harness --scope user`, then `--scope project` in each project installing it, and ask the user to reopen the session. Never fall back to the local clone's `SKILL.md` files.

## 10. Pre-commit gate

- **GIT-3** Before every commit: re-read the feedback memories and check each against the staged diff; check the title against GIT-2; run the `Validation command` (GATE-2); when `CLAUDE.md` or `AGENTS.md` is staged, `cmp CLAUDE.md AGENTS.md` is silent (DOC-1).

## 11. Language

- **DOC-2** Agent instruction documents are in English: `~/.claude/` files, `CONVENTIONS.md`, `CLAUDE.md`, `AGENTS.md`, skills, memories (French feedback becomes an English memory) and the project skeleton. Lots files (`lots.md`, `LOTS.md`, `dev-plan.md`, `TODO.md`) are in French, identifiers in English. PR and commit bodies may be French.

## 12. Project documents

- **DOC-4** Every project carries at its root `CLAUDE.md` (project conventions, `## Gate parameters`, `## Project documents`), `AGENTS.md`, `CONVENTIONS.md`, its lots file and `README.md`.
- **DOC-5** `## Gate parameters` has one row per parameter, `n/a` when one does not apply, never an omitted row: `Stack`, `Validation command`, `Coverage tool`, `Coverage threshold`, `Coverage exclusions`, `Migrations directory`, `Lots file`, `Frontend backend pair`, `Health path`, `Dist forbidden pattern`, `Image name`.
- **DOC-1** `CLAUDE.md` and `AGENTS.md` stay byte-identical (the plugin's `mirror-sync` hook, or `cp` outside Claude Code). Every document added to the project (its skills, its `docs/audits/` reports, any project document) enters `## Project documents` in the same commit.
- **DOC-6** Generic skills ship in the `claude-harness` plugin (`claude-harness:<name>`); project skills live in `.claude/skills/<name>/SKILL.md`. An agent that loads no plugin reads the procedures from `~/ENV/projets/claude-harness/plugins/claude-harness/skills/<name>/SKILL.md`.
- **DOC-7** `CONVENTIONS.md` changes only by a harness pull request; a project's copy is never edited. When the master changes on the harness `main`, `sync-projects` updates every copy (GIT-7), and `harness-invariants.yml` fails a project whose copy differs from the master at `main`. `~/.claude/coding-conventions.md` is a symlink to `~/.claude/plugins/marketplaces/claude-harness/CONVENTIONS.md`, the marketplace clone that follows `main`.

## 13. Skills and the lot gate

- **GATE-6** Invoke a skill with the `Skill` tool when its trigger is met, before doing the work it covers. Its procedure overrides your default approach.
- **GATE-7** The lot gate runs once per lot, in order: `lot-start` → development → `lot-test` → `lot-review` → `lot-audit` → `lot-ship`, with `integration-check` before `lot-ship` on a frontend. Each step is invoked explicitly; never skip one, never run two from one invocation.
- **GATE-8** A gate skill commits its deliverable alone, after a green `Validation command`, before it reports back, and adds it to the census when new: `docs/audits/lot-N-review.md` (`docs(N): add the lot review report`), `docs/audits/lot-N.md` (`docs(N): add the lot audit report`), `docs/audits/lot-0-integration.md` (`docs: add the integration check report`). `lot-deliverables.yml` blocks a pull request without them.
- **GATE-9** When a gate skill fails or costs work for nothing in its own run, record it in `docs/audits/lot-N-friction.md` under `## <skill>`, each entry opening with the key `` `<skill> / <step>` ``. The lot's own bugs are `lot-review` findings, not friction. No check requires the file.

## 14. Review in a new session, under the claude profile

- **PROF-1** Two profiles, switched by `/home/selim/.local/bin/claude-profile`: `claude` (a native Claude model) for review, audit and judgement on produced work; `deepseek` (`ANTHROPIC_BASE_URL=https://api.deepseek.com/anthropic`) for delegated coding. The script rewrites `settings.json`, which only the next session reads: never switch on your own initiative.
- **LOT-7** Development ends after `lot-test`, whatever the profile. Tell the user to end the session, run `claude-profile claude` if the profile is `deepseek`, and open a new session for `lot-review`, `lot-audit` and `lot-ship`. `lot-review` runs only when `ANTHROPIC_BASE_URL` is empty; a model's account of its own identity is never the signal.

## 15. Response shape

- **OUT-0** Never cut these to be concise; state them plainly and early: failures and bad news, assumptions made, anything skipped or left undone, caveats that change the next action, anything the user must do themselves. This rule wins over OUT-1.
- **OUT-1** No preamble, no recap, no closing pleasantry. Time estimates in concrete units. Errors stated factually: file, line, expected vs actual. Answer in the user's language.
- **OUT-2** Fuller output shaping (next action first, numbered steps, state restated each turn) is the `i-have-adhd` skill, invoked by the user only, never a default.
