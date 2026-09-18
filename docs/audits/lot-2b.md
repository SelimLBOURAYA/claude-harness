# Lot Audit — Lot 2b — feat/lot-0-6-harness-foundation

**Harness ref:** `feat/lot-0-6-harness-foundation` (lot 2 at `51883be`)
**Scope:** 1 skill + 12 assertions added to `tests/skills.test.sh`
**Verdict:** ⚠️ Fix warnings — the profile guard is documented and asserted, but
its behavioural criteria need a live session to close

Origin: user request of 2026-09-18, outside the audit findings. Direct
consequence of the lot 5 test — a mid-session profile switch does **not** change
the running session's model.

## Summary

| Dimension | Critical | Warning | Info |
|---|---|---|---|
| Security | 0 | 1 | 1 |
| Harness | 0 | 2 | 1 |

## What the lot delivers

| Deliverable | State |
|---|---|
| `lot-review` skill, invoking `Skill(code-review) --comment --fix` on the lot's PR | Delivered |
| Profile guard refusing any session that is not running the `claude` profile | Delivered, on a **runtime** signal |
| Gate updated to `lot-test → lot-review → lot-audit → lot-ship` | Delivered in `lot-test`, `lot-audit`, `lot-ship`, `harness-sync`, `CLAUDE.md` and `README.md` |
| `lot-audit` refuses to start without the review deliverable | Delivered as Step 0, with a staleness check on the reviewed SHA |
| Traceability deliverable `docs/audits/lot-N-review.md` | Template delivered, added to the census |
| `harness-sync` checks the gate order and the deliverable ordering | Delivered as invariants 8 and 9 |

## The profile guard, and why it is built this way

The plan asked the skill to "check the announced model of the active session".
A model asked to self-report its own identity is the least reliable witness
available, so the guard leads with a signal that does not depend on
introspection:

```bash
printenv ANTHROPIC_BASE_URL     # empty under claude, api.deepseek.com under deepseek
```

The `deepseek` profile sets `ANTHROPIC_BASE_URL=https://api.deepseek.com/anthropic`
in its `env` block, which Claude Code injects into the session environment at
startup. The `claude` profile sets no `env` block at all. The env var therefore
reflects the profile the session **actually started under**, which is exactly the
thing the `settings.json` file cannot tell us mid-session.

The self-reported model is kept as a second signal; both must hold.

## Security

| Severity | Location | Finding | Action |
|---|---|---|---|
| Warning | out of repo | `~/.claude/settings.deepseek.json` carries `ANTHROPIC_AUTH_TOKEN` (a DeepSeek API key) **in clear**. Contrary to §5 and to the forbidden patterns of §3. The file is local and unversioned, so nothing leaks today, but the guard's design draws attention to it | Reported to the user. Out of scope here: it is a `~/.claude` file. Move it to a secret manager or an env var loaded at launch |
| Info | `lot-review` | The skill reads the env var, it does not print it. A base URL carrying a token in its query string would not be echoed | None |

## Harness

| Severity | Location | Finding | Action |
|---|---|---|---|
| Warning | `lot-review` Step 0 | The guard is **instruction, not enforcement**: nothing mechanically stops a model from reading Step 0 and continuing anyway. This is the same class of limit as the git guard, and the same mitigation applies — the CI is the agent-agnostic curtain | Accepted. A CI check on the review deliverable is already in `lot-deliverables.yml` (lot 3) |
| Warning | `lot-review` | `Skill(code-review)` with `--comment` needs an **open PR** to anchor inline comments. The lot gate opens the PR in `lot-ship`, *after* the review. The skill handles both cases explicitly (PR present → inline comments; no PR → findings recorded in the deliverable), but the first run of a lot will usually take the second path | Accepted; the deliverable stays complete either way |
| Info | `lot-review` | The deliverable records **Reviewed at**, the HEAD SHA at review time, so `lot-audit` can detect code landing after the review instead of trusting the file's existence | None |

## Validation criteria

- [ ] On a test PR with a deliberate defect, `lot-review` posts an inline comment
      and fixes the defect before `lot-audit` can run — **needs a live session
      with the plugin installed**; blocked on V1 and V2
- [ ] `lot-review` launched under the `deepseek` profile stops without touching
      the PR or the working tree — **needs a live deepseek session**. The
      condition it branches on is asserted statically instead
- [x] `lot-audit` refuses to start when `docs/audits/lot-N-review.md` is missing
      (Step 0, asserted)
- [x] Report `docs/audits/lot-2b.md`

The two open criteria are behavioural and need the plugin actually installed;
they join V1 to V7 on the post-merge verification list rather than blocking the
PR, because the code paths they exercise are asserted statically here.

## Recommended next steps

1. After V1, run the two behavioural criteria in one session: install the plugin,
   open a test PR with a deliberate defect, run `lot-review` under each profile.
2. Move `ANTHROPIC_AUTH_TOKEN` out of `settings.deepseek.json`.
