# Lot Audit — Checklists

Generic checklists for the portfolio. Apply **only** to the files modified by the
current lot. Rows marked *(backend)* or *(frontend)* apply to that `Stack` only;
the rest apply to both.

---

## Security

### Secrets and configuration

- [ ] No secret, API key, token or password hard-coded in committed code or config
- [ ] Every secret read through an env var placeholder, with **no default value**
      (§5 of `CONVENTIONS.md`)
- [ ] Startup fails fast when a required secret is missing
- [ ] `.env` ignored, `.env.example` committed and up to date with the new vars
- [ ] No absolute user path (`/home/<user>/…`) in committed code

### Authentication and authorisation

- [ ] Credentials hashed with a slow hash — never plain in logs, responses or
      test assertions
- [ ] Token validated (signature **and** expiry) on every protected route
- [ ] Authorisation checked per resource, not only per role: a user cannot read or
      mutate another user's row (horizontal escalation)
- [ ] CORS restricted to a configured origin list — no `*` in production
- [ ] *(frontend)* No token in `localStorage` if the project decided otherwise; no
      token logged or put in a URL

### Input validation

- [ ] Declarative validation on every request body at the HTTP boundary
- [ ] Server-generated identifiers and references never trusted from the client
- [ ] Enum-like values validated at the boundary, not deep in the service
- [ ] Upload size and MIME type bounded

### Injection

- [ ] *(backend)* No query built by string concatenation — bound parameters only
- [ ] *(backend)* Native queries parameterised
- [ ] CSV or spreadsheet exports neutralise formula injection (`=`, `+`, `-`, `@`)
- [ ] File paths resolved under a configured root — no traversal from user input
- [ ] No user-controlled content interpreted as a path, template or command
- [ ] *(frontend)* No `innerHTML` / bypassed sanitisation on user content

### Data exposure

- [ ] *(backend)* ORM entities never serialised over HTTP — always a DTO (§6)
- [ ] Error responses carry no stack trace, SQL or internal path
- [ ] Logs carry no secret, token or personal data beyond what is needed
- [ ] No silent `catch` — at minimum logged with context (§3)

---

## Performance

### Data access *(backend)*

- [ ] No N+1: lazy associations resolved in loops, explicit joins where needed
- [ ] No unpaginated list endpoint on a collection that grows
- [ ] Filtering and sorting done in the database, not in memory
- [ ] Indexes present for the columns the lot starts filtering on

### Transactions *(backend)*

- [ ] Write service methods transactional; read paths marked read-only
- [ ] No transaction on a controller
- [ ] No remote call (HTTP, mail, storage) inside a transaction without a timeout

### Payloads and rendering

- [ ] Large documents streamed rather than fully buffered
- [ ] *(frontend)* No unbounded list rendered without virtualisation or pagination
- [ ] *(frontend)* No request fired per rendered row when one batched call exists
- [ ] *(frontend)* Bundle impact of a new dependency checked before adding it

---

## Architecture

### Layering

- [ ] *(backend)* `controller → service → repository`, no layer skipped
- [ ] *(backend)* No business logic in a controller, no persistence logic in a service
- [ ] *(backend)* Entity ↔ DTO conversion through the project's mapper
- [ ] *(frontend)* No HTTP call from a component — it goes through a service
- [ ] Constructor injection only — no field injection (§3)

### Domain model

- [ ] Business behaviour with no external dependency lives **on the entity**
      (§1 of `CONVENTIONS.md`), not in a new `XxxHelper` / `XxxUtils`
- [ ] No Lombok `@Data` on an entity with relations (§3)
- [ ] New code in the package the repo's `CLAUDE.md` prescribes

### Migrations *(backend, when `Migrations directory` is set)*

- [ ] Every touched migration file is in status `A` versus `origin/develop`
- [ ] No merged migration edited in place
- [ ] Expand/contract respected: no drop, rename or `NOT NULL` in the same version
      as the code that stops using the column; contract step marked `contract`
- [ ] The new changesets are executed by a real-database integration test

### API conventions *(backend)*

- [ ] Errors centralised, one envelope, Problem Details where possible (§6)
- [ ] Semantic status codes: 201 on create, 204 on delete, 409 on business conflict
- [ ] Soft delete via the `deleted` flag rather than physical deletion (§6)

### Tests

- [ ] Every new endpoint or route covered by an integration test, same commit
- [ ] Every new public service method covered by a unit test, same commit
- [ ] The lot's business rules covered (matrix in `lot-test`)
- [ ] Coverage gate green, threshold not lowered, no exclusion added to pass
- [ ] No `@Disabled` / `@Ignore` / `test.skip` introduced by the lot

### Harness and documentation

- [ ] `CLAUDE.md` and `AGENTS.md` byte-identical
- [ ] `## Gate parameters` still accurate after the lot's changes
- [ ] Documents census updated in the **same commit** as any added document (§12)
- [ ] `CONVENTIONS.md` identical to the harness master
- [ ] Commit messages in English, Conventional Commits, no U+2014 (§7, §10)
- [ ] No commented-out code left in the diff (§3)

### Lot scope

- [ ] Changes limited to the lot's scope in the `Lots file` — no scope creep
- [ ] No half-implemented feature belonging to a future lot
- [ ] Exactly one `docs/audits/lot-*.md` added by this PR (P5-#13)
- [ ] The `Lots file` modified only on status lines

---

## Lot-specific triggers

Pick the extra focus from what the lot touches, not from its number.

| The lot touches | Extra focus |
|---|---|
| Authentication, tokens, sessions | Expiry, refresh, logout, replay, error codes |
| Mail or notification sending | Credentials, content injection, async failure handling, timeouts |
| Money, totals, rates | Server-side recomputation, snapshotting, rounding |
| Export or import | Formula injection, size limits, MIME validation |
| File or document generation | Path traversal, temp file cleanup, memory |
| Roles and permissions | Horizontal escalation, ownership checks on every route |
| Migrations | Status `A`, expand/contract, real execution in a test |
| CI or Docker | Pinned actions, minimal `permissions`, no secret echoed, tested artefact = shipped artefact |
| Dependencies | Major bumps approved, lockfile committed, audit output reviewed |
