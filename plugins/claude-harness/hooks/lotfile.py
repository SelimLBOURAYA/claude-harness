#!/usr/bin/env python3
"""Shared readers for the lot 19 hooks and the lot-start skill.

One definition of what a harnessed repository, its lots file, its status table
and its lot lock are, so the write guard, the confirmation hook, the session
context hook and the status synchronisation cannot drift apart.

Standard library only (V6), like git-guard.py.

CLI, for the shell hooks:

  lotfile.py root <path>            repository toplevel, empty when none
  lotfile.py lots-file <root>       absolute path of the lots file, empty when none
  lotfile.py table <root>           status table, done rows folded into one line
  lotfile.py has-lot <root> <id>    exit 0 when <id> is a row of the status table
  lotfile.py lock <root>            the lock, one key=value per line, empty when none
"""

import os
import re
import subprocess
import sys

LOCK_PATH = os.path.join(".claude", "current-lot")
LOTS_FILE_FALLBACKS = ("lots.md", "LOTS.md", "dev-plan.md")

DONE = "✅"
TODO = "⬜"
IN_PROGRESS = "\U0001f504"
PAUSED = "⏸"
FROZEN = "❄"
STATUSES = (DONE, TODO, IN_PROGRESS, PAUSED, FROZEN)

# A lot branch: feat/lot-19-slug, feat/lot-6b-slug. Sub-lots share the flat
# branch of their parent (CONVENTIONS.md section 7: no N.M in branch names).
LOT_BRANCH = re.compile(r"^feat/lot-([0-9]+[a-z]?)(?:-|$)")
# Any lot-shaped branch, whatever its type prefix.
ANY_LOT_BRANCH = re.compile(r"^(?:feat|fix|chore)/lot-([0-9]+[a-z]?)(?:-|$)")


def run_git(cwd, *args):
    try:
        result = subprocess.run(
            ["git", "-C", cwd, *args],
            capture_output=True,
            text=True,
            timeout=10,
        )
    except (OSError, subprocess.SubprocessError):
        return None
    if result.returncode != 0:
        return None
    return result.stdout.rstrip("\n")


def existing_dir(path):
    """The closest existing directory at or above path."""
    path = os.path.abspath(path)
    while not os.path.isdir(path):
        parent = os.path.dirname(path)
        if parent == path:
            return None
        path = parent
    return path


def repo_root(path):
    start = existing_dir(path)
    if start is None:
        return None
    return run_git(start, "rev-parse", "--show-toplevel") or None


def current_branch(root):
    return run_git(root, "rev-parse", "--abbrev-ref", "HEAD")


def gate_parameters(root):
    """The Gate parameters of CLAUDE.md as a dict, or None when not harnessed."""
    try:
        with open(os.path.join(root, "CLAUDE.md"), encoding="utf-8") as handle:
            text = handle.read()
    except OSError:
        return None
    match = re.search(r"^## Gate parameters[ \t]*$", text, re.M)
    if not match:
        return None
    section = text[match.end():]
    end = re.search(r"^## ", section, re.M)
    if end:
        section = section[: end.start()]
    params = {}
    for line in section.splitlines():
        cells = [cell.strip() for cell in line.strip().strip("|").split("|")]
        if len(cells) >= 2 and cells[0].startswith("`"):
            params[cells[0].strip("`")] = cells[1].strip("`").strip()
    return params


def lots_file(root, params=None):
    if params is None:
        params = gate_parameters(root) or {}
    declared = params.get("Lots file", "")
    candidates = []
    if declared and declared.lower() not in ("n/a", "(none)"):
        candidates.append(declared)
    candidates.extend(LOTS_FILE_FALLBACKS)
    for name in candidates:
        path = os.path.join(root, name)
        if os.path.isfile(path):
            return path
    return None


def status_of(cell):
    for status in STATUSES:
        if status in cell:
            return status
    return None


def split_row(line):
    return [cell.strip() for cell in line.strip().strip("|").split("|")]


def status_table(lines):
    """Locate the status table: the first table with a Lot and a Statut column.

    Returns a dict with the header index, the column indexes and the rows, or
    None. Each row carries its line index so a caller can rewrite it in place.
    """
    for index, line in enumerate(lines):
        if not line.lstrip().startswith("|"):
            continue
        header = [cell.lower() for cell in split_row(line)]
        if "lot" not in header:
            continue
        status_col = next(
            (i for i, cell in enumerate(header) if cell in ("statut", "status")), None
        )
        if status_col is None:
            continue
        branch_col = next(
            (i for i, cell in enumerate(header) if cell in ("branche", "branch")), None
        )
        lot_col = header.index("lot")
        rows = []
        cursor = index + 2  # skip the |---| separator
        while cursor < len(lines) and lines[cursor].lstrip().startswith("|"):
            cells = split_row(lines[cursor])
            if len(cells) > max(lot_col, status_col):
                branch = ""
                if branch_col is not None and branch_col < len(cells):
                    ticked = re.search(r"`([^`]+)`", cells[branch_col])
                    branch = ticked.group(1) if ticked else ""
                    # `chore/harness-adoption` (kb): a branch of another repo.
                    if re.search(r"`\s*\(", cells[branch_col]):
                        branch = ""
                rows.append(
                    {
                        "id": cells[lot_col].strip("`* "),
                        "branch": branch.strip(),
                        "status": status_of(cells[status_col]),
                        "line": cursor,
                    }
                )
            cursor += 1
        return {
            "header": index,
            "end": cursor,
            "lot_col": lot_col,
            "status_col": status_col,
            "rows": rows,
        }
    return None


def read_lines(path):
    with open(path, encoding="utf-8") as handle:
        return handle.read().split("\n")


def lot_base(lot_id):
    """`2.1` -> `2`: the part of a lot ID a branch name can carry."""
    return lot_id.split(".", 1)[0].lower()


def read_lock(root):
    try:
        with open(os.path.join(root, LOCK_PATH), encoding="utf-8") as handle:
            text = handle.read()
    except OSError:
        return None
    lock = {}
    for line in text.splitlines():
        if "=" in line:
            key, value = line.split("=", 1)
            lock[key.strip()] = value.strip()
    return lock if lock.get("lot") and lock.get("branch") else None


# --------------------------------------------------------------------------
# CLI


def cli_table(root):
    path = lots_file(root)
    if path is None:
        return 1
    lines = read_lines(path)
    table = status_table(lines)
    if table is None:
        return 1
    done = [row["id"] for row in table["rows"] if row["status"] == DONE]
    print(lines[table["header"]])
    print(lines[table["header"] + 1])
    for row in table["rows"]:
        if row["status"] != DONE:
            print(lines[row["line"]])
    if done:
        print("(done, rows folded: %s)" % ", ".join(done))
    return 0


def main(argv):
    if len(argv) < 3:
        print(__doc__, file=sys.stderr)
        return 2
    command, target = argv[1], argv[2]
    if command == "root":
        print(repo_root(target) or "")
        return 0
    if command == "lots-file":
        print(lots_file(target) or "")
        return 0
    if command == "table":
        return cli_table(target)
    if command == "has-lot" and len(argv) == 4:
        path = lots_file(target)
        table = status_table(read_lines(path)) if path else None
        ids = {row["id"].lower() for row in table["rows"]} if table else set()
        return 0 if argv[3].lower() in ids else 1
    if command == "lock":
        lock = read_lock(target) or {}
        for key, value in lock.items():
            print("%s=%s" % (key, value))
        return 0
    print(__doc__, file=sys.stderr)
    return 2


if __name__ == "__main__":
    sys.exit(main(sys.argv))
