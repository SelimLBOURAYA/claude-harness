#!/usr/bin/env python3
"""PreToolUse guard for git and gh commands.

Reads the hook payload on stdin and answers with a permission decision:

  deny  - the command is forbidden by CONVENTIONS.md section 7
  ask   - the command is reversible-but-outward-facing, or not parseable
  (silence) - nothing recognised, the normal permission flow applies

The guard never answers "allow": it must not widen permissions, only narrow them.
Anything it cannot parse produces "ask", never a silent pass.

Standard library only: the hook runs in IDE sessions whose PATH has no project
virtualenv (V6).
"""

import json
import os
import re
import shlex
import subprocess
import sys

PROTECTED_BRANCH = "main"
REQUIRED_PR_BASE = "develop"
DEFAULT_REMOTES = ("origin", "upstream")

# Options that make a push rewrite or delete remote history.
FORCE_FLAGS = {"--force", "-f", "--force-with-lease", "--force-if-includes"}

# A token we cannot resolve statically: shell expansion, substitution, glob.
UNRESOLVED = re.compile(r"[$`*?]|\$\(")

LOT_BRANCH = re.compile(r"^feat/lot-(\d+[a-z]?)(?:-|$)")
# A report line still carrying an unresolved Critical finding.
CRITICAL_LINE = re.compile(r"critical", re.IGNORECASE)
RESOLVED_MARK = re.compile(r"\b(resolved|fixed|closed|none|0)\b", re.IGNORECASE)


# --------------------------------------------------------------------------
# decisions


def decide(decision, reason):
    """Emit a permission decision and stop."""
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


def deny(reason):
    decide("deny", reason)


def ask(reason):
    decide("ask", reason)


# --------------------------------------------------------------------------
# command splitting


def tokenize(command):
    """Split a shell command into tokens, keeping operators as their own token.

    Returns None when the command cannot be lexed (unbalanced quotes), which the
    caller turns into a confirmation prompt.
    """
    lexer = shlex.shlex(command, posix=True, punctuation_chars=True)
    lexer.whitespace_split = True
    try:
        return list(lexer)
    except ValueError:
        return None


def segments(tokens):
    """Split a token list on shell separators into individual commands.

    Recurses into `bash -c "..."` / `sh -c "..."` so a wrapped command is
    inspected like a bare one.
    """
    out = []
    current = []
    for token in tokens:
        if token in ("&&", "||", ";", "|", "&", "\n"):
            if current:
                out.append(current)
            current = []
        else:
            current.append(token)
    if current:
        out.append(current)

    expanded = []
    for segment in out:
        head = strip_assignments(segment)
        if len(head) >= 3 and os.path.basename(head[0]) in ("bash", "sh", "zsh"):
            try:
                flag_index = head.index("-c")
            except ValueError:
                flag_index = -1
            if flag_index != -1 and flag_index + 1 < len(head):
                inner = tokenize(head[flag_index + 1])
                if inner is None:
                    ask(
                        "Command wrapped in `%s -c` could not be parsed; confirm manually."
                        % head[0]
                    )
                expanded.extend(segments(inner))
                continue
        expanded.append(segment)
    return expanded


def has_short_flag(tokens, letter):
    """True when a short flag is present, including bundled (`-rd`, `-fu`)."""
    for token in tokens:
        if token.startswith("-") and not token.startswith("--"):
            if letter in token[1:].split("=", 1)[0]:
                return True
    return False


def strip_assignments(segment):
    """Drop leading `VAR=value` environment assignments."""
    index = 0
    while index < len(segment) and re.match(r"^[A-Za-z_][A-Za-z0-9_]*=", segment[index]):
        index += 1
    return segment[index:]


# --------------------------------------------------------------------------
# git context


def run_git(cwd, *args):
    try:
        result = subprocess.run(
            ["git", *args],
            cwd=cwd or None,
            capture_output=True,
            text=True,
            timeout=5,
        )
    except (OSError, subprocess.SubprocessError):
        return None
    if result.returncode != 0:
        return None
    return result.stdout.strip()


def current_branch(cwd):
    return run_git(cwd, "rev-parse", "--abbrev-ref", "HEAD")


def repo_root(cwd):
    return run_git(cwd, "rev-parse", "--show-toplevel")


def known_remotes(cwd):
    listed = run_git(cwd, "remote")
    if not listed:
        return set(DEFAULT_REMOTES)
    return set(listed.split()) | set(DEFAULT_REMOTES)


# --------------------------------------------------------------------------
# git parsing


def parse_git_globals(segment, cwd):
    """Consume git's global options, returning (cwd, remaining tokens).

    Denies straight away on a hooks-path override, which is `--no-verify` by
    another name.
    """
    tokens = segment[1:]
    index = 0
    while index < len(tokens):
        token = tokens[index]
        if token in ("-C", "--git-dir", "--work-tree") and index + 1 < len(tokens):
            if token == "-C":
                cwd = os.path.join(cwd, tokens[index + 1]) if cwd else tokens[index + 1]
            index += 2
            continue
        if token.startswith("-C") and len(token) > 2:
            cwd = os.path.join(cwd, token[2:]) if cwd else token[2:]
            index += 1
            continue
        if token.startswith("--git-dir=") or token.startswith("--work-tree="):
            index += 1
            continue
        if token in ("-c", "--config-env") and index + 1 < len(tokens):
            check_config_override(tokens[index + 1])
            index += 2
            continue
        if token.startswith("-c") and len(token) > 2:
            check_config_override(token[2:])
            index += 1
            continue
        if token.startswith("-"):
            index += 1
            continue
        break
    return cwd, tokens[index:]


def check_config_override(setting):
    if setting.split("=", 1)[0].strip().lower() == "core.hookspath":
        deny(
            "Overriding core.hooksPath disables the local hooks; this is the same "
            "bypass as --no-verify (CONVENTIONS.md section 7)."
        )


def push_destinations(args, cwd):
    """Return the destination branch names of a push, normalised.

    An empty list means "no refspec given", i.e. the current branch.
    """
    remotes = known_remotes(cwd)
    positionals = []
    index = 0
    while index < len(args):
        token = args[index]
        if token == "--":
            positionals.extend(args[index + 1 :])
            break
        if token.startswith("-"):
            # Options taking a separate value; none of them is a refspec.
            if token in ("--repo", "-o", "--push-option", "--receive-pack", "--exec"):
                index += 2
                continue
            index += 1
            continue
        positionals.append(token)
        index += 1

    refspecs = [token for token in positionals if token not in remotes]
    # `git push origin` where origin is also a branch name is vanishingly rare;
    # treating the first positional as the remote keeps the common case right.
    if positionals and refspecs == positionals and positionals[0] in DEFAULT_REMOTES:
        refspecs = positionals[1:]

    destinations = []
    for spec in refspecs:
        stripped = spec.lstrip("+")
        destination = stripped.split(":")[-1] if ":" in stripped else stripped
        destination = destination.replace("refs/heads/", "")
        destinations.append((spec, destination))
    return destinations


def guard_push(args, cwd):
    flags = {token for token in args if token.startswith("-")}

    if (
        flags & FORCE_FLAGS
        or has_short_flag(args, "f")
        or any(token.startswith("+") for token in args if not token.startswith("-"))
    ):
        deny(
            "Force push rewrites published history. Forbidden by CONVENTIONS.md "
            "section 4; ask the user before any history rewrite."
        )
    # Only the long form here: on push, `-n` is --dry-run, not --no-verify.
    if "--no-verify" in flags:
        deny("--no-verify skips the hooks; forbidden by CONVENTIONS.md section 7.")
    if "--delete" in flags or has_short_flag(args, "d"):
        deny(
            "Deleting a remote branch is a user decision (CONVENTIONS.md section 4)."
        )

    destinations = push_destinations(args, cwd)
    for spec, destination in destinations:
        if spec.startswith(":"):
            deny(
                "`git push <remote> :branch` deletes a remote branch; that is a user "
                "decision (CONVENTIONS.md section 4)."
            )
        if UNRESOLVED.search(spec):
            ask(
                "Push target `%s` contains a shell expansion the guard cannot resolve; "
                "confirm the destination branch manually." % spec
            )
        if destination == PROTECTED_BRANCH:
            deny(
                "Pushing to `%s` is forbidden: it is the production branch. The "
                "promotion develop -> main is done by the user (CONVENTIONS.md "
                "section 7)." % PROTECTED_BRANCH
            )

    if not destinations:
        branch = current_branch(cwd)
        if branch is None:
            ask(
                "Push with no explicit refspec and the current branch could not be "
                "resolved; confirm manually."
            )
        if branch == PROTECTED_BRANCH:
            deny(
                "The current branch is `%s`: pushing it is forbidden (CONVENTIONS.md "
                "section 7)." % PROTECTED_BRANCH
            )

    ask("`git push` reaches the remote; confirm before publishing.")


def guard_git(segment, cwd):
    cwd, args = parse_git_globals(segment, cwd)
    if not args:
        return
    subcommand, rest = args[0], args[1:]
    flags = {token for token in rest if token.startswith("-")}

    if subcommand == "push":
        guard_push(rest, cwd)

    if subcommand == "commit" and (
        "--no-verify" in flags or has_short_flag(rest, "n")
    ):
        deny(
            "--no-verify skips the pre-commit hooks; forbidden by CONVENTIONS.md "
            "section 7. Fix the hook failure instead."
        )

    if subcommand == "reset" and "--hard" in flags:
        deny(
            "`git reset --hard` destroys uncommitted work; it is a user decision "
            "(CONVENTIONS.md section 4)."
        )

    if subcommand == "branch" and (
        "--delete" in flags or has_short_flag(rest, "d") or has_short_flag(rest, "D")
    ):
        remotes = known_remotes(cwd)
        remote_scoped = "--remotes" in flags or has_short_flag(rest, "r")
        for token in rest:
            if token.startswith("-"):
                continue
            if remote_scoped or token.split("/", 1)[0] in remotes:
                deny(
                    "Deleting the remote branch `%s` is a user decision "
                    "(CONVENTIONS.md section 4)." % token
                )


# --------------------------------------------------------------------------
# gh parsing


def option_value(args, *names):
    for index, token in enumerate(args):
        if token in names and index + 1 < len(args):
            return args[index + 1]
        for name in names:
            if token.startswith(name + "="):
                return token.split("=", 1)[1]
    return None


def gate_parameter(root, name):
    """Read one `## Gate parameters` value from the repo CLAUDE.md."""
    path = os.path.join(root, "CLAUDE.md")
    try:
        with open(path, encoding="utf-8") as handle:
            content = handle.read()
    except OSError:
        return None
    match = re.search(
        r"^\|\s*`?%s`?\s*\|\s*`?([^|`]+)`?\s*\|" % re.escape(name),
        content,
        re.MULTILINE,
    )
    return match.group(1).strip() if match else None


def guard_pr_deliverables(cwd):
    root = repo_root(cwd)
    branch = current_branch(cwd)
    if root is None or branch is None:
        ask("Repository state could not be resolved; confirm the PR creation manually.")

    match = LOT_BRANCH.match(branch)
    if match:
        lot = match.group(1)
        report = os.path.join(root, "docs", "audits", "lot-%s.md" % lot)
        if not os.path.isfile(report):
            deny(
                "docs/audits/lot-%s.md is missing. Run the gate "
                "lot-test -> lot-review -> lot-audit before opening the PR." % lot
            )
        with open(report, encoding="utf-8") as handle:
            for line in handle:
                if line.lstrip().startswith("|") and CRITICAL_LINE.search(line):
                    if not RESOLVED_MARK.search(line):
                        deny(
                            "docs/audits/lot-%s.md still carries an unresolved "
                            "Critical finding: %s" % (lot, line.strip())
                        )

    if (gate_parameter(root, "Stack") or "").lower() == "frontend":
        integration = os.path.join(root, "docs", "audits", "lot-0-integration.md")
        if not os.path.isfile(integration):
            deny(
                "This is a frontend repo and docs/audits/lot-0-integration.md is "
                "missing: the front has never been validated against the real "
                "backend. Run the integration-check skill first."
            )


def guard_gh(segment, cwd):
    args = segment[1:]
    if len(args) < 2 or args[0] != "pr":
        return
    action, rest = args[1], args[2:]

    if action == "merge":
        deny(
            "Merging a PR is the user's decision; the agent stops after opening it "
            "(CONVENTIONS.md section 7)."
        )

    if action != "create":
        return

    base = option_value(rest, "--base", "-B")
    if base is None:
        deny(
            "`gh pr create` without --base would target the repository default "
            "branch. Pass --base %s explicitly (CONVENTIONS.md section 7)."
            % REQUIRED_PR_BASE
        )
    if base != REQUIRED_PR_BASE:
        deny(
            "PRs target `%s`, not `%s`. The promotion develop -> main is done by "
            "the user (CONVENTIONS.md section 7)." % (REQUIRED_PR_BASE, base)
        )

    guard_pr_deliverables(cwd)
    ask("Opening a PR publishes the branch for review; confirm before creating it.")


# --------------------------------------------------------------------------


def main():
    try:
        payload = json.load(sys.stdin)
    except (ValueError, OSError):
        sys.exit(0)

    if payload.get("tool_name") != "Bash":
        sys.exit(0)

    command = payload.get("tool_input", {}).get("command", "")
    if not command.strip():
        sys.exit(0)
    if "git" not in command and "gh" not in command:
        sys.exit(0)

    cwd = payload.get("cwd") or os.getcwd()

    tokens = tokenize(command)
    if tokens is None:
        ask(
            "The command could not be parsed (unbalanced quotes); confirm it manually "
            "rather than letting the guard pass it silently."
        )

    for segment in segments(tokens):
        segment = strip_assignments(segment)
        if not segment:
            continue
        name = os.path.basename(segment[0])
        if name == "cd" and len(segment) > 1:
            # `cd x && git push` must be judged against x, not the session cwd.
            cwd = segment[1] if os.path.isabs(segment[1]) else os.path.join(cwd, segment[1])
        elif name == "git":
            guard_git(segment, cwd)
        elif name == "gh":
            guard_gh(segment, cwd)

    sys.exit(0)


if __name__ == "__main__":
    main()
