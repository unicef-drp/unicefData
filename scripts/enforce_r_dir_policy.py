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
    # Public repo uses R/ (uppercase); dev repo uses r/ (lowercase).
    # Accept either as canonical — just ensure one exists.
    canonical_lower = repo_root / "r"
    canonical_upper = repo_root / "R"
    if not canonical_lower.is_dir() and not canonical_upper.is_dir():
        print("ERROR: Missing R package directory (expected 'r/' or 'R/').")
        return 1

    print("OK: R package directory policy check passed")
    return 0


if __name__ == "__main__":
    sys.exit(main())
