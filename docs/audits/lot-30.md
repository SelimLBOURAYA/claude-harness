# Lot Audit — Lot 30 — feat/lot-30-plugin-update-before-lot

**Harness ref:** 2.5.0
**Scope:** 11 modified files | **Fix commit:** none needed | **Verdict:** Ready for PR

Security discovery and false-positive phases run inline, without sub-agents: the
diff (120 lines added) fits in the session. The session ran on the Anthropic API
with Opus, in the same session as development and review, by the owner's choice.

## Summary
| Dimension    | Critical | Warning | Info |
|--------------|----------|---------|------|
| Security     | 0        | 0       | 2    |
| Performance  | 0        | 0       | 1    |
| Architecture | 0        | 0       | 1    |

## Security
| Severity | Location | Finding | Action |
|----------|----------|---------|--------|
| Info | `plugins/claude-harness/autopilot/autopilot.py:44` | The autopilot allowlist gains one exact command, no wildcard: a headless session can update this plugin at project scope and nothing else; a compound command does not match the entry | none: intended |
| Info | `plugins/claude-harness/skills/lot-start/SKILL.md:46` | The update installs whatever the marketplace's `main` declares, the trust model already in place (auto-update, PLUG-1, ASK-2); the path reaches `jq` through `--arg`, never spliced into the filter | none |

## Performance
| Severity | Location | Finding | Action |
|----------|----------|---------|--------|
| Info | `plugins/claude-harness/skills/lot-start/SKILL.md:47` | One network call per Part A of `lot-start` (a few seconds), skipped where the repository has no project-scope install | none: accepted by the lot |

## Architecture
| Severity | Location | Finding | Action |
|----------|----------|---------|--------|
| Info | `plugins/claude-harness/skills/lot-start/SKILL.md:38` | The skill cites ASK-2 and PLUG-1 by ID without restating them; plugin version bumped once (2.6.0, both manifests); review and audit reports in the census, `CLAUDE.md` and `AGENTS.md` identical | none |

## Coverage exclusions
| Exclusion | Business code? | Proposed action |
|-----------|----------------|-----------------|
| (none) | n/a | none |

## Migrations
n/a (`Migrations directory` is n/a).

## Lot-specific notes
- The guard reads `installed_plugins.json`: a repository that enables the plugin
  without a project-scope install (meal-planner-frontend today) is skipped and
  keeps running the user-scope copy, which PLUG-1 updates.
- The step takes effect in the 8 repositories only once the owner promotes
  `develop` → `main` and each installation updates.

## Recommended next steps
1. Promote `develop` → `main` (owner), then run `lot-start` once in each repository to pull 2.6.0.
