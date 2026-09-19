---
name: integration-check
description: >-
  Runs the manual smoke test of a frontend against its real backend and writes
  docs/audits/lot-0-integration.md, which every frontend PR requires. Use before
  the first frontend PR, when the API contract changed, or when the user
  mentions integration, the real backend, end-to-end or the contract.
metadata:
  version: "2.0"
---

# Integration Check — Front against the real backend

A green frontend unit suite proves the components talk correctly to **mocks**.
It says nothing about whether the application works against the real API. On
kreadevis-frontend the front had never once been run against the backend
(findings #3 and P5-#4), so field name, status code and payload shape mismatches
had nowhere to surface before production.

This skill closes that gap with a **manual** smoke test and a written
deliverable. The automated CI contract job is planned as lot 16 of the harness
plan and will eventually replace it.

## When it is required

`docs/audits/lot-0-integration.md` must exist before **any** frontend PR.
`lot-deliverables.yml` fails the build of a repo whose `Stack` is `frontend`
without it.

Re-run this skill, and update the deliverable, whenever:

- a backend endpoint used by the front is added, removed or changes shape;
- authentication or the token lifecycle changes on either side;
- the front's API base URL or proxy configuration changes;
- more than one backend lot merged since the last run.

## Gate parameters used

| Parameter | Used for |
|---|---|
| `Frontend backend pair` | Which repository to start as the backend |
| `Health path` | The backend readiness probe to poll |
| `Dist forbidden pattern` | The string that must not survive into a production build |

## Workflow

```
Task Progress:
- [ ] Step 1 — Start the real backend
- [ ] Step 2 — Point the front at it
- [ ] Step 3 — Run the scenario
- [ ] Step 4 — Compare the contracts
- [ ] Step 5 — Write the deliverable
```

### Step 1 — Start the real backend

From the `Frontend backend pair` repository, on its current `develop`:

```bash
docker compose up -d          # database and any dependency
<its Validation command>      # confirm the backend itself is green first
<its run command>             # the app, as documented in its README
curl -f http://localhost:<port><Health path>
```

Record the backend's **commit SHA**: the deliverable is only meaningful against a
known backend version.

### Step 2 — Point the front at it

Use the project's documented development configuration. Do **not** invent a new
one and do not commit a temporary URL.

Check while you are here that the production configuration does **not** carry the
development URL: a production bundle containing `Dist forbidden pattern` is
findings P5-#15, and `frontend-dist.yml` fails the CI on it.

### Step 3 — Run the scenario

Minimum scenario, adapted to the project's domain:

1. **Authenticate** with a real account against the real backend.
2. **List** the main resource — confirm the rendered fields match the payload.
3. **Create** one resource through the UI — confirm it persists after a reload.
4. **Update** it — confirm the server value wins over any client-side guess.
5. **Delete** or archive it — confirm the documented status code path.
6. **Trigger one error on purpose** — expired or absent token, validation failure
   — and confirm the front handles it rather than showing a blank screen.

Keep the browser console **and** the backend logs open. A silently swallowed 500
is the exact class of defect this skill exists to catch.

### Step 4 — Compare the contracts

For every call in the scenario, note the real request and response against what
the front expects:

| Endpoint | Method | Front expects | Backend returns | Verdict |
|---|---|---|---|---|

Look specifically for:

- field names that differ (`totalPrice` vs `totalPriceHt`);
- nullability the front does not handle;
- status codes the front does not branch on (409, 422, 401 refresh);
- date and number formats, time zones, decimal separators;
- pagination envelope shape;
- CORS errors — they show up here, never in unit tests.

### Step 5 — Write the deliverable

Write **`docs/audits/lot-0-integration.md`** in the frontend repository:

```markdown
# Integration check — <frontend> against <backend>

**Date:** YYYY-MM-DD
**Frontend:** <branch> @ <short SHA>
**Backend:** <repo> @ <short SHA>, started with <command>
**Verdict:** Pass / Pass with findings / Fail

## Scenario
| # | Step | Result |
|---|------|--------|
| 1 | Authenticate | … |
| 2 | List | … |
| 3 | Create | … |
| 4 | Update | … |
| 5 | Delete | … |
| 6 | Error path | … |

## Contract comparison
| Endpoint | Method | Front expects | Backend returns | Verdict |
|---|---|---|---|---|

## Findings
| Severity | Side | Finding | Action |
|---|---|---|---|

## Production build check
- `Dist forbidden pattern` absent from the production bundle: yes / no

## Next run required when
- …
```

A **Fail** verdict blocks the frontend PR just as a Critical audit finding does.
Findings belonging to the backend become a lot in the backend's own lots file —
propose it, and wait for approval before editing that file.

## Rules

- The backend is the **real** one, from its repository. A mock server, a stub or
  a recorded fixture makes the deliverable worthless.
- Never commit a temporary URL, credential or proxy tweak used during the run.
- Never mark the deliverable Pass from a partially run scenario — record what was
  not run and why.
- The deliverable is dated and carries both SHAs; an undated one cannot be
  trusted and `harness-sync` reports it.
