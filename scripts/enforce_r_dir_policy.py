#!/usr/bin/env python3
"""Enforce canonical R package directory policy.

Policy:
- Canonical package directory must be `r/`.
- Uppercase `R/` at repo root is disallowed.
"""

from __future__ import annotations

import subprocess
import sys
from pathlib import Path


def tracked_paths() -> list[str]:
    result = subprocess.run(
        ["git", "ls-files"],
        check=True,
        capture_output=True,
        text=True,
    )
    return [line.strip() for line in result.stdout.splitlines() if line.strip()]


def main() -> int:
    repo_root = Path(__file__).resolve().parent.parent
    canonical_dir = repo_root / "r"
    if not canonical_dir.is_dir():
        print("ERROR: Missing canonical package directory 'r/'.")
        return 1

    offending = [path for path in tracked_paths() if path == "R" or path.startswith("R/")]

    if offending:
        print("ERROR: Disallowed uppercase root directory 'R/' detected.")
        for path in offending[:20]:
            print(f"- Tracked path: {path}")
        if len(offending) > 20:
            print(f"- ... and {len(offending) - 20} more")
        print("Use canonical lowercase directory: r/")
        return 1

    print("OK: r/R policy check passed (canonical: r/)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
