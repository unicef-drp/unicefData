#!/usr/bin/env python3
"""Prepare R test fixtures for CI.

Extracts deterministic CSV fixtures from `stata/qa/fixtures.zip` into the R
package test fixture directory expected by testthat.

API response fixtures are maintained separately under the repo-level
`tests/fixtures/api_responses` tree and are not copied into the package source.
"""

from __future__ import annotations

import zipfile
import shutil
from pathlib import Path


REQUIRED_DETERMINISTIC_FILES = [
    "CME_MRY0T4_USA_2020_pinning.csv",
    "CME_MRY0T4_USA_2015_2023.csv",
    "CME_MRY0T4_USA_BRA_2020.csv",
    "CME_MRY0T4_multi_2018_2023.csv",
    "CME_MRY0T4_BRA_sex_2020.csv",
    "IM_MCV1_USA_BRA_2015_2023.csv",
]


def main() -> int:
    repo_root = Path(__file__).resolve().parent.parent
    zip_path = repo_root / "stata" / "qa" / "fixtures.zip"
    deterministic_dir = repo_root / "r" / "tests" / "fixtures" / "deterministic"

    if not zip_path.exists():
        raise FileNotFoundError(f"Missing fixture archive: {zip_path}")

    deterministic_dir.mkdir(parents=True, exist_ok=True)

    stale_api_dir = deterministic_dir / "api"
    if stale_api_dir.exists():
        shutil.rmtree(stale_api_dir)

    for stale_file in deterministic_dir.glob("api\\*"):
        if stale_file.is_file():
            stale_file.unlink()

    extracted = 0
    with zipfile.ZipFile(zip_path, "r") as archive:
        for member in archive.namelist():
            if member.endswith("/"):
                continue

            normalized_member = member.replace("\\", "/")
            if normalized_member.startswith("api/"):
                continue

            source = archive.open(member)
            target = deterministic_dir / normalized_member

            target.parent.mkdir(parents=True, exist_ok=True)
            with source, target.open("wb") as stream:
                stream.write(source.read())
            extracted += 1

    missing = [name for name in REQUIRED_DETERMINISTIC_FILES if not (deterministic_dir / name).exists()]
    if missing:
        raise RuntimeError(f"Missing required deterministic fixtures after extraction: {missing}")

    print(f"Extracted {extracted} fixture files from {zip_path}")
    print(f"Deterministic fixtures: {deterministic_dir}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
