---
name: lot-test
description: >-
  Checks and completes the tests of a lot in a new session, after the
  development's close: black-box tests drawn from the lot's specification,
  test files only, coverage gate green at the repository's own threshold. Use
  after lot-start closed the development, before lot-review, or when the user
  mentions tests, coverage, JUnit, Vitest, Karma, JaCoCo or verification.
metadata:
  version: "4.0"
---

# Lot Test — Check and complete the coverage

Runs in a **new session**, under any profile, once `lot-start` has closed the
development (its Step B3). The lot's tests were written with its code (GATE-3):
this skill **checks and completes** them, it does not rewrite them. A fresh
look finds the forgotten cases; it does not know the decisions behind the code,
so it never touches the code.

```
development  →  close  →  [lot-test]  →  lot-review  →  lot-audit  →  lot-ship
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

### 0.1 Starting point and what you may write

```bash
git status --porcelain        # must print nothing
START=$(git rev-parse HEAD)   # the starting point of this run
```

Write down the SHA `START` holds: a shell variable does not survive from one
`Bash` call to the next, so section 5 uses that SHA, never a new
`git rev-parse HEAD`, which would make the check pass on an empty range.

A dirty tree → **stop** and report it: the development is not closed, or a
previous run left a test revealing a bug (section 1, step 6), whose fix belongs
to a development session.

Then read `docs/memory.md` (MEM-1), if it exists, and the lot's section in the
`Lots file`.

You write **test files only**, chosen by `Stack`:

| `Stack` | Test files |
|---|---|
| `backend` | under `src/test/` |
| `frontend` | `*.spec.ts` |
| `harness` | under `tests/` |
| `other` | any file, each one listed in your report |

The one other file you may write is `docs/audits/lot-N-friction.md`, your
friction entry (GATE-9). Never modify production code, an existing assertion, or the coverage
configuration (threshold, exclusions).

## 1. Complete the tests

1. The lot's acceptance criteria are the test list.
2. List what the lot added or modified, against the fetched `origin/develop`,
   never the local `develop`:

   ```bash
   git fetch -q origin develop
   git diff --name-status origin/develop...HEAD
   ```

   - backend: services, controllers, entities, mappers, migrations;
   - frontend: components, services, guards, interceptors, stores, routes.
3. Fill the business-rule matrix (section 2) and find each row's existing test.
4. For each criterion or branch left uncovered, write a **black-box** test:
   drawn from the lot's specification, not from the code, so that it asserts
   what the code should do rather than what it does.
5. `Validation command` green (section 3) → commit the added tests:
   `test(N): complete the lot coverage`. Nothing added → no commit.
6. A test you added is red → it has revealed a bug. **Do not fix it**: no
   change to the code, no weakened assertion (GATE-2). Put it in a new test file
   of its own, the bug at its top as a comment (expected, actual). Commit the
   other added tests only if the `Validation command` is green with that file
   moved out of the repository for the run, never skipped or disabled; then put
   it back, uncommitted in the working tree. Go to section 4, then stop and
   report the bug: a development session fixes it, and `lot-test` runs again in
   a new session.

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
- [ ] Clean tree at the start, `START` noted, `docs/memory.md` read
- [ ] Tests for every class or component the lot modified
- [ ] Business-rule matrix filled, every row covered
- [ ] Backend: migrations executed by a real-database integration test
- [ ] `<Validation command>` green
- [ ] Coverage report opened — no business class at 0 %
- [ ] `Coverage exclusions` reviewed, any business-package exclusion reported
- [ ] Added tests black-box, committed as `test(N): complete the lot coverage`
- [ ] A test revealing a bug left uncommitted, the code untouched
- [ ] Boundary check passed (section 5)

## 5. Boundary check, before the stop

```bash
git diff --name-only "$START" HEAD
```

Every path listed is a test file of the table in section 0.1, or the friction
file. Another path →
**stop** and report it; never rewrite the history to hide it. The check sees
only this run's commits: a fix committed by a development session before the
run is not in it. `lot-review` checks the `test(N)` commits again.

## 6. Stop

Whatever the profile, stop after this skill (LOT-7): tell the user to end the
session, run `/home/selim/.local/bin/claude-profile claude` if the profile is
`deepseek`, and open a new session for `lot-review`, then `lot-audit` and
`lot-ship`.
