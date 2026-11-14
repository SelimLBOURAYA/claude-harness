#!/usr/bin/env python3
"""Follow an autopilot run: one line per tool call, text, denial and step result.

Usage: watch.py [project_dir]   (default: the current directory)
Reads the newest ~/.claude/autopilot/<project>/*.jsonl and switches to the next
step's log as soon as it appears. Ctrl-C to quit. Stdlib only.
"""
import collections
import glob
import json
import os
import sys
import time

BACKLOG = 15


def newest(folder):
    logs = glob.glob(os.path.join(folder, "*.jsonl"))
    return max(logs, key=os.path.getmtime) if logs else None


def step_of(path):
    return os.path.basename(path).rsplit("-", 1)[-1].replace(".jsonl", "")


def detail(name, args):
    for key in ("file_path", "skill", "description", "command", "pattern", "prompt"):
        if args.get(key):
            return str(args[key]).splitlines()[0][:100]
    return ""


MODEL = {"name": "?"}


def lines(event, step, stamp=None):
    stamp = stamp or time.strftime("%H:%M:%S")
    kind, sub = event.get("type"), event.get("subtype")
    if kind == "system" and sub == "init" and event.get("model"):
        MODEL["name"] = event["model"].split("[")[0]
    agent = MODEL["name"]
    if kind == "assistant":
        agent = (event.get("message", {}).get("model") or agent).split("[")[0]
        if event.get("parent_tool_use_id"):
            agent = "↳" + agent
    step = "%-11s %-16s" % (step, agent[:16])
    if kind == "assistant":
        for block in event.get("message", {}).get("content", []):
            if block.get("type") == "tool_use":
                yield "%s  %-11s %-8s %s" % (stamp, step, block.get("name"), detail(block.get("name"), block.get("input") or {}))
            elif block.get("type") == "text" and block.get("text", "").strip():
                yield "%s  %-11s » %s" % (stamp, step, block["text"].strip().splitlines()[0][:110])
    elif kind == "system" and sub == "permission_denied":
        yield "%s  %-11s ✗ refusé %s: %s" % (stamp, step, event.get("tool_name"), event.get("message", "")[:90])
    elif kind == "system" and sub == "code_change_published":
        yield "%s  %-11s ↗ %s" % (stamp, step, event.get("url"))
    elif kind == "result":
        answer = event.get("structured_output") or {}
        if not answer:
            try:
                answer = json.loads(event.get("result") or "")
            except ValueError:
                answer = {}
        status = answer.get("status") if isinstance(answer, dict) else None
        yield "%s  %-11s ✔ fin d'étape: %s %s" % (
            stamp, step, status or event.get("subtype"), (answer.get("reason") or "")[:90] if isinstance(answer, dict) else "")
        for question in (answer.get("questions") or []) if isinstance(answer, dict) else []:
            yield "                              ? %s" % str(question)[:150]


def parse(raw):
    try:
        return json.loads(raw)
    except ValueError:
        return None


def main():
    root = os.path.abspath(sys.argv[1] if len(sys.argv) > 1 else ".")
    folder = os.path.join(os.path.expanduser("~/.claude/autopilot"), os.path.basename(root))
    print("autopilot-watch: %s (Ctrl-C pour quitter)" % folder, flush=True)
    current, handle = None, None
    while True:
        path = newest(folder)
        if path and path != current:
            current, step = path, step_of(path)
            if handle:
                handle.close()
            handle = open(path, encoding="utf-8", errors="replace")
            print("\n== %s ==" % os.path.basename(path), flush=True)
            backlog = collections.deque(maxlen=BACKLOG)
            # shortcut: the log has no per-event time, so the backlog shows the file's last write, prefixed with ~.
            before = "~" + time.strftime("%H:%M", time.localtime(os.path.getmtime(path)))
            for raw in handle:
                event = parse(raw)
                if event:
                    backlog.extend(lines(event, step, before.ljust(8)))
            print("\n".join(backlog), flush=True)
        if handle:
            raw = handle.readline()
            while raw:
                if not raw.endswith("\n"):
                    # shortcut: a half-written line is re-read once complete.
                    handle.seek(handle.tell() - len(raw.encode("utf-8")))
                    break
                event = parse(raw)
                for line in lines(event, step) if event else ():
                    print(line, flush=True)
                raw = handle.readline()
        time.sleep(1)


if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        pass
