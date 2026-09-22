#!/usr/bin/env python3
"""PreToolUse write guard: no development before the user confirmed the lot.

Matcher Edit|Write|MultiEdit|NotebookEdit. Reads the hook payload on stdin and
answers with a permission decision:

  deny  - a lot branch with no lock, or a lock for another lot or branch;
          any tool write to the lock file itself, or into the `.git` directory
          of a harnessed repository
  ask   - any write on develop or main, where no development takes place
  (silence) - everything else, and the normal permission flow applies

The lock is `.claude/current-lot`, written only by the UserPromptSubmit hook
lot-confirm.sh when the *user* types `lot-start confirm <N>`. The model cannot
forge a user prompt, so a lock is a real confirmation.

The repository is resolved from the path of the file being written, never from
the session directory (lesson C3 of lot 18): a session sitting in one clone and
writing into another must be judged against the other. The path is resolved
through symlinks for the same reason.

Writes into `.git` are denied rather than judged: git resolves no work tree
from inside its own directory, and a tool that rewrites `.git/HEAD` or
`core.worktree` in `.git/config` would change the branch or the root the guard
reads next, and so switch it off (lot 19 audit).

The guard never answers "allow": it only narrows permissions, like git-guard.py.

Known limit, accepted at the start of lot 19: a write made through Bash
(`sed -i`, `tee`, a redirection, a heredoc) is not seen by this guard. A shell
heuristic would catch some of them and give the impression of catching all.

Standard library only (V6).
"""

import json
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.realpath(__file__)))

sys.dont_write_bytecode = True  # no __pycache__ inside the plugin tree
import lotfile  # noqa: E402

WRITE_TOOLS = {"Edit", "Write", "MultiEdit", "NotebookEdit"}
PROTECTED = {"develop", "main"}


def decide(decision, reason):
    print(
        json.dumps(
            {
                "hookSpecificOutput": {
                    "hookEventName": "PreToolUse",
                    "permissionDecision": decision,
                    "permissionDecisionReason": reason,
                }
            }
        )
    )
    sys.exit(0)


def target_path(payload):
    tool_input = payload.get("tool_input") or {}
    path = tool_input.get("file_path") or tool_input.get("notebook_path")
    if not path:
        return None
    if not os.path.isabs(path):
        path = os.path.join(payload.get("cwd") or os.getcwd(), path)
    return os.path.realpath(path)


def git_dir_owner(path):
    """The directory holding the first `.git` component of path, or None."""
    parts = path.split(os.sep)
    if ".git" not in parts:
        return None
    return os.sep.join(parts[: parts.index(".git")]) or os.sep


def main():
    try:
        payload = json.load(sys.stdin)
    except (ValueError, OSError):
        sys.exit(0)
    if payload.get("tool_name") not in WRITE_TOOLS:
        sys.exit(0)

    path = target_path(payload)
    if path is None:
        sys.exit(0)

    owner = git_dir_owner(path)
    if owner is not None and lotfile.gate_parameters(owner) is not None:
        decide(
            "deny",
            "Writes into `%s/.git` are denied: they change the branch or the root "
            "this guard reads. Use git itself." % owner,
        )

    root = lotfile.repo_root(os.path.dirname(path))
    if root is None:
        sys.exit(0)
    root = os.path.realpath(root)
    rel = os.path.relpath(path, root)

    if rel == lotfile.LOCK_PATH:
        decide(
            "deny",
            "`.claude/current-lot` is written only by the lot-confirm hook, when the "
            "user types `lot-start confirm <N>`. A tool may not write it.",
        )

    params = lotfile.gate_parameters(root)
    if params is None:
        sys.exit(0)  # not a harnessed repository

    lots = lotfile.lots_file(root, params)
    if lots is not None and os.path.realpath(lots) == path:
        sys.exit(0)  # the status sync of section 2.1 happens before the lock

    branch = lotfile.current_branch(root)
    if branch in PROTECTED:
        decide(
            "ask",
            "`%s` is checked out in %s: no development happens on %s. Confirm this "
            "write, or create the lot branch with `lot-start` first." % (branch, root, branch),
        )

    match = lotfile.LOT_BRANCH.match(branch or "")
    if not match:
        sys.exit(0)  # chore/*, fix/*, a detached HEAD: no lot to lock
    lot = match.group(1).lower()

    how = (
        "Run `lot-start`, then have the user confirm with `lot-start confirm %s`."
        % lot
    )
    lock = lotfile.read_lock(root)
    if lock is None:
        decide(
            "deny",
            "No confirmed lot in %s: `.claude/current-lot` is absent. %s" % (root, how),
        )
    # Two different situations, told apart (lot 20). A lock naming an earlier
    # lot is the normal state at the start of the next one, and it is worth
    # saying so: the alternative is a message that reads like a corrupted lock.
    # A lock naming this same lot on another branch is not normal: the branch
    # was renamed or recreated since the confirmation, so that confirmation
    # named a branch that no longer exists.
    if lotfile.lot_base(lock["lot"]) != lot:
        decide(
            "deny",
            "`.claude/current-lot` still names lot %s, confirmed on `%s`: the lock of "
            "a previous lot, which is the normal state at the start of the next one. "
            "Each lot is confirmed once. %s" % (lock["lot"], lock["branch"], how),
        )
    if lock["branch"] != branch:
        decide(
            "deny",
            "Lot %s was confirmed on `%s`, but `%s` is checked out: the branch changed "
            "since the confirmation, so the confirmation names a branch that no longer "
            "exists. %s" % (lock["lot"], lock["branch"], branch, how),
        )
    sys.exit(0)


if __name__ == "__main__":
    main()
