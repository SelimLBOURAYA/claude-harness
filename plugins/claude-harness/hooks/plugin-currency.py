#!/usr/bin/env python3
"""Is the installed plugin the one `main` carries? (lot 20)

Claude Code loads the harness from the copy it installed under
`~/.claude/plugins/cache/<marketplace>/<plugin>/<version>`, refreshed by the
user, never from this working clone. Nothing here saw that copy's age, so a
stale plugin silently disarmed the start-of-lot gate: `lot-start` and its
confirmation hook were not installed at all, and a missing hook writes nothing
- which is also what a guard writes when it finds nothing to report. The agent
could not tell "guard satisfied" from "guard absent" (incident of 2026-09-22,
repo elya, lot 3.3).

This module answers one question for the SessionStart hook: is the installed
SHA the one `main` carries? When it is not, it prints the warning the hook puts
at the top of its state re-injection. When it cannot tell - no installed entry,
no marketplace clone, no remote, offline - it prints nothing and exits 0: the
hook must never block a session, and a guess would be worse than the silence it
replaces.

The plugin identity is read from the path of this very file, so no name is
hard-coded: `<plugins>/cache/<marketplace>/<plugin>/<version>/hooks/`.

CLI:

    plugin-currency.py [--plugin-root DIR] [--plugins-dir DIR] [--timeout SECONDS]

Exit status is always 0: the verdict is the output, not the code.

Standard library only (V6), like the other hooks.
"""

import argparse
import json
import os
import subprocess
import sys

sys.dont_write_bytecode = True  # no __pycache__ inside the plugin tree

DEFAULT_TIMEOUT = 5
CACHE_DIR = "cache"
GUARDS = "lot-start, its confirmation, the write lock, the start-of-lot reinjection"


def plugins_dir(explicit):
    """Where Claude Code keeps installed plugins and marketplaces."""
    if explicit:
        return os.path.realpath(explicit)
    # HARNESS_PLUGINS_DIR is this module's own seam: the test suite builds a
    # fixture plugin tree there, and never touches the reader's installation.
    from_env = os.environ.get("HARNESS_PLUGINS_DIR")
    if from_env:
        return os.path.realpath(from_env)
    config = os.environ.get("CLAUDE_CONFIG_DIR") or os.path.join(
        os.path.expanduser("~"), ".claude"
    )
    return os.path.join(os.path.realpath(config), "plugins")


def plugin_root(explicit):
    if explicit:
        return os.path.realpath(explicit)
    return os.path.dirname(os.path.dirname(os.path.realpath(__file__)))


def identity(root, plugins):
    """(marketplace, plugin, version, cache dir) for an installed copy.

    None when `root` is not an installed copy - a working clone of this
    repository, for instance, which is never what this check is about.
    """
    cache = os.path.join(plugins, CACHE_DIR)
    rel = os.path.relpath(root, cache)
    if rel.startswith(os.pardir + os.sep) or rel == os.pardir:
        return None
    parts = rel.split(os.sep)
    if len(parts) < 3 or not all(parts[:3]):
        return None
    return parts[0], parts[1], parts[2], os.path.join(cache, *parts[:3])


def read_json(path):
    try:
        with open(path, encoding="utf-8") as handle:
            return json.load(handle)
    except (OSError, ValueError):
        return None


def installed_entry(plugins, key, version_dir):
    """The record of one installation: the newest one of that plugin.

    Three scopes of the same plugin share one cache directory (user level,
    per-project), so the record is picked by installPath when it matches the
    copy this hook runs from, and by lastUpdated otherwise.
    """
    data = read_json(os.path.join(plugins, "installed_plugins.json")) or {}
    entries = [e for e in (data.get("plugins") or {}).get(key) or [] if isinstance(e, dict)]
    if not entries:
        return None
    for entry in entries:
        path = entry.get("installPath")
        if path and os.path.realpath(path) == version_dir:
            return entry
    return max(entries, key=lambda entry: str(entry.get("lastUpdated", "")))


def marketplace_ref(plugins, name):
    """(clone path, ref) of a marketplace, or (None, None)."""
    data = read_json(os.path.join(plugins, "known_marketplaces.json")) or {}
    entry = data.get(name)
    if not isinstance(entry, dict):
        return None, None
    source = entry.get("source") if isinstance(entry.get("source"), dict) else {}
    return entry.get("installLocation"), source.get("ref") or "main"


def remote_tip(clone, ref, timeout):
    """The SHA `origin` carries at `ref`, or None when it cannot be read."""
    if not clone or not os.path.isdir(os.path.join(clone, ".git")):
        return None
    try:
        result = subprocess.run(
            ["git", "-C", clone, "ls-remote", "origin", ref],
            capture_output=True,
            text=True,
            timeout=timeout,
        )
    except (OSError, subprocess.SubprocessError):
        return None
    if result.returncode != 0:
        return None
    for line in result.stdout.splitlines():
        fields = line.split()
        if len(fields) == 2 and fields[1].endswith("/" + ref):
            return fields[0]
    return None


def short(sha):
    return (sha or "")[:7]


def stamp(entry):
    raw = str(entry.get("lastUpdated") or entry.get("installedAt") or "")
    return raw[:10]


def warning(plugin, entry, tip):
    return (
        "⚠ The installed `%s` plugin is %s (%s, %s) while `main` is at %s. Lot guards "
        "may be missing (%s). Refresh it (`/plugin marketplace update %s`) and reopen "
        "the session before any lot work."
        % (
            plugin,
            entry.get("version") or "?",
            short(entry.get("gitCommitSha")),
            stamp(entry) or "date unknown",
            short(tip),
            GUARDS,
            plugin,
        )
    )


def check(root, plugins, timeout):
    """The warning line, or an empty string when there is nothing to say."""
    found = identity(root, plugins)
    if found is None:
        return ""
    marketplace, plugin, version, version_dir = found
    entry = installed_entry(plugins, "%s@%s" % (plugin, marketplace), version_dir)
    if not entry:
        return ""
    installed = entry.get("gitCommitSha")
    if not installed:
        return ""
    clone, ref = marketplace_ref(plugins, marketplace)
    tip = remote_tip(clone, ref, timeout)
    if not tip or tip.startswith(installed) or installed.startswith(tip):
        return ""
    return warning(plugin, entry, tip)


def main(argv):
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("--plugin-root")
    parser.add_argument("--plugins-dir")
    parser.add_argument("--timeout", type=float, default=DEFAULT_TIMEOUT)
    args = parser.parse_args(argv[1:])

    line = check(plugin_root(args.plugin_root), plugins_dir(args.plugins_dir), args.timeout)
    if line:
        print(line)
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
