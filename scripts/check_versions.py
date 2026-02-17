#!/usr/bin/env python3
"""Check that modified source files in a git diff have an updated header version.

Usage: python scripts/check_versions.py <base-ref>

Compares header versions for each modified R/Python/Stata file against <base-ref>
and exits non-zero if any modified file does not have an increased version.

Adapted from wbopendata-dev/scripts/check_versions.py for trilingual support.
"""

import re
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]

# ---------------------------------------------------------------------------
# Version extraction (matches update_component_versions.py logic)
# ---------------------------------------------------------------------------

RE_ADO = re.compile(r"^\s*\*!.*?v(?:ersion)?\s*([0-9]+(?:\.[0-9]+)*)", re.IGNORECASE)
RE_PY_COMMENT = re.compile(r"^#?\s*Version:\s*([0-9]+(?:\.[0-9]+)*)", re.IGNORECASE)
RE_PY_DUNDER = re.compile(r'__version__\s*=\s*["\']([0-9]+(?:\.[0-9]+)*)')
RE_R_COMMENT = re.compile(r"^#\s*Version:\s*([0-9]+(?:\.[0-9]+)*)", re.IGNORECASE)
RE_LEGACY = re.compile(r"^\s*\*!\s*v?\s*([0-9]+)(?:\s|$)")

# File extensions we care about
TRACKED_EXTENSIONS = {".ado", ".py", ".R"}


def normalize_version(v: str) -> str:
    parts = v.split(".")
    while len(parts) < 3:
        parts.append("0")
    return ".".join(parts[:3])


def extract_version(text: str, ext: str) -> str | None:
    """Extract version from file content based on extension."""
    if text is None:
        return None

    for line in text.splitlines()[:20]:
        if ext == ".ado":
            m = RE_ADO.match(line)
            if m:
                return normalize_version(m.group(1))
        elif ext == ".py":
            m = RE_PY_DUNDER.search(line)
            if m:
                return normalize_version(m.group(1))
            m = RE_PY_COMMENT.match(line)
            if m:
                return normalize_version(m.group(1))
        elif ext == ".R":
            m = RE_R_COMMENT.match(line)
            if m:
                return normalize_version(m.group(1))

    return None


def version_tuple(v: str) -> tuple:
    return tuple(int(x) for x in v.split(".")[:3])


def git_cat(ref: str, path: str) -> str | None:
    p = subprocess.run(
        ["git", "show", f"{ref}:{path}"],
        capture_output=True, text=True, cwd=ROOT
    )
    return p.stdout if p.returncode == 0 else None


def main():
    if len(sys.argv) < 2:
        print("Usage: check_versions.py <base-ref>")
        print("Example: python scripts/check_versions.py origin/main")
        return 2

    base = sys.argv[1]

    p = subprocess.run(
        ["git", "diff", "--name-only", base, "HEAD"],
        capture_output=True, text=True, cwd=ROOT
    )
    files = [l.strip() for l in p.stdout.splitlines() if l.strip()]

    failures = []
    checked = 0

    for f in files:
        path = ROOT / f
        ext = Path(f).suffix

        if ext not in TRACKED_EXTENSIONS:
            continue
        if not path.exists():
            continue

        # Skip test files, archive, and __pycache__
        if any(skip in f for skip in ["test", "archive", "__pycache__", "examples"]):
            continue

        text_new = path.read_text(encoding="utf-8", errors="ignore")
        v_new = extract_version(text_new, ext)

        old_text = git_cat(base, f)
        v_old = extract_version(old_text, ext) if old_text else None

        # Skip files that have no version header in either old or new
        if v_old is None and v_new is None:
            continue

        checked += 1

        # Default missing to 0.0.0
        v_old = v_old or "0.0.0"
        v_new = v_new or "0.0.0"

        try:
            t_old = version_tuple(v_old)
            t_new = version_tuple(v_new)
        except ValueError:
            failures.append((f, v_old, v_new))
            continue

        if t_new <= t_old:
            failures.append((f, v_old, v_new))

    if failures:
        print(f"Version check FAILED for {len(failures)} file(s):")
        for f, old, new in failures:
            print(f"  {f}: {old} -> {new} (not bumped)")
        return 1

    print(f"All {checked} versioned file(s) have version bumps. OK.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
