# Lot Review — Lot 34 — feat/lot-34-autopilot-watch

**Harness ref:** 2.10.0
**Model:** claude-opus-5-5
**Target:** local diff origin/develop...HEAD
**Reviewed at:** b3413b1
**Verdict:** Fixed

No pull request is open yet. Run under the autopilot (`HARNESS_AUTOPILOT=1`), `claude` profile.

## Findings
| # | Severity | Location | Finding | Outcome |
|---|----------|----------|---------|---------|
| 1 | Major | `plugins/claude-harness/autopilot/watch.py:18` | `newest()` took the newest log of any age: started before the first step writes its log, the watch replayed a previous run's log as live | fixed in cd5c6f9 (`since` argument, passed by `start_watch`) |
| 2 | Major | `plugins/claude-harness/autopilot/watch.py:95` | The backlog loop consumed a half-written last line, so that event was never shown | fixed in cd5c6f9 (`complete_lines()`) |
| 3 | Minor | `plugins/claude-harness/autopilot/watch.py:105` | Seeking back by the re-encoded length of a decoded line is wrong once `errors="replace"` substituted a byte | fixed in cd5c6f9 (seek to the recorded `tell()`) |
| 4 | Major | `plugins/claude-harness/autopilot/watch.py:72` | A log line that is valid JSON but not an object (stderr shares the log) crashed the watch | fixed in cd5c6f9 (`parse()` keeps objects only) |
| 5 | Minor | `plugins/claude-harness/autopilot/watch.py:55` | A `message` or `content` key set to `null`, or a non-string `result`, raised `TypeError` | fixed in cd5c6f9 |
| 6 | Minor | `plugins/claude-harness/autopilot/watch.py:20` | A log removed between `glob` and `getmtime` raised `FileNotFoundError` | fixed in cd5c6f9 |
| 7 | Minor | `plugins/claude-harness/autopilot/watch.py:47` | Redundant `%-11s` over the padded step column and an unused `detail()` parameter | fixed in cd5c6f9 |
| 8 | Minor | `plugins/claude-harness/autopilot/watch.py:34` | The current model is kept in the module-level `MODEL` dict | rejected: minor (autopilot); each step log opens with its `init` event, and removing it reshapes the `lines()` interface the tests use |
| 9 | Minor | `docs/memory.md:26,98` | The watch note omitted the `since` filter; the open question on the untested terminal launch is stale since `test(34)` covers it through `script` | fixed in b3413b1 |

The `lot-test` commit (2a40cad) touches `tests/autopilot.test.sh` only, with insertions only: no assertion weakened.

## Candidate lots
none
