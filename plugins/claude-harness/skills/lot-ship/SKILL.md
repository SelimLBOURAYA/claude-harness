---
name: lot-ship
description: >-
  Ships a lot: uniform Conventional Commits, the lot's row marked done, push,
  PR to develop via gh, and the merge once every check is green, then stop. Use
  at the end of a lot after lot-audit, or when the user mentions branch, commit,
  push, PR or delivery.
metadata:
  version: "3.0"
---

# Lot Ship — Commits, push, PR, merge

One lot, one PR, merged into `develop` once its CI is green, then **stop**.

```
lot-test  →  lot-review  →  lot-audit  →  [lot-ship]
```

The branch exists: `feat/lot-N-slug` from `develop`, as named in the
`Lots file`. `Validation command` and `Lots file` come from the
`## Gate parameters` of `CLAUDE.md`.

## 1. Commit convention

Conventional Commits, in English, imperative mood (GIT-2):

```
<type>(<scope>): <short description>
```

- `<type>`: `feat`, `fix`, `refactor`, `test`, `chore`, `docs`
- `<scope>`: the lot number alone — `(1)`, `(11b)`, `(12)`; omitted for a
  cross-cutting chore: `chore: ignore IntelliJ project files`
- `<description>`: imperative, lowercase, no trailing period, at most 72 chars,
  no em dash (U+2014)

```
feat(12): split quote total into net, vat and gross
fix(12): map the business conflict to 409
test(12): cover status guards and vat computation
chore: bump the github actions to their pinned shas
docs: sync lots file status
```

| Forbidden | Correct |
|---|---|
| `Ajout du PDF de devis` | `feat(7): render the quote pdf` |
| `feat: add stuff` | `feat(13): paginate the quote list` |
| `feat(lot-12): …` | `feat(12): …` |
| Several logical changes mixed | One commit per logical change |

## 2. Pre-commit gate

Check the staged diff against GIT-3, and:

- [ ] `<Validation command>` green
- [ ] No secret, password, token or absolute user path staged
- [ ] One logical change in this commit
- [ ] `docs/audits/lot-N-review.md` and `docs/audits/lot-N.md` committed, the
      audit free of unresolved Critical rows
- [ ] *(frontend)* `docs/audits/lot-0-integration.md` committed
- [ ] Every `docs/audits/` report listed verbatim in the `## Project documents`
      census of `CLAUDE.md` (a directory row does not cover its files)

```bash
<Validation command>
for f in $(git ls-files 'docs/audits/*.md'); do
  grep -qF "$f" CLAUDE.md || echo "missing from the census: $f"
done
git diff --cached --stat
git commit -m "feat(N): <description>"
```

## 3. Mark the lot done, before the push

Set the lot's status to ✅ in the `Lots file`: its row of the status table, and
its section heading when the heading carries a status. `develop` then carries ✅
exactly when the PR is merged.

```bash
git add <Lots file>
git commit -m "docs(N): mark the lot done in the lots file"
```

## 4. Push and open the PR

```bash
git push -u origin feat/lot-N-<slug>
```

The git guard denies anything targeting `main` and lets every other push and
the PR to `develop` pass without a prompt.

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
- [ ] lot-audit executed, findings fixed, no unresolved Critical
- [ ] No secret committed
EOF
)"
```

`--base develop` is mandatory; the guard denies `gh pr create` without it (GIT-1).
The body has `## Summary` then `## Test plan`, and a third section only when it
adds real information (`## DB migration` for a changeset) (GIT-6).

## 5. Watch the CI, merge, stop

```bash
gh pr checks --watch
```

- A check red → report which one, fix it on the branch, push again, watch again.
- Every check green → merge, pinned to the commit that was checked:

  ```bash
  gh pr merge <number> --merge --match-head-commit "$(git rev-parse HEAD)"
  ```

  A merge commit, which `lot-start` maps to the lot. The git guard reads the PR
  and denies the merge unless its base is `develop`, its head a `feat/lot-*`
  branch and every check green (GIT-5, GIT-6). Never `--delete-branch`, never
  `--admin`.

- Once merged, remove the lot lock, so that the next lot, even on the same
  branch, needs its own `lot-start confirm N` (LOT-1):

  ```bash
  rm -f "$(git rev-parse --show-toplevel)/.claude/current-lot"
  ```

Then report the PR URL and the merge, and **stop** (LOT-6). The `develop` →
`main` promotion is the user's.

## Rules

- Never commit on `main` or `develop`; never push to `main`.
- `<Validation command>` green before every commit; never `--no-verify`.
- No merge while a check is not green.
- History reads through `rtk proxy git log`.
