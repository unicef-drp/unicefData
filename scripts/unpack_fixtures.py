#!/usr/bin/env python3
"""
unpack_fixtures.py — Extract tests/fixtures.zip to all platform directories
============================================================================

The ZIP file is the single authoritative source of truth for all test fixtures.
This script extracts it to the locations expected by each platform's test runner:

    tests/fixtures/deterministic/   ← Python + R offline data tests
    tests/fixtures/api_responses/   ← Python + R mock API tests
    tests/fixtures/xml/             ← Python + R small XML subset tests
    tests/fixtures/xml_full/        ← Full SDMX XML (for sync pipeline tests)
    tests/fixtures/yaml/            ← Python + R small YAML subset tests
    stata/qa/fixtures/              ← Stata fromfile() data tests
    stata/qa/fixtures/api/          ← Stata XML metadata tests
    stata/qa/fixtures/api/enrichment/ ← Stata enrichment pipeline tests

Auto-run:
    This script is called automatically by .githooks/post-checkout and
    .githooks/post-merge, so fixtures are always available after clone/pull.

Manual run:
    python scripts/unpack_fixtures.py           # extract if ZIP is newer
    python scripts/unpack_fixtures.py --force    # always re-extract
    python scripts/unpack_fixtures.py --check    # verify without extracting
"""

import argparse
import hashlib
import json
import sys
import zipfile
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
ZIP_PATH = ROOT / "tests" / "fixtures.zip"
STAMP_PATH = ROOT / "tests" / "fixtures" / ".unpack_stamp"

# ---------------------------------------------------------------------------
# Extraction mapping: zip_prefix → local_directory
# ---------------------------------------------------------------------------

EXTRACT_MAP = {
    # ZIP prefix              → target directory (relative to ROOT)
    "data/":                  ["tests/fixtures/deterministic", "stata/qa/fixtures"],
    "api_responses/":         ["tests/fixtures/api_responses"],
    "xml_subset/":            ["tests/fixtures/xml"],
    "xml/enrichment/":        ["tests/fixtures/xml_full/enrichment", "stata/qa/fixtures/api/enrichment"],
    "xml/":                   ["tests/fixtures/xml_full", "stata/qa/fixtures/api"],
    "yaml/":                  ["tests/fixtures/yaml"],
    "manifest.json":          ["tests/fixtures/deterministic"],
}


def zip_hash(path: Path) -> str:
    """SHA-256 of the ZIP file for change detection."""
    h = hashlib.sha256()
    with open(path, "rb") as f:
        for chunk in iter(lambda: f.read(8192), b""):
            h.update(chunk)
    return h.hexdigest()


def needs_unpack() -> bool:
    """Check if ZIP has changed since last unpack."""
    if not ZIP_PATH.exists():
        return False
    if not STAMP_PATH.exists():
        return True
    try:
        stamp_data = json.loads(STAMP_PATH.read_text(encoding="utf-8"))
        return stamp_data.get("sha256") != zip_hash(ZIP_PATH)
    except (OSError, json.JSONDecodeError, KeyError):
        return True


def find_target_dirs(zip_entry: str) -> list:
    """Given a ZIP entry path, return the target directories."""
    # Try prefixes from longest to shortest (enrichment before xml)
    for prefix in sorted(EXTRACT_MAP.keys(), key=len, reverse=True):
        if zip_entry.startswith(prefix):
            filename = zip_entry[len(prefix):]
            if not filename:  # directory entry
                continue
            targets = []
            for target_dir in EXTRACT_MAP[prefix]:
                targets.append((ROOT / target_dir, filename))
            return targets

    # Special case: manifest.json at root level
    if zip_entry == "manifest.json":
        return [(ROOT / "tests" / "fixtures" / "deterministic", "manifest.json")]

    return []


def unpack(force: bool = False):
    """Extract fixtures.zip to all target directories."""
    if not ZIP_PATH.exists():
        print(f"No fixtures.zip found at {ZIP_PATH}")
        print("Run: python scripts/generate_fixtures.py --download --pack")
        return False

    if not force and not needs_unpack():
        print("Fixtures are up to date (ZIP unchanged).")
        return True

    print(f"Unpacking {ZIP_PATH.name}...")
    extracted = 0

    with zipfile.ZipFile(ZIP_PATH, "r") as zf:
        for entry in zf.namelist():
            if entry.endswith("/"):  # skip directory entries
                continue

            targets = find_target_dirs(entry)
            if not targets:
                continue

            data = zf.read(entry)
            for target_dir, filename in targets:
                dest = target_dir / filename
                dest.parent.mkdir(parents=True, exist_ok=True)
                dest.write_bytes(data)
                extracted += 1

    # Write stamp file
    STAMP_PATH.parent.mkdir(parents=True, exist_ok=True)
    stamp = {
        "sha256": zip_hash(ZIP_PATH),
        "extracted_files": extracted,
    }
    STAMP_PATH.write_text(json.dumps(stamp, indent=2) + "\n", encoding="utf-8")

    print(f"Extracted {extracted} file copies from {ZIP_PATH.name}")
    return True


def check():
    """Verify fixtures are properly unpacked without modifying anything."""
    if not ZIP_PATH.exists():
        print("MISSING: tests/fixtures.zip")
        return False

    missing = []
    with zipfile.ZipFile(ZIP_PATH, "r") as zf:
        for entry in zf.namelist():
            if entry.endswith("/"):
                continue
            targets = find_target_dirs(entry)
            for target_dir, filename in targets:
                dest = target_dir / filename
                if not dest.exists():
                    missing.append(str(dest.relative_to(ROOT)))

    if missing:
        print(f"MISSING {len(missing)} files (run: python scripts/unpack_fixtures.py)")
        for m in missing[:10]:
            print(f"  {m}")
        if len(missing) > 10:
            print(f"  ... and {len(missing) - 10} more")
        return False

    print("OK: All fixture files present.")
    return True


def main():
    parser = argparse.ArgumentParser(description="Unpack test fixtures from ZIP")
    parser.add_argument("--force", action="store_true",
                        help="Re-extract even if ZIP is unchanged")
    parser.add_argument("--check", action="store_true",
                        help="Verify fixtures are present without extracting")
    args = parser.parse_args()

    if args.check:
        return 0 if check() else 1

    return 0 if unpack(force=args.force) else 1


if __name__ == "__main__":
    sys.exit(main())
