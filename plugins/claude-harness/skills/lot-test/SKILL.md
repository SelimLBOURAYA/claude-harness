---
name: lot-test
description: >-
  Guarantees that every lot is covered by written, passing tests before the PR
  is opened, with the coverage gate green at the repository's own threshold.
  Use at the end of a lot, before lot-review, or when the user mentions tests,
  coverage, JUnit, Vitest, Karma, JaCoCo or verification.
metadata:
  version: "2.0"
---

# Lot Test — Coverage & quality

Every PR is **preceded** by written, passing tests. A lot without tests is an
incomplete lot, not a lot to be tested later.

Mandatory gate order, each step invoked explicitly:

```
lot-test  →  lot-review  →  lot-audit  →  lot-ship
```

## 0. Read the gate parameters first

This skill hard-codes **no** command and **no** threshold. Read the
`## Gate parameters` table in the repository's `CLAUDE.md` and use those values
throughout:

| Parameter | Used for |
|---|---|
| `Stack` | Selects the backend or frontend branch of section 2 |
| `Validation command` | The single command run in section 3 |
| `Coverage tool` | Where the gate is wired and where the report lands |
| `Coverage threshold` | The current ratchet value |
| `Coverage exclusions` | The list reviewed in section 3.2 |
| `Lots file` | Where the lot's scope and acceptance criteria are written |

If the section is missing or a parameter is absent, **stop** and ask the user to
fill it. Guessing a validation command is how a lot ships untested.

---

## 1. Write the tests before opening the PR

1. Read the lot's section in the `Lots file` — the acceptance criteria are the
   test list in disguise.
2. Diff the branch against `develop` and list what was added or modified:
   - backend: services, controllers, entities, mappers, migrations;
   - frontend: components, services, guards, interceptors, stores.
3. Write the corresponding tests (section 2).
4. Run the `Validation command` until green (section 3).
5. Commit the tests **in the same lot, on the same branch**, alongside the code
   they cover — never in a follow-up commit and never in a later lot.

---

## 2. What to test

### General rules, both stacks

- Test **behaviour**, not internal implementation.
- Every business rule stated in `CLAUDE.md` or in the lot's section gets at least
  one dedicated test.
- Every new or modified **public service method** gets a unit test, in the same
  commit (§3 of `CONVENTIONS.md`).
- Every new **endpoint** (backend) or **route/page** (frontend) gets an
  integration test, in the same commit.
- A test that passes only because its collaborator is mocked proves the mock, not
  the code. Keep at least one test per persistence or HTTP path that exercises
  the real boundary.

### Business-rule test matrix

Fill this matrix for the lot before writing anything. One row per rule, no row
left without a test.

| Rule (from the lot section or `CLAUDE.md`) | Kind | Expected test |
|---|---|---|
| … | unit / integration | … |

Rows that recur across the portfolio and are easy to forget:

| Rule family | Expected test |
|---|---|
| Server-computed totals or references | Client-supplied value is ignored; the server value is the one asserted |
| State guards (finalised, cancelled, archived) | Mutation attempt → domain exception → the documented HTTP status |
| Snapshotted values (rates, prices) | Changing the source after the snapshot does not alter existing rows |
| Secrets and passwords | Never serialised, never logged — assert on the response body and on the log output |
| Authentication on protected routes | Unauthenticated → 401; valid credentials → 200 |
| Export injection (CSV, spreadsheet) | A cell starting with `=`, `+`, `-` or `@` is neutralised |
| Authorisation / ownership | A user cannot read or mutate another user's row |

### Backend specifics (`Stack = backend`)

- Unit tests: the business logic in isolation, collaborators mocked.
- **Integration tests use a real database**: Testcontainers PostgreSQL with the
  migration tool **active** (§2.5 of `CONVENTIONS.md`, P5-#1 and P5-#7). A
  `@SpringBootTest` on H2 with `ddl-auto: create-drop` and Liquibase or Flyway
  disabled is **not** an integration test: it proves the Hibernate DDL, not the
  migrations that will run in production.
- Every changeset added by the lot must be executed by at least one test run.

### Frontend specifics (`Stack = frontend`)

- Components: render through the testing harness, assert rendered output and user
  interactions — never private state.
- Services: assert request URL, method and body against the HTTP testing
  controller, and the state exposed to consumers.
- Guards and interceptors: pure tests with the collaborators mocked.
- A green frontend suite proves nothing about the real backend. The front ↔
  backend contract is the `integration-check` skill's job, and its deliverable
  `docs/audits/lot-0-integration.md` is required before any frontend PR.

---

## 3. Measure and enforce

### 3.1 Run the gate

```bash
<Validation command>
```

One command. It runs the tests **and** enforces the coverage threshold. A red
result means failing tests or coverage below the gate — both block the commit.

Then open the report produced by `Coverage tool` and **look at it**. A global
percentage above the threshold can hide a business class at 0 %; the threshold is
a floor, not the objective.

### 3.2 Review the exclusions

Read `Coverage exclusions` and challenge every entry (finding #7):

- An exclusion is legitimate for generated code and for pure configuration.
- An exclusion covering a **business package** makes the measurement a fiction.
  Report it, propose its removal, and let the threshold fall to the real measured
  level rather than keeping a flattering number.
- A change to the exclusion list is a change to the gate: it belongs in the audit
  report and in the PR description.

### 3.3 The ratchet

The threshold only ever goes **up**. Never lower it, never disable it, never add
an exclusion to make a red build green. If the lot cannot reach the current
threshold, that is a finding to report, not a setting to edit.

---

## 4. Pre-review checklist

- [ ] `Gate parameters` read; no command or threshold improvised
- [ ] Tests written for every class or component modified in the lot
- [ ] Business-rule matrix filled, every row covered
- [ ] Backend: migrations executed by a real-database integration test
- [ ] `<Validation command>` green
- [ ] Coverage report opened — no business class at 0 %
- [ ] `Coverage exclusions` reviewed, any business-package exclusion reported
- [ ] Tests committed on the lot branch, with the code they cover
- [ ] `## lot-test` friction section committed (section 5)

---

## 5. Record the friction

Append the `## lot-test` section to `docs/audits/lot-N-friction.md`, in the format
of `CONVENTIONS.md` §13 (« Friction »): what, in running **this skill**, failed,
came back empty, was ambiguous or cost for nothing — a `Coverage tool` report
that was not where the gate parameters say, a matrix row the skill does not fit,
a validation command that misreports. Each entry opens with its key,
`` `lot-test / <step>` `` (`3.1`, `3.2`…). Nothing to record → `None.`

Write it now: §14 ends this session before `lot-review`, and what is not in the
file is lost. `<Validation command>` green, then commit it on its own:

```
docs(N): record the lot-test friction
```

Next step: **`lot-review`**. It requires the `claude` profile — if the session is
not running it, stop here and tell the user to open a new session.

---

## Absolute rules

- No commit without a green `<Validation command>`.
- Never `@Disabled`, `@Ignore`, `test.skip`, or a deleted assertion to make a
  build pass — a red test is fixed, not masked (§3 of `CONVENTIONS.md`).
- The coverage threshold is a ratchet: never lowered, never disabled.
- Tests belong to the lot that introduces the code, never to a later lot.
