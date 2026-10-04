#!/usr/bin/env python3
"""Is the installed plugin the version `main` declares?

Claude Code loads the harness from the copy it installed under
`~/.claude/plugins/cache/<marketplace>/<plugin>/<version>`, never from a working
clone, and a hook that was never installed writes nothing. This module answers
one question for the SessionStart hook: is the version of the copy this file
runs from the version that the marketplace clone declares for the plugin?

Only versions are compared (lot 24). The version changes with every change under
`plugins/` (the `plugin-version` job of the harness CI), Claude Code names the
cache directory after it, and its auto-update, which keeps the marketplace clone
on `main`, compares nothing else.

When it cannot tell - not an installed copy, no marketplace clone, no version
declared - it prints nothing: the hook must never block a session.

The plugin identity is read from the path of this very file, so no name is
hard-coded: `<plugins>/cache/<marketplace>/<plugin>/<version>/hooks/`.

CLI:

    plugin-currency.py [--plugin-root DIR] [--plugins-dir DIR]
    plugin-currency.py --installed-version [--plugin-root DIR] [--plugins-dir DIR]

Exit status is always 0: the verdict is the output, not the code.

--installed-version prints the version of the installed copy this file runs
from, and nothing when it is not an installed copy: the `Harness ref` of the
review and audit reports.

Standard library only (V6), like the other hooks.
"""

import argparse
import json
import os
import sys

sys.dont_write_bytecode = True  # no __pycache__ inside the plugin tree

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
    """(marketplace, plugin, version) of an installed copy.

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
    return parts[0], parts[1], parts[2]


def read_json(path):
    try:
        with open(path, encoding="utf-8") as handle:
            return json.load(handle)
    except (OSError, ValueError):
        return None


def declared_version(plugins, marketplace, plugin):
    """The version the marketplace clone declares for `plugin`, or None."""
    known = read_json(os.path.join(plugins, "known_marketplaces.json")) or {}
    entry = known.get(marketplace)
    if not isinstance(entry, dict) or not entry.get("installLocation"):
        return None
    manifest = read_json(
        os.path.join(entry["installLocation"], ".claude-plugin", "marketplace.json")
    ) or {}
    for listed in manifest.get("plugins") or []:
        if isinstance(listed, dict) and listed.get("name") == plugin:
            return str(listed.get("version") or "") or None
    return None


def warning(marketplace, plugin, installed, declared):
    return (
        "⚠ The installed `%s` plugin is %s while `main` declares %s. Lot guards "
        "may be missing (%s). Before any lot work, run `claude plugin update "
        "%s@%s --scope user`, then `--scope project` in each project installing it, "
        "and ask the user to reopen the session (CONVENTIONS.md PLUG-1)."
        % (plugin, installed, declared, GUARDS, plugin, marketplace)
    )


def installed_version(root, plugins):
    """Version of the installed copy at `root`, or an empty string."""
    found = identity(root, plugins)
    return found[2] if found else ""


def check(root, plugins):
    """The warning line, or an empty string when there is nothing to say."""
    found = identity(root, plugins)
    if found is None:
        return ""
    marketplace, plugin, installed = found
    declared = declared_version(plugins, marketplace, plugin)
    if not declared or declared == installed:
        return ""
    return warning(marketplace, plugin, installed, declared)


def main(argv):
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("--plugin-root")
    parser.add_argument("--plugins-dir")
    parser.add_argument("--installed-version", action="store_true")
    args = parser.parse_args(argv[1:])

    root = plugin_root(args.plugin_root)
    plugins = plugins_dir(args.plugins_dir)
    line = installed_version(root, plugins) if args.installed_version else check(root, plugins)
    if line:
        print(line)
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
