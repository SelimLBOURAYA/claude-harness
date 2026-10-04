#!/usr/bin/env python3
"""Generates the deepseek rules card from CONVENTIONS.md (lot 24).

The card, `plugins/claude-harness/rules/deepseek.json`, chooses rules by
identifier only; their text is the text of CONVENTIONS.md, one place for every
rule. The SessionStart hook renders the card as `- <id>: <rule>` lines, inside
its own character cap, so the rendering must leave room for the rest of the
hook output: the table budget and a fixed allowance for the repository state.

Usage:

    deepseek-card.py            rewrite the card's rule texts from CONVENTIONS.md
    deepseek-card.py --check    exit 1 when the committed card differs from the
                                generation, names an unknown rule, or exceeds
                                its budget

Standard library only.
"""

import argparse
import json
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.realpath(__file__))))
CONVENTIONS = os.path.join(ROOT, "CONVENTIONS.md")
CARD = os.path.join(ROOT, "plugins", "claude-harness", "rules", "deepseek.json")
HOOK = os.path.join(ROOT, "plugins", "claude-harness", "hooks", "session-context.sh")

RULE = re.compile(r"^- \*\*([A-Z]+-[0-9]+)\*\* (.+)$", re.M)
# What the hook prints besides the table and the card: header, plugin warning,
# repository state, last commits, the "before any write" steps.
STATE_ALLOWANCE = 2000


def rules():
    with open(CONVENTIONS, encoding="utf-8") as handle:
        return dict(RULE.findall(handle.read()))


def budget():
    with open(HOOK, encoding="utf-8") as handle:
        text = handle.read()
    caps = dict(re.findall(r"^(CAP|TABLE_CAP)=([0-9]+)$", text, re.M))
    return int(caps["CAP"]) - int(caps["TABLE_CAP"]) - STATE_ALLOWANCE


def render(card):
    return "\n".join("- %s: %s" % (rule["id"], rule["rule"]) for rule in card["rules"])


def generate(card, known):
    unknown = [rule["id"] for rule in card["rules"] if rule["id"] not in known]
    if unknown:
        raise KeyError(", ".join(unknown))
    out = dict(card)
    out["rules"] = [{"id": rule["id"], "rule": known[rule["id"]]} for rule in card["rules"]]
    return out


def dump(card):
    return json.dumps(card, indent=2, ensure_ascii=False) + "\n"


def main(argv):
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("--check", action="store_true")
    args = parser.parse_args(argv[1:])

    with open(CARD, encoding="utf-8") as handle:
        committed = handle.read()
    card = json.loads(committed)
    try:
        generated = generate(card, rules())
    except KeyError as error:
        print("unknown rule in the card: %s" % error, file=sys.stderr)
        return 1

    size, limit = len(render(generated)), budget()
    if size > limit:
        print("the card renders %d characters, over its budget of %d" % (size, limit), file=sys.stderr)
        return 1
    if args.check:
        if dump(generated) != committed:
            print("the card differs from CONVENTIONS.md: run %s" % os.path.relpath(__file__, ROOT),
                  file=sys.stderr)
            return 1
        return 0
    with open(CARD, "w", encoding="utf-8") as handle:
        handle.write(dump(generated))
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
