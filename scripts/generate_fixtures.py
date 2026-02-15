#!/usr/bin/env python3
"""
generate_fixtures.py — Download and pack all test fixtures for unicefData
=========================================================================

Downloads raw SDMX API responses (CSV data + XML metadata) from the UNICEF
Data Warehouse, then packs everything into a single authoritative ZIP file.

The ZIP is the single source of truth, committed to the repo. On clone,
`scripts/unpack_fixtures.py` extracts it to the correct platform-specific
locations (see below).

Workflow:
    1. python scripts/generate_fixtures.py --download   # fetch from live API
    2. python scripts/generate_fixtures.py --pack        # create fixtures.zip
    3. git add tests/fixtures.zip && git commit          # commit the ZIP
    4. (on clone) python scripts/unpack_fixtures.py      # auto-extract

ZIP structure:
    fixtures.zip/
    ├── data/               10 CSV data fixtures (DET, EXT, REGR)
    ├── baselines/           2 regression baseline CSVs
    ├── api_responses/       6 small mock CSVs + 1 XML
    ├── xml/                10 full SDMX XML metadata files
    ├── xml/enrichment/      2 YAML + 5 serieskeys XML
    ├── yaml/                4 small YAML test subsets
    └── manifest.json        provenance metadata

Unpack destinations:
    ZIP path            → tests/fixtures/...        + stata/qa/fixtures/...
    data/*              → deterministic/*             *.csv (flat copy)
    baselines/*         → deterministic/*             *.csv (flat copy)
    api_responses/*     → api_responses/*             (not copied)
    xml/*               → xml_full/*                  api/*
    xml/enrichment/*    → xml_full/enrichment/*        api/enrichment/*
    yaml/*              → yaml/*                      (not copied)
    manifest.json       → deterministic/              manifest.json

Usage:
    python scripts/generate_fixtures.py --download          # fetch all from API
    python scripts/generate_fixtures.py --download --data    # data CSVs only
    python scripts/generate_fixtures.py --download --xml     # XML metadata only
    python scripts/generate_fixtures.py --pack               # pack into ZIP
    python scripts/generate_fixtures.py --download --pack    # fetch + pack
    python scripts/generate_fixtures.py --dry-run --download # preview URLs
"""

import argparse
import json
import logging
import os
import sys
import time
import zipfile
from pathlib import Path
from urllib.error import HTTPError, URLError
from urllib.request import Request, urlopen

# ---------------------------------------------------------------------------
# Paths
# ---------------------------------------------------------------------------

SCRIPT_DIR = Path(__file__).resolve().parent
ROOT = SCRIPT_DIR.parent  # unicefData-dev/

# Staging directory where downloads land before packing
STAGING = ROOT / "tests" / "fixtures" / "_staging"

# Output ZIP (authoritative source, committed to repo)
ZIP_PATH = ROOT / "tests" / "fixtures.zip"

# SDMX base URL
SDMX_BASE = "https://sdmx.data.unicef.org/ws/public/sdmxapi/rest"

# Retry settings
MAX_RETRIES = 3
RETRY_DELAY = 5
DEFAULT_TIMEOUT = 120

logger = logging.getLogger("fixtures")

# ---------------------------------------------------------------------------
# Fixture definitions: (subdir_in_zip, filename, url, description)
# ---------------------------------------------------------------------------

DATA_FIXTURES = [
    ("data", "CME_MRY0T4_USA_BRA_2020.csv",
     f"{SDMX_BASE}/data/UNICEF,CME,1.0/USA+BRA.CME_MRY0T4.._T._T._T?format=csv&startPeriod=2020&endPeriod=2020",
     "DET-01/03: Under-5 mortality, USA+BRA, 2020"),

    ("data", "CME_MRY0T4_USA_2020_pinning.csv",
     f"{SDMX_BASE}/data/UNICEF,CME,1.0/USA.CME_MRY0T4.._T._T._T?format=csv&startPeriod=2020&endPeriod=2020",
     "DET-02: Value pinning, USA U5MR 2020"),

    ("data", "CME_MRY0T4_USA_2015_2023.csv",
     f"{SDMX_BASE}/data/UNICEF,CME,1.0/USA.CME_MRY0T4.._T._T._T?format=csv&startPeriod=2015&endPeriod=2023",
     "DET-04: Time series, USA, 2015-2023"),

    ("data", "CME_MRY0T4_BRA_sex_2020.csv",
     f"{SDMX_BASE}/data/UNICEF,CME,1.0/BRA.CME_MRY0T4..._T._T?format=csv&startPeriod=2020&endPeriod=2020",
     "DET-05: Sex disaggregation, BRA, 2020"),

    ("data", "CME_multi_USA_2020.csv",
     f"{SDMX_BASE}/data/UNICEF,CME,1.0/USA.CME_MRY0T4+CME_MRM0+CME_MRY0+CME_TMY0T4+CME_TMM0.._T._T._T?format=csv&startPeriod=2020&endPeriod=2020",
     "DET-07: Multiple CME indicators, USA, 2020"),

    ("data", "CME_MRY0T4_USA_nofilter_2020.csv",
     f"{SDMX_BASE}/data/UNICEF,CME,1.0/USA.CME_MRY0T4?format=csv&startPeriod=2020&endPeriod=2020",
     "DET-08: Nofilter (all disaggregations), USA, 2020"),

    ("data", "CME_MRY0T4_BRA_1990_2023.csv",
     f"{SDMX_BASE}/data/UNICEF,CME,1.0/BRA.CME_MRY0T4.._T._T._T?format=csv&startPeriod=1990&endPeriod=2023",
     "DET-09: Long time series, BRA, 1990-2023"),

    ("data", "CME_MRY0T4_multi_2018_2023.csv",
     f"{SDMX_BASE}/data/UNICEF,CME,1.0/USA+BRA+IND+NGA+ETH.CME_MRY0T4.._T._T._T?format=csv&startPeriod=2018&endPeriod=2023",
     "DET-10: Multi-country time series, 5 countries, 2018-2023"),

    ("data", "CME_MRY0T4_all_2020.csv",
     f"{SDMX_BASE}/data/UNICEF,CME,1.0/.CME_MRY0T4.._T._T._T?format=csv&startPeriod=2020&endPeriod=2020",
     "DET-01/EXT-03: Under-5 mortality, all countries, 2020"),

    ("data", "IM_MCV1_USA_BRA_2015_2023.csv",
     f"{SDMX_BASE}/data/UNICEF,IMMUNISATION,1.0/USA+BRA.IM_MCV1?format=csv&startPeriod=2015&endPeriod=2023",
     "DET-11: MCV1 vaccination, USA+BRA, 2015-2023 (cross-dataflow)"),
]

# Regression baselines are NOT auto-downloaded — they are manually curated
# snapshots. Include them in the ZIP but never overwrite from the API.
BASELINE_FILES = [
    "snap_mortality_baseline.csv",
    "snap_vaccination_baseline.csv",
]

XML_METADATA_FIXTURES = [
    ("xml", "dataflows.xml",
     f"{SDMX_BASE}/dataflow/UNICEF?references=none&detail=full",
     "Dataflow catalog (69 dataflows)"),

    ("xml", "dataflow_CME_dsd.xml",
     f"{SDMX_BASE}/dataflow/UNICEF/CME/1.0?references=all",
     "CME data structure definition"),

    ("xml", "codelist_CL_UNICEF_INDICATOR.xml",
     f"{SDMX_BASE}/codelist/UNICEF/CL_UNICEF_INDICATOR/latest",
     "Indicator codelist (730+ indicators)"),

    ("xml", "codelist_CL_COUNTRY.xml",
     f"{SDMX_BASE}/codelist/UNICEF/CL_COUNTRY/latest",
     "Country codelist (264 countries)"),

    ("xml", "codelist_CL_WORLD_REGIONS.xml",
     f"{SDMX_BASE}/codelist/UNICEF/CL_WORLD_REGIONS/latest",
     "World regions codelist"),

    ("xml", "codelist_CL_AGE.xml",
     f"{SDMX_BASE}/codelist/UNICEF/CL_AGE/latest",
     "Age group codelist"),

    ("xml", "codelist_CL_WEALTH_QUINTILE.xml",
     f"{SDMX_BASE}/codelist/UNICEF/CL_WEALTH_QUINTILE/latest",
     "Wealth quintile codelist"),

    ("xml", "codelist_CL_RESIDENCE.xml",
     f"{SDMX_BASE}/codelist/UNICEF/CL_RESIDENCE/latest",
     "Residence type codelist"),

    ("xml", "codelist_CL_UNIT_MEASURE.xml",
     f"{SDMX_BASE}/codelist/UNICEF/CL_UNIT_MEASURE/latest",
     "Unit of measure codelist"),

    ("xml", "codelist_CL_OBS_STATUS.xml",
     f"{SDMX_BASE}/codelist/UNICEF/CL_OBS_STATUS/latest",
     "Observation status codelist"),
]

XML_ENRICHMENT_FIXTURES = [
    ("xml/enrichment/serieskeys", "CME.xml",
     f"{SDMX_BASE}/data/UNICEF,CME,1.0/all?format=sdmx-compact-2.1&detail=serieskeysonly",
     "CME serieskeys (34 indicators)"),

    ("xml/enrichment/serieskeys", "ECD.xml",
     f"{SDMX_BASE}/data/UNICEF,ECD,1.0/all?format=sdmx-compact-2.1&detail=serieskeysonly",
     "ECD serieskeys (6 indicators)"),

    ("xml/enrichment/serieskeys", "EDUCATION.xml",
     f"{SDMX_BASE}/data/UNICEF,EDUCATION,1.0/all?format=sdmx-compact-2.1&detail=serieskeysonly",
     "EDUCATION serieskeys (21 indicators)"),

    ("xml/enrichment/serieskeys", "HIV_AIDS.xml",
     f"{SDMX_BASE}/data/UNICEF,HIV_AIDS,1.0/all?format=sdmx-compact-2.1&detail=serieskeysonly",
     "HIV_AIDS serieskeys (25 indicators)"),

    ("xml/enrichment/serieskeys", "IMMUNISATION.xml",
     f"{SDMX_BASE}/data/UNICEF,IMMUNISATION,1.0/all?format=sdmx-compact-2.1&detail=serieskeysonly",
     "IMMUNISATION serieskeys (18 indicators)"),
]

# ---------------------------------------------------------------------------
# Download helpers
# ---------------------------------------------------------------------------

def download_file(url: str, dest: Path, description: str, *,
                  timeout: int = DEFAULT_TIMEOUT, dry_run: bool = False,
                  force: bool = False) -> bool:
    if dry_run:
        logger.info(f"  [DRY-RUN] {dest.name}  <--  {url}")
        return True

    if dest.exists() and not force:
        logger.info(f"  [SKIP] {dest.name} ({dest.stat().st_size:,} bytes)")
        return True

    for attempt in range(1, MAX_RETRIES + 1):
        try:
            logger.info(f"  [{attempt}/{MAX_RETRIES}] {dest.name}...")
            req = Request(url, headers={
                "User-Agent": "unicefData-fixtures/1.0",
                "Accept": "*/*",
            })
            with urlopen(req, timeout=timeout) as resp:
                data = resp.read()
            dest.parent.mkdir(parents=True, exist_ok=True)
            dest.write_bytes(data)
            logger.info(f"  [OK] {dest.name} ({len(data):,} bytes)")
            return True
        except HTTPError as e:
            if e.code == 404:
                logger.error(f"  [404] {dest.name}: {url}")
                return False
            if e.code in (429, 503):
                time.sleep(RETRY_DELAY * attempt)
            elif attempt == MAX_RETRIES:
                logger.error(f"  [FAIL] {dest.name} after {MAX_RETRIES} attempts")
                return False
            else:
                time.sleep(RETRY_DELAY)
        except (URLError, Exception) as e:
            if attempt == MAX_RETRIES:
                logger.error(f"  [FAIL] {dest.name}: {e}")
                return False
            time.sleep(RETRY_DELAY * attempt)
    return False


def download_set(fixtures, label, *, timeout, dry_run, force):
    logger.info(f"\n{'='*60}\n {label}\n{'='*60}")
    ok = fail = 0
    for subdir, filename, url, desc in fixtures:
        logger.info(f"  {desc}")
        dest = STAGING / subdir / filename
        if download_file(url, dest, desc, timeout=timeout, dry_run=dry_run, force=force):
            ok += 1
        else:
            fail += 1
        if not dry_run:
            time.sleep(0.5)
    logger.info(f"  -> {ok} OK, {fail} FAILED")
    return ok, fail


# ---------------------------------------------------------------------------
# Pack: staging → ZIP
# ---------------------------------------------------------------------------

def pack_fixtures():
    """Pack all fixture files into tests/fixtures.zip."""

    # Collect files from multiple sources
    sources = {}  # zip_path -> local_path

    # 1. Staging directory (downloaded fixtures)
    if STAGING.exists():
        for f in sorted(STAGING.rglob("*")):
            if f.is_file():
                zip_path = f.relative_to(STAGING).as_posix()
                sources[zip_path] = f

    # 2. Data CSVs — fallback from existing locations when staging is empty
    stata_fixtures = ROOT / "stata" / "qa" / "fixtures"
    det_dir = ROOT / "tests" / "fixtures" / "deterministic"
    data_names = [fname for _, fname, _, _ in DATA_FIXTURES]
    data_names.extend(BASELINE_FILES)
    for name in data_names:
        zip_key = f"data/{name}"
        if zip_key in sources:
            continue  # staging already has it
        # Try deterministic dir first, then Stata fixtures
        for candidate in [det_dir / name, stata_fixtures / name]:
            if candidate.exists():
                sources[zip_key] = candidate
                break

    # 3. Full XML metadata — fallback from Stata api/ directory
    stata_api = stata_fixtures / "api"
    for _, fname, _, _ in XML_METADATA_FIXTURES:
        zip_key = f"xml/{fname}"
        if zip_key in sources:
            continue
        local = stata_api / fname
        if local.exists():
            sources[zip_key] = local

    # 4. Enrichment serieskeys XML — fallback from Stata
    for subdir, fname, _, _ in XML_ENRICHMENT_FIXTURES:
        zip_key = f"{subdir}/{fname}"
        if zip_key in sources:
            continue
        local = stata_fixtures / "api" / "enrichment" / "serieskeys" / fname
        if local.exists():
            sources[zip_key] = local

    # 5. Enrichment YAML intermediates (derived, not downloaded)
    enrichment_dir = stata_fixtures / "api" / "enrichment"
    for yaml_name in ["_indicator_dataflow_map.yaml",
                      "_unicefdata_dataflow_metadata.yaml"]:
        local = enrichment_dir / yaml_name
        if local.exists():
            sources[f"xml/enrichment/{yaml_name}"] = local

    # 6. Small API response fixtures (tests/fixtures/api_responses/)
    api_resp_dir = ROOT / "tests" / "fixtures" / "api_responses"
    if api_resp_dir.exists():
        for f in sorted(api_resp_dir.iterdir()):
            if f.is_file():
                sources[f"api_responses/{f.name}"] = f

    # 7. Small YAML test subsets (tests/fixtures/yaml/)
    yaml_dir = ROOT / "tests" / "fixtures" / "yaml"
    if yaml_dir.exists():
        for f in sorted(yaml_dir.iterdir()):
            if f.is_file():
                sources[f"yaml/{f.name}"] = f

    # 8. Small XML test subsets (tests/fixtures/xml/)
    xml_subset_dir = ROOT / "tests" / "fixtures" / "xml"
    if xml_subset_dir.exists():
        for f in sorted(xml_subset_dir.iterdir()):
            if f.is_file():
                sources[f"xml_subset/{f.name}"] = f

    if not sources:
        logger.error("No fixture files found to pack.")
        return False

    # Build manifest
    manifest = {
        "generated_at": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime()),
        "generator": "scripts/generate_fixtures.py",
        "snapshot_date": time.strftime("%Y-%m-%d"),
        "sdmx_base_url": SDMX_BASE,
        "files": {},
    }

    all_fixtures = DATA_FIXTURES + XML_METADATA_FIXTURES + XML_ENRICHMENT_FIXTURES
    url_map = {f"{subdir}/{fname}": (url, desc)
               for subdir, fname, url, desc in all_fixtures}

    for zip_path, local_path in sorted(sources.items()):
        entry = {"size_bytes": local_path.stat().st_size}
        if zip_path in url_map:
            entry["url"] = url_map[zip_path][0]
            entry["description"] = url_map[zip_path][1]
        manifest["files"][zip_path] = entry

    # Write manifest to staging
    manifest_path = STAGING / "manifest.json"
    manifest_path.parent.mkdir(parents=True, exist_ok=True)
    manifest_path.write_text(
        json.dumps(manifest, indent=2, ensure_ascii=False) + "\n",
        encoding="utf-8",
    )
    sources["manifest.json"] = manifest_path

    # Create ZIP
    ZIP_PATH.parent.mkdir(parents=True, exist_ok=True)
    with zipfile.ZipFile(ZIP_PATH, "w", zipfile.ZIP_DEFLATED) as zf:
        for zip_path, local_path in sorted(sources.items()):
            zf.write(local_path, zip_path)

    total = len(sources)
    size_mb = ZIP_PATH.stat().st_size / (1024 * 1024)
    logger.info(f"\nPacked {total} files into {ZIP_PATH.name} ({size_mb:.1f} MB)")
    return True


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

def main():
    parser = argparse.ArgumentParser(
        description="Generate and pack test fixtures for unicefData",
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )
    parser.add_argument("--download", action="store_true",
                        help="Download fixtures from live SDMX API")
    parser.add_argument("--data", action="store_true",
                        help="Download only CSV data fixtures")
    parser.add_argument("--xml", action="store_true",
                        help="Download only XML metadata fixtures")
    parser.add_argument("--pack", action="store_true",
                        help="Pack fixtures into tests/fixtures.zip")
    parser.add_argument("--force", action="store_true",
                        help="Re-download even if file exists")
    parser.add_argument("--dry-run", action="store_true",
                        help="Show what would be downloaded")
    parser.add_argument("--timeout", type=int, default=DEFAULT_TIMEOUT,
                        help=f"HTTP timeout (default: {DEFAULT_TIMEOUT}s)")

    args = parser.parse_args()

    if not (args.download or args.pack):
        parser.print_help()
        return 0

    logging.basicConfig(level=logging.INFO, format="%(message)s",
                        handlers=[logging.StreamHandler(sys.stdout)])

    total_ok = total_fail = 0

    if args.download:
        download_all = not (args.data or args.xml)

        if download_all or args.data:
            ok, fail = download_set(
                DATA_FIXTURES,
                "CSV data fixtures (DET, EXT, REGR)",
                timeout=args.timeout, dry_run=args.dry_run, force=args.force,
            )
            total_ok += ok
            total_fail += fail

        if download_all or args.xml:
            ok, fail = download_set(
                XML_METADATA_FIXTURES,
                "XML metadata fixtures (codelists, dataflows)",
                timeout=args.timeout, dry_run=args.dry_run, force=args.force,
            )
            total_ok += ok
            total_fail += fail

            ok, fail = download_set(
                XML_ENRICHMENT_FIXTURES,
                "XML enrichment fixtures (serieskeys)",
                timeout=args.timeout, dry_run=args.dry_run, force=args.force,
            )
            total_ok += ok
            total_fail += fail

        logger.info(f"\nDownload total: {total_ok} OK, {total_fail} FAILED")

    if args.pack and not args.dry_run:
        pack_fixtures()

    return 0 if total_fail == 0 else 1


if __name__ == "__main__":
    sys.exit(main())
