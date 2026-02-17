#!/usr/bin/env python3
"""Generate a unified __COMPONENT_VERSIONS.yaml for the unicefData trilingual package.

Scans R, Python, and Stata source files for version headers and writes a single
mapping file organized by platform.

Usage:
    python scripts/update_component_versions.py

Output: doc/__COMPONENT_VERSIONS.yaml (written directly, not to stdout)

Adapted from wbopendata-dev/scripts/update_component_versions.py
"""

import re
import sys
from pathlib import Path
from datetime import date

ROOT = Path(__file__).resolve().parents[1]
OUTPUT = ROOT / "doc" / "__COMPONENT_VERSIONS.yaml"

# ---------------------------------------------------------------------------
# File patterns to scan, by platform
# ---------------------------------------------------------------------------
PLATFORM_GLOBS = {
    "stata": {
        "base": ROOT / "stata" / "src",
        "patterns": ["**/*.ado"],
        "exclude": ["_archive", "__archive", "_tmp"],
    },
    "python": {
        "base": ROOT / "python" / "unicefdata",
        "patterns": ["**/*.py"],
        "exclude": ["__pycache__"],
    },
    "r": {
        "base": ROOT / "R",
        "patterns": ["**/*.R"],
        "exclude": ["tests", "examples"],
    },
}

# Also scan package-level files
PACKAGE_FILES = [
    ("all", ROOT / "DESCRIPTION"),
    ("all", ROOT / "CITATION.cff"),
    ("all", ROOT / "CHANGELOG.md"),
    ("python", ROOT / "python" / "pyproject.toml"),
    ("python", ROOT / "python" / "unicefdata" / "__init__.py"),
]

# Also scan YAML metadata files
YAML_DIRS = [
    ("stata", ROOT / "stata" / "src" / "_"),
    ("r", ROOT / "R"),
    ("all", ROOT),
]

# ---------------------------------------------------------------------------
# Version extraction regexes
# ---------------------------------------------------------------------------

# Stata: *! v 2.2.0 or *! version 1.3.0
RE_ADO = re.compile(r"^\s*\*!.*?v(?:ersion)?\s*([0-9]+(?:\.[0-9]+)*)", re.IGNORECASE)

# Python: # Version: 2.1.0 or __version__ = "2.1.1"
RE_PY_COMMENT = re.compile(r"^#?\s*Version:\s*([0-9]+(?:\.[0-9]+)*)", re.IGNORECASE)
RE_PY_DUNDER = re.compile(r'__version__\s*=\s*["\']([0-9]+(?:\.[0-9]+)*)')

# R: # Version: 2.1.0
RE_R_COMMENT = re.compile(r"^#\s*Version:\s*([0-9]+(?:\.[0-9]+)*)", re.IGNORECASE)

# YAML: version: "2.0.0" or version: 2.0.0 (but NOT cff-version:, metadata_version:, etc.)
RE_YAML_VER = re.compile(r"^version:\s*['\"]?([0-9]+(?:\.[0-9]+)*)", re.IGNORECASE)

# DESCRIPTION: Version: 2.1.0
RE_DESC_VER = re.compile(r"^Version:\s*([0-9]+(?:\.[0-9]+)*)", re.IGNORECASE)

# pyproject.toml: version = "2.1.1"
RE_TOML_VER = re.compile(r'^version\s*=\s*"([0-9]+(?:\.[0-9]+)*)"')

# Generic legacy: *! v 16.3 (normalize to 16.3.0)
RE_LEGACY = re.compile(r"^\s*\*!\s*v?\s*([0-9]+)(?:\s|$)")


def normalize_version(v: str) -> str:
    """Normalize to at least MAJOR.MINOR.PATCH format."""
    parts = v.split(".")
    while len(parts) < 3:
        parts.append("0")
    return ".".join(parts[:3])


def extract_version(path: Path, platform: str) -> str | None:
    """Extract version string from a file's first 20 lines."""
    try:
        text = path.read_text(encoding="utf-8", errors="ignore")
    except Exception:
        return None

    lines = text.splitlines()[:20]

    for line in lines:
        # Platform-specific patterns first
        if platform == "stata":
            m = RE_ADO.match(line)
            if m:
                return normalize_version(m.group(1))

        elif platform == "python":
            m = RE_PY_DUNDER.search(line)
            if m:
                return normalize_version(m.group(1))
            m = RE_PY_COMMENT.match(line)
            if m:
                return normalize_version(m.group(1))

        elif platform == "r":
            m = RE_R_COMMENT.match(line)
            if m:
                return normalize_version(m.group(1))

        # Generic patterns
        m = RE_DESC_VER.match(line)
        if m:
            return normalize_version(m.group(1))

        m = RE_TOML_VER.match(line)
        if m:
            return normalize_version(m.group(1))

        m = RE_YAML_VER.match(line)
        if m:
            return normalize_version(m.group(1))

    return None


def should_exclude(path: Path, excludes: list) -> bool:
    """Check if a path should be excluded."""
    parts = path.parts
    return any(ex in parts for ex in excludes)


def scan_platform(name: str, config: dict) -> dict:
    """Scan a platform's source files for version headers."""
    results = {}
    base = config["base"]
    if not base.exists():
        return results

    for pattern in config["patterns"]:
        for f in sorted(base.glob(pattern)):
            if should_exclude(f, config.get("exclude", [])):
                continue
            v = extract_version(f, name)
            if v:
                rel = f.relative_to(ROOT).as_posix()
                results[rel] = v
    return results


def scan_yaml_files() -> dict:
    """Scan YAML metadata files for version headers."""
    results = {}
    for _, base_dir in YAML_DIRS:
        if not base_dir.exists():
            continue
        for f in sorted(base_dir.glob("*.yaml")):
            v = extract_version(f, "yaml")
            if v:
                rel = f.relative_to(ROOT).as_posix()
                results[rel] = v
    return results


def main():
    output_lines = []
    output_lines.append("# Auto-generated component versions for unicefData")
    output_lines.append(f"# Generated: {date.today().isoformat()}")
    output_lines.append(f"# Generator: scripts/update_component_versions.py")
    output_lines.append("")

    # Package-level versions
    output_lines.append("# ---- Package-level versions ----")
    output_lines.append("package:")
    for platform, path in PACKAGE_FILES:
        if path.exists():
            v = extract_version(path, platform)
            if v:
                rel = path.relative_to(ROOT).as_posix()
                output_lines.append(f"  {rel}: {v}")
    output_lines.append("")

    # Per-platform component versions
    for platform_name, config in PLATFORM_GLOBS.items():
        results = scan_platform(platform_name, config)
        if results:
            output_lines.append(f"# ---- {platform_name.upper()} components ----")
            output_lines.append(f"{platform_name}:")
            for path, ver in sorted(results.items()):
                output_lines.append(f"  {path}: {ver}")
            output_lines.append("")

    # YAML metadata files
    yaml_results = scan_yaml_files()
    if yaml_results:
        output_lines.append("# ---- YAML metadata ----")
        output_lines.append("yaml:")
        for path, ver in sorted(yaml_results.items()):
            output_lines.append(f"  {path}: {ver}")
        output_lines.append("")

    # Write output
    content = "\n".join(output_lines) + "\n"
    OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    OUTPUT.write_text(content, encoding="utf-8")
    print(f"Written: {OUTPUT.relative_to(ROOT)}")

    # Summary
    total = sum(1 for line in output_lines if ": " in line and not line.startswith("#"))
    print(f"Total components tracked: {total}")


if __name__ == "__main__":
    main()
