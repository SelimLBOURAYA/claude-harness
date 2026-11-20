## Model routing

### Advisor (Opus)
- Call the advisor BEFORE substantive work: before writing code,
  committing to an interpretation, or building on an assumption.
  Read-only orientation (finding files, reading sources) may come first.
- Call it when stuck: recurring errors, non-converging approach,
  results that don't fit, or before changing approach.
- Call it BEFORE declaring done — save/commit the deliverable first.
- Target 2-3 calls per task. Short reactive steps don't need one.
- Give advice serious weight. If evidence contradicts it, don't
  silently switch: make one more advisor call stating the conflict.

### Subagents (Haiku)
- Delegate to at most 3 parallel subagents, read-only work only:
  codebase search, log/test-output triage, summarizing, classification.
- Never delegate file edits, migrations, or state-changing commands.
- Each subagent returns conclusions + file:line refs, not file dumps.
- Verify subagent findings before acting on them.

### Delegation triggers
- Delegate before doing the work yourself when a search likely needs
  more than 2 grep/glob calls or spans more than 5 files, or when test,
  build or log output longer than ~50 lines must be triaged.
- Exempt: one grep or read on a known path, or files already in context.
- Latency and "the task looks simple" are not valid reasons to skip
  a trigger.

### Opus sessions
- Never call the advisor: no model in this session is stronger than you.
