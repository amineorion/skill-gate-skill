#!/usr/bin/env python3
"""SKILL.md shape check.

Run from the repo root:

    python3 scripts/test/check_skill_md.py

Asserts:
  1. SKILL.md exists, starts with --- frontmatter that closes with ---,
     and the frontmatter contains `name:` and `description:`.
  2. Every markdown reference of the form (playbooks/...md) inside
     SKILL.md points to a file that actually exists on disk.

Used in CI to catch the most common "I added a playbook but forgot to
link it" / "I broke the frontmatter" failures without spinning up the
full platform integration stack.
"""

from __future__ import annotations

import os
import re
import sys


def main() -> int:
    if not os.path.exists("SKILL.md"):
        print("SKILL.md not found in cwd", file=sys.stderr)
        return 1

    src = open("SKILL.md", encoding="utf-8").read()

    if not src.startswith("---"):
        print("SKILL.md must start with --- frontmatter", file=sys.stderr)
        return 1

    parts = src.split("---", 2)
    if len(parts) < 3:
        print("SKILL.md frontmatter not closed with ---", file=sys.stderr)
        return 1

    frontmatter = parts[1]
    for required in ("name:", "description:"):
        if required not in frontmatter:
            print(f"SKILL.md frontmatter missing required field: {required}", file=sys.stderr)
            return 1

    refs = set(re.findall(r"\(([^)]+\.md)\)", src))
    missing = [r for r in refs if r.startswith("playbooks/") and not os.path.exists(r)]
    if missing:
        print("SKILL.md references missing playbooks:", ", ".join(missing), file=sys.stderr)
        return 1

    print(f"OK: frontmatter valid · {len(refs)} markdown refs, all on disk")
    return 0


if __name__ == "__main__":
    sys.exit(main())
