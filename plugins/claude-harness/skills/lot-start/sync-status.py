#!/usr/bin/env python3
"""Synchronise the status table of a lots file with develop (CONVENTIONS.md §2.1).

    sync-status.py <repo> [--apply] [--start <lot>]

Reads the status table, maps every merge on develop to its lot by branch name,
and reports, as JSON on stdout:

  updates      lots whose merge is on develop but whose row is not done yet
  stops        what the agent must ask the user instead of deciding
  in_progress  rows marked in progress
  candidate    first to-do row, in file order, once the updates are applied
  changed      whether --apply modified the lots file

A mapping is applied only when it names exactly one lot. Anything else is a stop,
never an arbitration: an ambiguous merge (sub-lots on one flat branch, a branch
shared by several open rows), a lot marked done with no trace on develop, a
lot-shaped merge with no row, or merged commits already carrying the candidate's
scope.

A merge or a scoped commit whose SHA the lots file already cites in backticks
(`abc1234`, as in the `**Mergé**` notes this script writes) is reconciled: the
user's answer to a stop is recorded that way, and the stop does not come back.

--apply writes the updates, and nothing at all while a stop is pending.
--start <lot> also marks that lot in progress, after the user confirmed it.
The script never commits: the skill commits `docs: sync lots file status` only
when the file changed.

Exit status: 0 clean, 3 stops pending, 2 not a harnessed repository / no table /
no develop.
"""

import argparse
import json
import os
import re
import sys

HOOKS = os.path.join(os.path.dirname(os.path.realpath(__file__)), "..", "..", "hooks")
sys.path.insert(0, os.path.normpath(HOOKS))

sys.dont_write_bytecode = True  # no __pycache__ inside the plugin tree
import lotfile  # noqa: E402  (path set above: the module ships with the hooks)

CITED_SHA = re.compile(r"`([0-9a-f]{7,40})`")
MERGE_PR = re.compile(r"^Merge pull request #(\d+) from [^/\s]+/(\S+)")
MERGE_BRANCH = re.compile(r"^Merge (?:remote-tracking )?branch '([^']+)'")
SCOPE = re.compile(r"^[a-z]+\(([^)]*)\)!?:")


def fail(message):
    print(json.dumps({"error": message}, ensure_ascii=False, indent=2))
    sys.exit(2)


def develop_ref(root):
    for ref in ("origin/develop", "develop"):
        if lotfile.run_git(root, "rev-parse", "--verify", "-q", ref) is not None:
            return ref
    return None


def history(root, ref):
    """First-parent commits of develop, oldest first: (sha, date, subject, full)."""
    out = lotfile.run_git(
        root, "log", "--first-parent", "--reverse", "--format=%h%x09%cs%x09%H%x09%s", ref
    )
    commits = []
    for line in (out or "").splitlines():
        parts = line.split("\t", 3)
        if len(parts) == 4:
            commits.append((parts[0], parts[1], parts[3], parts[2]))
    return commits


def reconciled(full_sha, cited):
    """True when the lots file already cites this commit (a recorded answer)."""
    return any(full_sha.startswith(token) for token in cited)


def merged_branch(subject):
    match = MERGE_PR.match(subject)
    if match:
        return match.group(2), match.group(1)
    match = MERGE_BRANCH.match(subject)
    if match:
        return match.group(1), None
    return None, None


def scope_covers(subject, lot_id):
    """True when a commit scope names the lot: `feat(5)`, `feat(2.1)` for lot 2,
    or a range `docs(0-6)` for lot 2b."""
    match = SCOPE.match(subject)
    if not match:
        return False
    lot = lot_id.lower()
    base = lotfile.lot_base(lot)
    base_num = re.match(r"\d+", base)
    for token in re.split(r"[,\s]+", match.group(1).lower()):
        if not token:
            continue
        if token == lot or ("." not in lot and lotfile.lot_base(token) == lot):
            return True
        bounds = re.fullmatch(r"(\d+)-(\d+)", token)
        if bounds and base_num:
            if int(bounds.group(1)) <= int(base_num.group(0)) <= int(bounds.group(2)):
                return True
    return False


def has_sub_lots(text, lot_id):
    pattern = r"lot[ -]?%s\.[0-9]" % re.escape(lotfile.lot_base(lot_id))
    return re.search(pattern, text, re.I) is not None


def heading_index(lines, lot_id):
    pattern = re.compile(
        r"^#{1,4}\s.*?lot[ -]?%s(?![0-9a-z]|\.[0-9])" % re.escape(lot_id), re.I
    )
    for index, line in enumerate(lines):
        if pattern.match(line):
            return index
    return None


def replace_status(line, status):
    old = lotfile.status_of(line)
    if not old:
        return line
    return re.sub(re.escape(old) + "\ufe0f?", status, line, count=1)


def set_cell_status(lines, row, status):
    """Rewrite the status cell of a row. Line count is unchanged."""
    cells = lines[row["line"]].split("|")
    # cells[0] is the text before the leading pipe, so the column is shifted by one.
    col = row["status_col"] + 1
    replaced = replace_status(cells[col], status)
    cells[col] = replaced if replaced != cells[col] else " %s " % status
    lines[row["line"]] = "|".join(cells)


def main():
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("repo")
    parser.add_argument("--apply", action="store_true")
    parser.add_argument("--start")
    args = parser.parse_args()

    root = lotfile.repo_root(args.repo)
    if root is None:
        fail("%s is not inside a git repository" % args.repo)
    params = lotfile.gate_parameters(root)
    if params is None:
        fail("%s/CLAUDE.md has no `## Gate parameters` section" % root)
    path = lotfile.lots_file(root, params)
    if path is None:
        fail("no lots file: `Lots file` in Gate parameters names nothing that exists")
    lines = lotfile.read_lines(path)
    text = "\n".join(lines)
    table = lotfile.status_table(lines)
    if table is None:
        fail("%s has no status table (a table with a Lot and a Statut column)" % path)
    ref = develop_ref(root)
    if ref is None:
        fail("neither origin/develop nor develop exists; run `git fetch` first")

    rows = table["rows"]
    for row in rows:
        row["status_col"] = table["status_col"]
    commits = history(root, ref)
    cited = set(CITED_SHA.findall(text))

    stops = []
    updates = []
    claimed = set()

    for sha, date, subject, full in commits:
        branch, pr = merged_branch(subject)
        if not branch:
            continue
        exact = [row for row in rows if row["branch"] and row["branch"] == branch]
        shaped = lotfile.ANY_LOT_BRANCH.match(branch)
        if exact:
            candidates, by_pattern = exact, False
        elif shaped:
            base = shaped.group(1).lower()
            candidates = [row for row in rows if lotfile.lot_base(row["id"]) == base]
            by_pattern = True
        else:
            continue  # chore/*, a back-merge of main: not a lot

        for row in candidates:
            claimed.add(row["id"])
        open_rows = [row for row in candidates if row["status"] != lotfile.DONE]
        if not candidates:
            stops.append(
                {
                    "kind": "merge-without-lot",
                    "detail": "merge %s (%s) has a lot-shaped branch but no row of the "
                    "status table maps to it" % (sha, branch),
                }
            )
            continue
        if not open_rows or reconciled(full, cited):
            continue
        ambiguous = len(candidates) > 1 or (
            by_pattern and has_sub_lots(text, candidates[0]["id"])
        )
        if ambiguous:
            stops.append(
                {
                    "kind": "ambiguous",
                    "detail": "merge %s (%s) cannot be mapped to one lot: it matches "
                    "%s (several rows, or sub-lots in the lots file); which lots does it "
                    "complete?"
                    % (sha, branch, ", ".join(row["id"] for row in candidates)),
                }
            )
            continue
        row = open_rows[0]
        updates.append(
            {"lot": row["id"], "branch": branch, "pr": pr, "sha": sha, "date": date}
        )
        row["status"] = lotfile.DONE
        row["merge"] = updates[-1]

    for row in rows:
        if row["status"] != lotfile.DONE or not row["branch"] or row.get("merge"):
            continue
        if row["id"] in claimed:
            continue
        if any(scope_covers(subject, row["id"]) for _, _, subject, _ in commits):
            continue
        stops.append(
            {
                "kind": "done-without-merge",
                "detail": "lot %s is marked done but develop has neither a merge of "
                "`%s` nor a commit scoped to it" % (row["id"], row["branch"]),
            }
        )

    in_progress = [row["id"] for row in rows if row["status"] == lotfile.IN_PROGRESS]
    candidate = next((row["id"] for row in rows if row["status"] == lotfile.TODO), None)

    if candidate is not None:
        carried = [
            "%s %s" % (sha, subject)
            for sha, _, subject, full in commits
            if scope_covers(subject, candidate) and not reconciled(full, cited)
        ]
        if carried:
            stops.append(
                {
                    "kind": "scope-already-merged",
                    "detail": "lot %s is still to do, but develop already carries "
                    "commits scoped to it: %s" % (candidate, "; ".join(carried[:5])),
                }
            )

    started = None
    if args.start:
        target = next(
            (row for row in rows if row["id"].lower() == args.start.lower()), None
        )
        if target is None:
            fail("lot %s is not a row of the status table" % args.start)
        if target["status"] not in (lotfile.TODO, lotfile.IN_PROGRESS):
            fail("lot %s cannot start: its status is %s" % (args.start, target["status"]))
        started = target["id"]

    changed = False
    if args.apply and not stops:
        before = list(lines)
        marks = [(update["lot"], lotfile.DONE, update) for update in updates]
        if started:
            marks.append((started, lotfile.IN_PROGRESS, None))
        headings = []
        for lot_id, status, update in marks:
            row = next(row for row in rows if row["id"] == lot_id)
            set_cell_status(lines, row, status)
            heading = heading_index(lines, lot_id)
            if heading is not None:
                lines[heading] = replace_status(lines[heading], status)
                if update:
                    headings.append((heading, update))
        # Insert bottom-up so an insertion never shifts a heading still to process.
        for heading, update in sorted(headings, key=lambda item: item[0], reverse=True):
            pr = "PR #%s, " % update["pr"] if update["pr"] else ""
            note = "**Mergé** le %s (%smerge `%s`)." % (update["date"], pr, update["sha"])
            if note not in lines[heading + 1 : heading + 3]:
                lines[heading + 1 : heading + 1] = ["", note]
        changed = lines != before
        if changed:
            with open(path, "w", encoding="utf-8") as handle:
                handle.write("\n".join(lines))

    print(
        json.dumps(
            {
                "repo": root,
                "lots_file": os.path.relpath(path, root),
                "ref": ref,
                "updates": updates,
                "stops": stops,
                "in_progress": in_progress,
                "candidate": candidate,
                "started": started if args.apply and not stops else None,
                "changed": changed,
            },
            ensure_ascii=False,
            indent=2,
        )
    )
    return 3 if stops else 0


if __name__ == "__main__":
    sys.exit(main())
