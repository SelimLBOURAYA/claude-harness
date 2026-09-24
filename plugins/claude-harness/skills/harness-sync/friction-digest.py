#!/usr/bin/env python3
"""Digest the gate friction of a repository into correction-lot drafts (lot 21).

    friction-digest.py <repo> [--lots FILE]... [--min N]

Reads every docs/audits/lot-N-friction.md (CONVENTIONS.md §13, « Friction »),
groups the entries by their stable key `<skill> / <step>`, and looks each key up
in the lots files: the repository's own (from its Gate parameters) plus every
--lots FILE, typically the harness dev-plan.md, where the correction lots of the
plugin skills live. Prints, as JSON on stdout:

  files   every friction file read: lot, path, date, entry count, sections missing
  window  the lots whose friction is reported: every lot holding an open or
          ineffective key, and at least the N most recent ones (--min, default 3)
  keys    one row per key: its occurrences, and its status
            open         no lots file cites the key
            planned      a lot cites it and is not merged yet (including a new
                         correction planned after an ineffective one)
            addressed    a merged lot cites it, and it has not come back since
                         (or the lot carries no merge date to measure against)
            ineffective  a merged lot cites it, a friction file created after
                         that merge carries it again, and no new lot is planned
  drafts  one correction-lot draft per skill holding open or ineffective keys

A lots file "cites" a key when it carries it in backticks inside a `## LOT`
section; the section's status and its `**Mergé** le YYYY-MM-DD` line give the
state of the correction. A key cited anywhere else is not seen, so a rejected
draft is recorded the same way, cited inside the `## LOT` section that set it
aside, to keep it from being proposed again.

Read-only: the script writes nothing, and never a SKILL.md or a lots file. The
drafts are proposals; the user decides what enters a lots file.

Exit status: 0 digest printed, 2 not a harnessed repository.
"""

import argparse
import datetime
import glob
import json
import os
import re
import sys

HOOKS = os.path.join(os.path.dirname(os.path.realpath(__file__)), "..", "..", "hooks")
sys.path.insert(0, os.path.normpath(HOOKS))

sys.dont_write_bytecode = True  # no __pycache__ inside the plugin tree
import lotfile  # noqa: E402  (path set above: the module ships with the hooks)

GATE_SKILLS = ("lot-start", "lot-test", "lot-review", "lot-audit", "lot-ship")
FILE_NAME = re.compile(r"^lot-([0-9]+[a-z]?(?:\.[0-9]+)?)-friction\.md$")
SECTION = re.compile(r"^## (\S+)\s*$")
ENTRY = re.compile(r"^- `([a-z0-9-]+) / ([^`]+)`\s*[—–-]?\s*(.*)$")
LOT_HEADING = re.compile(r"^## LOT ([0-9]+[a-z]?(?:\.[0-9]+)?)\b(.*)$", re.I)
MERGED_ON = re.compile(r"\*\*Mergé\*\* le (\d{4}-\d{2}-\d{2})")


def fail(message):
    print(json.dumps({"error": message}, ensure_ascii=False, indent=2))
    sys.exit(2)


def lot_order(lot_id):
    number = re.match(r"[0-9]+", lot_id)
    return (int(number.group(0)) if number else 0, lot_id)


def file_date(root, path):
    """The date the file was created in the history, else its date on disk.

    The author date of the commit that added it: the lot's start. Neither the
    committer date (rewritten by a rebase merge) nor the last change (a later
    fix of the file) may move a friction recorded before a correction to after
    it, which would report that correction as ineffective.
    """
    rel = os.path.relpath(path, root)
    added = lotfile.run_git(root, "log", "--diff-filter=A", "--format=%as", "--", rel)
    if added:
        return added.splitlines()[-1]
    return datetime.date.fromtimestamp(os.path.getmtime(path)).isoformat()


def read_friction(root, path):
    lot_id = FILE_NAME.match(os.path.basename(path)).group(1)
    # A section counts once it says something, an entry or None.: a bare
    # heading is a skill that did not record, as lot-deliverables.yml reads it.
    sections, entries, current = set(), [], None
    for line in lotfile.read_lines(path):
        heading = SECTION.match(line)
        if heading:
            current = heading.group(1)
            continue
        if current and line.strip():
            sections.add(current)
        entry = ENTRY.match(line)
        if entry and current:
            entries.append({
                "key": "%s / %s" % (entry.group(1), entry.group(2).strip()),
                "skill": entry.group(1),
                "step": entry.group(2).strip(),
                "section": current,
                "text": entry.group(3).strip(),
            })
            continue
        # A wrapped entry continues on an indented line.
        if entries and current and line.startswith("  ") and line.strip():
            entries[-1]["text"] = (entries[-1]["text"] + " " + line.strip()).strip()
    return {
        "lot": lot_id,
        "path": os.path.relpath(path, root),
        "date": file_date(root, path),
        "entries": entries,
        "missing_sections": [s for s in GATE_SKILLS if s not in sections],
    }


def citations(lots_path):
    """Every backticked key cited inside a `## LOT` section, with its state."""
    found = []
    lot_id, heading, merged, keys = None, "", None, set()

    def flush():
        if lot_id is not None:
            for key in keys:
                found.append({
                    "key": key,
                    "lots_file": lots_path,
                    "lot": lot_id,
                    "status": lotfile.status_of(heading),
                    "merged": merged,
                })

    for line in lotfile.read_lines(lots_path):
        match = LOT_HEADING.match(line)
        if match:
            flush()
            lot_id, heading, merged, keys = match.group(1), line, None, set()
            continue
        if line.startswith("## "):
            flush()
            lot_id, heading, merged, keys = None, "", None, set()
            continue
        if lot_id is None:
            continue
        date = MERGED_ON.search(line)
        if date and merged is None:
            merged = date.group(1)
        for key in re.findall(r"`([a-z0-9-]+ / [^`]+)`", line):
            keys.add(key.strip())
    flush()
    return found


def classify(occurrences, cites):
    """open / planned / addressed / ineffective, and the lot that decides it."""
    if not cites:
        return "open", None
    pending = [c for c in cites if c["status"] != lotfile.DONE]
    merged = [c for c in cites if c["status"] == lotfile.DONE]
    if not merged:
        return "planned", pending[0]
    dated = [c for c in merged if c["merged"]]
    if not dated:
        # A lot marked done with no **Mergé** line (a rebase merge, a status
        # set by hand): merged, but with no date to measure the fix against.
        return "addressed", merged[0]
    fix = max(dated, key=lambda c: c["merged"])
    if any(o["date"] > fix["merged"] for o in occurrences):
        # A new correction already planned is on its way: not a new draft.
        return ("planned", pending[0]) if pending else ("ineffective", fix)
    return "addressed", fix


def main():
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("repo")
    parser.add_argument("--lots", action="append", default=[])
    parser.add_argument("--min", type=int, default=3)
    args = parser.parse_args()

    root = lotfile.repo_root(args.repo)
    if root is None or lotfile.gate_parameters(root) is None:
        fail("%s is not a harnessed repository (no Gate parameters)" % args.repo)

    paths = [p for p in glob.glob(os.path.join(root, "docs", "audits", "lot-*-friction.md"))
             if FILE_NAME.match(os.path.basename(p))]
    files = sorted((read_friction(root, p) for p in paths),
                   key=lambda f: (f["date"], lot_order(f["lot"])))

    lots_paths = []
    own = lotfile.lots_file(root)
    for path in ([own] if own else []) + args.lots:
        path = os.path.abspath(os.path.expanduser(path))
        if os.path.isfile(path) and path not in lots_paths:
            lots_paths.append(path)
    cites = [c for path in lots_paths for c in citations(path)]

    by_key = {}
    for f in files:
        for entry in f["entries"]:
            by_key.setdefault(entry["key"], []).append({
                "lot": f["lot"], "date": f["date"], "text": entry["text"],
                "skill": entry["skill"], "step": entry["step"],
            })

    keys = []
    for key, occurrences in by_key.items():
        status, decided_by = classify(occurrences, [c for c in cites if c["key"] == key])
        keys.append({
            "key": key,
            "skill": occurrences[0]["skill"],
            "step": occurrences[0]["step"],
            "status": status,
            "decided_by": decided_by,
            "occurrences": [{k: o[k] for k in ("lot", "date", "text")} for o in occurrences],
        })
    keys.sort(key=lambda k: (k["skill"], k["step"]))

    live = {"open", "ineffective"}
    window = {o["lot"] for k in keys if k["status"] in live for o in k["occurrences"]}
    if args.min > 0:
        window.update(f["lot"] for f in files[-args.min:])

    drafts = []
    for skill in sorted({k["skill"] for k in keys if k["status"] in live}):
        mine = [k for k in keys if k["skill"] == skill and k["status"] in live]
        drafts.append({
            "skill": skill,
            "target": "claude-harness/dev-plan.md" if skill in GATE_SKILLS
                      else "the project's lots file",
            "keys": [k["key"] for k in mine],
            "ineffective": [k["key"] for k in mine if k["status"] == "ineffective"],
            "lots": sorted({o["lot"] for k in mine for o in k["occurrences"]}, key=lot_order),
        })

    print(json.dumps({
        "repo": root,
        "lots_files": lots_paths,
        "files": [{k: f[k] for k in ("lot", "path", "date", "missing_sections")}
                  | {"entries": len(f["entries"])} for f in files],
        "window": sorted(window, key=lot_order),
        "keys": keys,
        "drafts": drafts,
    }, ensure_ascii=False, indent=2))
    return 0


if __name__ == "__main__":
    sys.exit(main())
