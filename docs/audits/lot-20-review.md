# Lot Review — Lot 20 — feat/lot-20-plugin-currency

**Harness ref:** 2dda298
**Model:** claude-opus-5
**Target:** local diff develop...HEAD
**Reviewed at:** 2dda298
**Fix commit:** 4346ebd, 6f586f2
**Verdict:** Fixed

## Findings
| # | Severity | Location | Finding | Outcome |
|---|----------|----------|---------|---------|
| 1 | High | `plugins/claude-harness/hooks/plugin-currency.py:101` | `installed_entry` returned the first record whose `installPath` matched the running copy. Several scopes share one cache directory, and the real `installed_plugins.json` lists two older project-scope records (`d67c004`) before the user-scope one (`9393cf4`): the check compared the wrong commit with `main`, warning falsely or staying silent on a stale copy. | fixed in 4346ebd — newest matching record by `lastUpdated`, else `installedAt`; test with the newest record not listed first |
| 2 | Medium | `plugins/claude-harness/hooks/plugin-currency.py:105` | With no `installPath` match, the fallback took the newest record of any version, so a stale `0.1.0` copy could be judged by an up-to-date `1.0.0` record and stay silent. | fixed in 4346ebd — fallback restricted to records of the directory's version, silent otherwise; test with a record of another version |
| 3 | Medium | `plugins/claude-harness/hooks/plugin-currency.py:135` | `git ls-remote origin main` matches every ref ending in `main`, and the first line ending in `/main` was taken: `refs/heads/release/main` or a `main` tag could stand for `main`. The call also ran over SSH with stdin open and no batch mode, so a credential or passphrase prompt could hang the session start until the timeout. | fixed in 4346ebd — exact `refs/heads/main`, then exact tag; `GIT_TERMINAL_PROMPT=0`, `ssh -o BatchMode=yes` unless `GIT_SSH_COMMAND` is set, stdin closed; test with `refs/heads/release/main` |
| 4 | Low | `.github/workflows/harness-invariants.yml:~301` | The version-bump check only tested inequality: a version moved backwards (`1.0.2` → `1.0.1`) passed, although that number's cache directory may already exist with older content. | fixed in 4346ebd — `sort -V` comparison fails a decrease; test in `tests/workflows.test.sh` |
| 5 | Low | `plugins/claude-harness/hooks/lot-lock-guard.py:153` | The "other lot" denial called the lock "the lock of a previous lot", but checking out an older lot branch makes the locked lot a later one; the "same lot, other branch" denial asserted the confirmed branch "no longer exists", while it may exist and simply not be checked out. Message only, behaviour correct. | fixed in 6f586f2 — "another lot, normally the previous one" and "the confirmation was given for another branch (renamed, recreated or switched since)"; assertions updated |

Findings 1 to 4 were raised and fixed by `code-review --fix` (high effort) on
`develop...HEAD`; finding 5 was raised by the same run and left unapplied, then
fixed during this review's own pass over the diff. Every fix was read before
commit, and `./tests/run.sh` was green (12/12) before each commit.

## Inline comments posted
- No PR open at review time (`lot-ship` not yet run): findings recorded here only.

## Candidate lots
none
