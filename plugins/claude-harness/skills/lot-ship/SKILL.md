---
name: lot-ship
description: >-
  Ships a lot: uniform Conventional Commits, push, and PR to develop via gh,
  then stop until the user merges. Use at the end of a lot after lot-audit, or
  when the user mentions branch, commit, push, PR or delivery.
metadata:
  version: "2.0"
---

# Lot Ship — Commits, push, PR

Ships a lot: uniform commits, push, PR via `gh`, then **stop**. One lot, one PR.

Gate position:

```
lot-test  →  lot-review  →  lot-audit  →  [lot-ship]
```

The branch already exists — `feat/lot-N-slug` branched from `develop`, as named
in the `Lots file` (`chore/<slug>` for a cross-cutting chore). Never commit on
`main` or `develop`.

## 0. Read the gate parameters

`Validation command` and `Lots file` come from the `## Gate parameters` table in
`CLAUDE.md`. This skill hard-codes neither.

---

## 1. Commit convention

**Conventional Commits**, in **English**, imperative mood.

```
<type>(<scope>): <short description>
```

- `<type>`: `feat`, `fix`, `refactor`, `chore`, `docs`, `test`, `style`
- `<scope>`: the lot number alone — `(1)`, `(11b)`, `(12)`. Omitted for a
  cross-cutting chore: `chore: ignore IntelliJ project files`
- `<description>`: imperative, lowercase, no trailing period, at most 72 chars
- No em dash (U+2014) anywhere in the message; use an en dash (§10.3)

### Valid examples

```
feat(12): split quote total into net, vat and gross
fix(12): map the business conflict to 409
test(12): cover status guards and vat computation
chore(deps): bump the github actions to their pinned shas
docs: sync the lots file status
```

### Anti-examples

| Forbidden | Correct |
|---|---|
| `Ajout du PDF de devis` | `feat(7): render the quote pdf` |
| `feat: add stuff` | `feat(13): paginate the quote list` |
| `feat(lot-12): …` | `feat(12): …` (scope = lot number only) |
| A French message | An English message |
| A commit with a red gate | `<Validation command>` green first |
| Several logical changes mixed | One commit per logical change |

---

## 2. Pre-commit gate

Re-read §10 of `CONVENTIONS.md` and verify against the **staged diff**:

- [ ] `<Validation command>` green
- [ ] No secret, password, token or absolute user path in the staged files
- [ ] Message in English, Conventional Commits, scope = lot number, no U+2014
- [ ] One logical change in this commit
- [ ] `cmp CLAUDE.md AGENTS.md` silent if either is staged
- [ ] `CONVENTIONS.md` identical to the harness master if staged
- [ ] `docs/audits/lot-N-review.md` exists (produced by `lot-review`)
- [ ] `docs/audits/lot-N.md` exists and carries no unresolved Critical row
- [ ] `docs/audits/lot-N-friction.md` carries its five sections, `## lot-ship`
      included (section 2b)
- [ ] *(frontend)* `docs/audits/lot-0-integration.md` exists
- [ ] Every report just written is listed in the `## Project documents` census of
      `CLAUDE.md` — §12 says "in the same commit", and `harness-invariants.yml`
      fails on any `docs/audits/**.md` it cannot find there. A directory row
      (`docs/audits/`) does **not** cover the files inside it

```bash
<Validation command>
# Every audit report must appear verbatim in the census, or CI fails.
for f in $(find docs/audits -name '*.md' | sort); do
  grep -qF "$f" CLAUDE.md || echo "missing from the census: $f"
done
git diff --cached --stat
git commit -m "feat(N): <description>"
```

### 2b. Record the friction, before the push

Append the `## lot-ship` section to `docs/audits/lot-N-friction.md`, in the format
of `CONVENTIONS.md` §13 (« Friction »): what, in running **this skill** so far,
failed, came back empty, was ambiguous or cost for nothing — a pre-commit check
that did not fit the repository, a guard that asked for nothing. Each entry opens
with its key, `` `lot-ship / <step>` ``. Nothing to record → `None.` Then check
that the four other sections are there: a missing one means its skill did not
record, and `lot-deliverables.yml` fails the PR on it.

```bash
for s in lot-start lot-test lot-review lot-audit lot-ship; do
  grep -qx "## $s" docs/audits/lot-N-friction.md || echo "missing friction section: $s"
done
git add docs/audits/lot-N-friction.md
git commit -m "docs(N): record the lot-ship friction"
```

What goes wrong **after** the push (PR creation, a red check) cannot be
committed without another push: record it in a `## Friction` section of the PR
body (`gh pr edit --body`), with the same keys.

---

## 3. Push and open the PR

```bash
git push -u origin feat/lot-N-<slug>
```

The git guard asks for confirmation on every push and denies anything targeting
`main`. That is expected — confirm, do not work around it.

```bash
gh pr create \
  --base develop \
  --head feat/lot-N-<slug> \
  --title "feat(N): <short lot title>" \
  --body "$(cat <<'EOF'
## Summary
- <what changed, one bullet per logical change>

## Test plan
- [ ] `<Validation command>` green
- [ ] lot-review executed, fixes applied
- [ ] lot-audit executed, no unresolved Critical
- [ ] No secret committed
EOF
)"
```

`--base develop` is mandatory. A PR to `main` is forbidden: the promotion
`develop → main` belongs to the user (§7). The guard denies `gh pr create`
without it, and denies it outright when the lot's audit report is missing.

Exactly **two** sections in the body — `## Summary` then `## Test plan` — unless
a third adds real information (for instance `## DB migration` when the lot ships
a changeset, or `## Friction` for what failed after the push, section 2b).

---

## 4. Watch the CI, then stop

```bash
gh pr checks --watch
```

**Do not declare the lot ready while any check is red** (P5-#11). There is no
branch protection on these repositories: a red PR is still mergeable, so this
skill and the user's review are the only guard. On elya, three PRs were merged
across six consecutive red runs — that is what this step exists to prevent.

- Check red → report which one, fix it on the branch, push again.
- Checks green → report the PR URL and **stop**.

**Stop after PR.** Do not start the next lot, do not chain, do not merge. Wait
for the user to merge, then a new lot starts from an updated `develop`.

---

## Absolute rules

- Never commit on `main` or `develop`; never push to `main`.
- `<Validation command>` green before every commit; never `--no-verify`.
- English message, Conventional Commits, scope = lot number, no em dash.
- No PR without `docs/audits/lot-N.md` free of unresolved Critical rows.
- The `## lot-ship` friction section is committed before the push, `None.` when
  there is nothing to record.
- Never `gh pr merge` — merging is the user's decision.
- All history reads through `rtk proxy git log` (P5-#14): the rtk filter hides
  merge commits, which makes the branch state look wrong.
