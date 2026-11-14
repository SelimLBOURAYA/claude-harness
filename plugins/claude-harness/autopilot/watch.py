#!/usr/bin/env python3
"""Follow an autopilot run: one line per tool call, text, denial and step result.

Usage: watch.py [project_dir [since]]   (default: the current directory, any age)
Reads the newest ~/.claude/autopilot/<project>/*.jsonl written at or after the
epoch `since` and switches to the next step's log as soon as it appears; the
autopilot passes its start, so a previous run's log is never shown as live.
Ctrl-C to quit. Stdlib only.
"""
import collections
import glob
import json
import os
import re
import sys
import time

BACKLOG = 15


def newest(folder, since=0):
    found = []
    for log in glob.glob(os.path.join(folder, "*.jsonl")):
        try:
            mtime = os.path.getmtime(log)
        except OSError:
            continue
        if mtime >= since:
            found.append((mtime, log))
    return max(found)[1] if found else None


def complete_lines(handle):
    """The complete lines from the handle's position; a half-written one is left for the next read."""
    while True:
        start = handle.tell()
        raw = handle.readline()
        if not raw.endswith("\n"):
            handle.seek(start)
            return
        yield raw


def step_of(path):
    return os.path.basename(path).rsplit("-", 1)[-1].replace(".jsonl", "")


def detail(args):
    for key in ("file_path", "skill", "description", "command", "pattern", "prompt"):
        if args.get(key):
            return str(args[key]).splitlines()[0][:100]
    return ""


MODEL = {"name": "?"}
# C0 and C1 controls: a model's text or a tool input must not drive the terminal (escape sequences).
CONTROL = re.compile("[\x00-\x1f\x7f-\x9f]")


def lines(event, step, stamp=None):
    for line in render(event, step, stamp):
        yield CONTROL.sub("?", line)


def render(event, step, stamp=None):
    stamp = stamp or time.strftime("%H:%M:%S")
    kind, sub = event.get("type"), event.get("subtype")
    if kind == "system" and sub == "init" and event.get("model"):
        MODEL["name"] = event["model"].split("[")[0]
    agent = MODEL["name"]
    if kind == "assistant":
        agent = ((event.get("message") or {}).get("model") or agent).split("[")[0]
        if event.get("parent_tool_use_id"):
            agent = "↳" + agent
    step = "%-11s %-16s" % (step, agent[:16])
    if kind == "assistant":
        for block in (event.get("message") or {}).get("content") or []:
            if block.get("type") == "tool_use":
                yield "%s  %s %-8s %s" % (stamp, step, block.get("name"), detail(block.get("input") or {}))
            elif block.get("type") == "text" and (block.get("text") or "").strip():
                yield "%s  %s » %s" % (stamp, step, block["text"].strip().splitlines()[0][:110])
    elif kind == "system" and sub == "permission_denied":
        yield "%s  %s ✗ refusé %s: %s" % (stamp, step, event.get("tool_name"), (event.get("message") or "")[:90])
    elif kind == "system" and sub == "code_change_published":
        yield "%s  %s ↗ %s" % (stamp, step, event.get("url"))
    elif kind == "result":
        answer = event.get("structured_output") or {}
        if not answer:
            try:
                answer = json.loads(event.get("result") or "")
            except (TypeError, ValueError):
                answer = {}
        if not isinstance(answer, dict):
            answer = {}
        yield "%s  %s ✔ fin d'étape: %s %s" % (
            stamp, step, answer.get("status") or event.get("subtype"), str(answer.get("reason") or "")[:90])
        for question in answer.get("questions") or []:
            yield "                              ? %s" % str(question)[:150]


def parse(raw):
    """A stream event; the session's stderr shares the log, so anything but a JSON object is skipped."""
    try:
        event = json.loads(raw)
    except ValueError:
        return None
    return event if isinstance(event, dict) else None


def main():
    root = os.path.abspath(sys.argv[1] if len(sys.argv) > 1 else ".")
    since = float(sys.argv[2]) if len(sys.argv) > 2 else 0
    folder = os.path.join(os.path.expanduser("~/.claude/autopilot"), os.path.basename(root))
    print("autopilot-watch: %s (Ctrl-C pour quitter)" % folder, flush=True)
    current, handle = None, None
    while True:
        path = newest(folder, since)
        if path and path != current:
            current, step = path, step_of(path)
            if handle:
                handle.close()
            handle = open(path, encoding="utf-8", errors="replace")
            print("\n== %s ==" % os.path.basename(path), flush=True)
            backlog = collections.deque(maxlen=BACKLOG)
            # shortcut: the log has no per-event time, so the backlog shows the file's last write, prefixed with ~.
            before = "~" + time.strftime("%H:%M", time.localtime(os.path.getmtime(path)))
            for raw in complete_lines(handle):
                event = parse(raw)
                if event:
                    backlog.extend(lines(event, step, before.ljust(8)))
            print("\n".join(backlog), flush=True)
        if handle:
            for raw in complete_lines(handle):
                event = parse(raw)
                for line in lines(event, step) if event else ():
                    print(line, flush=True)
        time.sleep(1)


if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        pass
