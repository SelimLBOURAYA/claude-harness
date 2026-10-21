# Lot Review — Lot 26 — feat/lot-26-project-memory

**Harness ref:** 2.0.1
**Model:** Claude Opus 5.5 (`claude-opus-5-5`)
**Target:** local diff origin/develop...HEAD
**Reviewed at:** b70d787
**Verdict:** Fixed

No pull request was open at review time.

## Findings
| # | Severity | Location | Finding | Outcome |
|---|----------|----------|---------|---------|
| 1 | High | `plugins/claude-harness/skills/lot-test/SKILL.md:45` | `$START` does not survive from one `Bash` call to the next: section 5 diffs from an empty ref, or from a re-read `HEAD` that makes the boundary check pass on an empty range | fixed in f409876: the SHA is written down and reused, never re-read |
| 2 | High | `plugins/claude-harness/skills/lot-review/SKILL.md:104` | The `lot-test` boundary command lists file names only, so a weakened assertion (deliverable 5) cannot be seen; `--grep='^test('` errors under `grep.patternType=extended` | fixed in f409876: `--stat -p --grep='^test[(]'`, test assertion updated |
| 3 | Medium | `plugins/claude-harness/skills/lot-review/SKILL.md:117` | Step 3 commits without staging, and gives no way to keep the memory correction in its own commit | fixed in f409876: explicit `git add` of the fix paths, `docs/memory.md` staged alone |
| 4 | Medium | `plugins/claude-harness/skills/lot-test/SKILL.md:59` | GATE-9 makes `lot-test` write `docs/audits/lot-N-friction.md`, which its "test files only" boundary, and `lot-review`'s, would flag | fixed in f409876, owner's decision: the friction file is the one non-test file `lot-test` may write, named in both boundary checks |
| 5 | Medium | `CONVENTIONS.md:96` | GATE-7 says every step is invoked explicitly, while the close runs on its own (B3): a literal agent waits for a `lot-start close N` that never comes | fixed in f409876: GATE-7 excepts the close |
| 6 | Medium | `plugins/claude-harness/skills/lot-test/SKILL.md:86` | A red test left in the tree keeps the `Validation command` red, which pushes toward `skip`/`@Disabled` to commit the other tests | fixed in f409876: the red test goes in a new file of its own, moved out of the repository for the run, then put back uncommitted |
| 7 | Medium | `plugins/claude-harness/rules/deepseek.json:28` | The LOT-7 card entry says "closes per MEM-1", and MEM-1 is off the card: a `deepseek` session cannot tell what the close is | fixed in f409876: LOT-7 names `lot-start` Step B3 (the spec's wording), card regenerated, 4486 of 4500 characters |
| 8 | Low | `plugins/claude-harness/skills/lot-start/SKILL.md:192` | B3 writes the template into `docs/` without creating it | fixed in f409876: `mkdir -p` |
| 9 | Low | `docs/memory.md:28` | A Decisions note says skills read harness files from `origin/main`; `bootstrap-project` copies `templates/project/` from the working tree | fixed in b70d787: the note names what is read from `main` and the exception |
| 10 | Low | `README.md:199` | The README `lot-start` row misses the close step the other skill tables gained | fixed in f409876 |
| 11 | Low | `plugins/claude-harness/skills/lot-test/SKILL.md:64` | On a frontend, only `*.spec.ts` is writable: a test helper or HTTP mock handler in another file trips the boundary | rejected, owner's decision: the spec's pattern stays; a needed helper is a development session's work |

The `lot-test` boundary check of the lot itself passed: its one `test(26)`
commit (20db284) touches `tests/skills.test.sh` only, additions only.
`docs/memory.md` was read against the code: apart from finding 9, its notes
hold (card at 4486 of 4500, `CAP`/`TABLE_CAP`, `--no-track`, the 15000-byte
cap); 3747 of 6000 characters, header verbatim.

## Candidate lots
none
