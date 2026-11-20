#!/usr/bin/env python3
"""PostToolUse hook on the Agent tool: shows the user which model a subagent ran on (lot 40).

Answers with a `systemMessage`, `sous-agent <type> → <model>`: Claude Code shows
it to the user and never gives it to the model (lot 40, V5), so the display costs
no token. Never an `additionalContext`.

The model is the one that answered, `tool_response.resolvedModel`, which the
PostToolUse input carries (V5; PreToolUse does not). Without it (a background
subagent returns before it ran), the configured model is shown and marked as
such: the Agent call's own `model`, then CLAUDE_CODE_SUBAGENT_MODEL.

Never blocks: an unreadable input prints nothing and exits 0. Standard library only.
"""

import json
import os
import sys


def message(payload):
    tool_input = payload.get("tool_input")
    tool_input = tool_input if isinstance(tool_input, dict) else {}
    response = payload.get("tool_response")
    response = response if isinstance(response, dict) else {}
    kind = response.get("agentType") or tool_input.get("subagent_type") or "general-purpose"
    model = response.get("resolvedModel")
    if not model:
        configured = tool_input.get("model") or os.environ.get("CLAUDE_CODE_SUBAGENT_MODEL")
        model = "%s (configuré)" % configured if configured else "modèle de la session (configuré)"
    return "sous-agent %s → %s" % (kind, model)


def main():
    try:
        payload = json.load(sys.stdin)
    except ValueError:
        return
    if not isinstance(payload, dict) or payload.get("tool_name") not in ("Agent", "Task"):
        return
    print(json.dumps({"systemMessage": message(payload)}, ensure_ascii=False))


if __name__ == "__main__":
    main()
