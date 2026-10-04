---
name: lot-test
description: >-
  Guarantees that every lot is covered by written, passing tests before the PR
  is opened, with the coverage gate green at the repository's own threshold.
  Use at the end of a lot, before lot-review, or when the user mentions tests,
  coverage, JUnit, Vitest, Karma, JaCoCo or verification.
metadata:
  version: "3.0"
---

# Lot Test — Coverage & quality

The last step of a lot's development. A lot without tests is incomplete.

```
lot-test  →  lot-review  →  lot-audit  →  lot-ship
```

## 0. Read the gate parameters first

Read the `## Gate parameters` table of the repository's `CLAUDE.md` and use its
values throughout; this skill hard-codes no command and no threshold.

| Parameter | Used for |
|---|---|
| `Stack` | Selects the backend or frontend part of section 2 |
| `Validation command` | The single command run in section 3 |
| `Coverage tool` | Where the gate is wired and where the report lands |
| `Coverage threshold` | The current ratchet value |
| `Coverage exclusions` | The list reviewed in section 3.2 |
| `Lots file` | The lot's scope and acceptance criteria |

A missing section or parameter → **stop** and ask the user to fill it.

## 1. Write the tests

1. Read the lot's section in the `Lots file`: its acceptance criteria are the
   test list.
2. List what the lot added or modified, against the fetched `origin/develop`,
   never the local `develop`:

   ```bash
   git fetch -q origin develop
   git diff --name-status origin/develop...HEAD
   ```

   - backend: services, controllers, entities, mappers, migrations;
   - frontend: components, services, guards, interceptors, stores, routes.
3. Write the corresponding tests (section 2).
4. Run the `Validation command` until green (section 3).
5. Commit the tests on the lot branch, with the code they cover (GATE-3).

## 2. What to test

### Both stacks

- Test behaviour, not internal implementation.
- Every business rule of `CLAUDE.md` or of the lot section gets a dedicated test.
- Every new or modified public service method gets a unit test, every new
  endpoint (backend) or route (frontend) an integration test (GATE-3).
- Keep at least one test per persistence or HTTP path that exercises the real
  boundary: a test that passes only through a mock proves the mock.

### Business-rule test matrix

Fill it before writing anything. One row per rule, none without a test.

| Rule (from the lot section or `CLAUDE.md`) | Kind | Expected test |
|---|---|---|
| … | unit / integration | … |

Rows that recur and are easy to forget:

| Rule family | Expected test |
|---|---|
| Server-computed totals or references | Client-supplied value is ignored; the server value is the one asserted |
| State guards (finalised, cancelled, archived) | Mutation attempt → domain exception → the documented HTTP status |
| Snapshotted values (rates, prices) | Changing the source after the snapshot does not alter existing rows |
| Secrets and passwords | Never serialised, never logged — asserted on the response body and the log output |
| Authentication on protected routes | Unauthenticated → 401; valid credentials → 200 |
| Export injection (CSV, spreadsheet) | A cell starting with `=`, `+`, `-` or `@` is neutralised |
| Authorisation / ownership | A user cannot read or mutate another user's row |
| Route (frontend) | Navigating to the path renders its component, through the real router |
| Route guard (frontend) | Denied → redirect to the documented route; allowed → the route renders |
| HTTP interceptor (frontend) | The header or error handling it adds is asserted on the request the HTTP testing controller sees |

### Backend (`Stack = backend`)

- Unit tests: the business logic in isolation, collaborators mocked.
- Integration tests on a real database, migrations active (GATE-4).
- Every changeset the lot adds is executed by at least one test run.

### Frontend (`Stack = frontend`)

- Components: render through the testing harness, assert rendered output and user
  interactions, never private state.
- Services: assert request URL, method and body against the HTTP testing
  controller, and the state exposed to consumers.
- Guards and interceptors: pure tests, collaborators mocked.
- Lazy routes: a `loadComponent` / `loadChildren` loader is covered only once the
  route is navigated; a routes spec navigates each lazy path
  (`app.routes.spec.ts`) rather than an exclusion.
- The front ↔ backend contract is checked by `integration-check` (GATE-5).

## 3. Measure and enforce

### 3.1 Run the gate

```bash
<Validation command>
```

It runs the tests and enforces the coverage threshold; red blocks the commit
(GATE-2). Then open the report of `Coverage tool`: a global percentage above the
threshold can hide a business class at 0 %.

### 3.2 Review the exclusions

Challenge every entry of `Coverage exclusions`:

- Legitimate for generated code and pure configuration.
- An exclusion covering a business package is a finding: report it and propose
  its removal, letting the threshold fall to the real measured level.
- A change to the exclusion list is a change to the gate: it goes in the audit
  report and in the PR description.

### 3.3 The ratchet

The threshold only goes up: never lowered, never disabled, never an exclusion
added to turn a build green. A lot that cannot reach it is a finding to report.

## 4. Checklist

- [ ] `Gate parameters` read; no command or threshold improvised
- [ ] Tests for every class or component the lot modified
- [ ] Business-rule matrix filled, every row covered
- [ ] Backend: migrations executed by a real-database integration test
- [ ] `<Validation command>` green
- [ ] Coverage report opened — no business class at 0 %
- [ ] `Coverage exclusions` reviewed, any business-package exclusion reported
- [ ] Tests committed on the lot branch, with the code they cover

## 5. Stop: the development ends here

Whatever the profile, stop after this skill (LOT-7): tell the user the
development is done, and to end the session, run
`/home/selim/.local/bin/claude-profile claude` if the profile is `deepseek`, and
open a new session for `lot-review`, then `lot-audit` and `lot-ship`.
