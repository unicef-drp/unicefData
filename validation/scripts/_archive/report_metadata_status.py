#!/usr/bin/env python3
"""
report_metadata_status.py - Generate metadata status summary for unicefData
===========================================================================

This script checks the metadata files across all four platforms (Python, R, 
Stata with Python parser, Stata-only parser) and generates a markdown table 
showing the status of each file. It can also compare record counts across platforms.

Usage:
    python tests/report_metadata_status.py
    python tests/report_metadata_status.py --output markdown
    python tests/report_metadata_status.py --output csv
    python tests/report_metadata_status.py --detailed
    python tests/report_metadata_status.py --compare

Run from: C:\GitHub\others\unicefData
Log output: tests/logs/report_metadata_status.log
"""

import os
import sys
import logging
from pathlib import Path
from typing import Dict, List, Tuple, Optional, NamedTuple
import yaml
import argparse

# Configure logging
logging.basicConfig(level=logging.WARNING, format='%(levelname)s: %(message)s')
logger = logging.getLogger(__name__)

# Repository root (relative to this script location)
SCRIPT_DIR = Path(__file__).parent
REPO_ROOT = SCRIPT_DIR.parent

# Platform configuration: (directory, suffix_for_files)
PLATFORM_CONFIG = {
    'Python': (REPO_ROOT / 'python' / 'metadata' / 'current', ''),
    'R': (REPO_ROOT / 'R' / 'metadata' / 'current', ''),
    'Stata (Python)': (REPO_ROOT / 'stata' / 'metadata' / 'current', ''),
    'Stata (only)': (REPO_ROOT / 'stata' / 'metadata' / 'current', '_stataonly'),
}

# For backward compatibility
METADATA_DIRS = {k: v[0] for k, v in PLATFORM_CONFIG.items()}

# Files to check (base names without suffix)
METADATA_FILES = [
    '_unicefdata_dataflows',
    '_unicefdata_codelists', 
    '_unicefdata_countries',
    '_unicefdata_regions',
    '_unicefdata_indicators',
    'unicef_indicators_metadata',
    'dataflow_index',
    'dataflows/*.yaml',  # Special case for directory
]

# Expected metadata header keys
EXPECTED_HEADER_KEYS = ['metadata', '_metadata', 'version', 'synced_at', 'source', 'agency']


class FileStats(NamedTuple):
    """Statistics for a metadata file."""
    exists: bool
    records: Optional[int]
    lines: Optional[int]
    non_missing_attrs: Optional[int]
    has_header: bool
    header_keys: List[str]


def count_lines(filepath: Path) -> int:
    """Count the number of lines in a file."""
    try:
        with open(filepath, 'r', encoding='utf-8') as f:
            return sum(1 for _ in f)
    except Exception:
        return 0


def check_header(data: dict) -> Tuple[bool, List[str]]:
    """
    Check if a YAML file has a proper metadata header.
    
    Returns:
        Tuple of (has_header, list of header keys found)
    """
    if not isinstance(data, dict):
        return (False, [])
    
    found_keys = []
    
    # Check for metadata block
    if 'metadata' in data:
        found_keys.append('metadata')
        if isinstance(data['metadata'], dict):
            found_keys.extend([f"metadata.{k}" for k in data['metadata'].keys()])
    
    if '_metadata' in data:
        found_keys.append('_metadata')
        if isinstance(data['_metadata'], dict):
            found_keys.extend([f"_metadata.{k}" for k in data['_metadata'].keys()])
    
    # Check for top-level header keys
    for key in ['version', 'synced_at', 'source', 'agency', 'platform', 
                'metadata_version', 'last_updated', 'content_type']:
        if key in data:
            found_keys.append(key)
    
    has_header = len(found_keys) > 0
    return (has_header, found_keys)


def count_non_missing_attrs(records) -> int:
    """
    Count non-missing (non-None, non-empty) attribute values across all records.
    
    Args:
        records: List of dicts or dict of dicts
        
    Returns:
        Total count of non-missing attribute values
    """
    count = 0
    
    if isinstance(records, list):
        for record in records:
            if isinstance(record, dict):
                for value in record.values():
                    if value is not None and value != '' and value != []:
                        count += 1
    elif isinstance(records, dict):
        for key, record in records.items():
            if isinstance(record, dict):
                for value in record.values():
                    if value is not None and value != '' and value != []:
                        count += 1
            elif record is not None and record != '':
                count += 1
    
    return count


def count_records_in_yaml(filepath: Path) -> Tuple[Optional[int], Optional[int], bool, List[str]]:
    """
    Count the number of records in a YAML file and check for header.
    
    Returns:
        Tuple of (record_count, non_missing_attrs, has_header, header_keys)
    """
    try:
        with open(filepath, 'r', encoding='utf-8') as f:
            data = yaml.safe_load(f)
        
        if data is None:
            return (0, 0, False, [])
        
        has_header, header_keys = check_header(data)
        
        # Handle different file structures
        if isinstance(data, dict):
            # Check common list keys
            for key in ['dataflows', 'codelists', 'countries', 'regions', 'indicators', 'codes']:
                if key in data:
                    records = data[key]
                    if isinstance(records, (list, dict)):
                        non_missing = count_non_missing_attrs(records)
                        return (len(records), non_missing, has_header, header_keys)
            
            # For dataflow_index, count dataflows list
            if 'dataflows' in data:
                records = data['dataflows']
                non_missing = count_non_missing_attrs(records) if records else 0
                return (len(records) if records else 0, non_missing, has_header, header_keys)
            
            # For indicator metadata with 'indicators' as dict
            if 'indicators' in data and isinstance(data['indicators'], dict):
                records = data['indicators']
                non_missing = count_non_missing_attrs(records)
                return (len(records), non_missing, has_header, header_keys)
                
            # Fallback: count top-level keys (excluding metadata)
            top_keys = [k for k in data.keys() if not k.startswith('_') and k != 'metadata']
            count = len(top_keys)
            return (count, count, has_header, header_keys)
        elif isinstance(data, list):
            non_missing = count_non_missing_attrs(data)
            return (len(data), non_missing, has_header, header_keys)
        
        return (None, None, has_header, header_keys)
    except Exception as e:
        logger.warning(f"Error parsing YAML file {filepath}: {e}")
        return (None, None, False, [])


def get_file_stats(base_dir: Path, file_base: str, suffix: str = '') -> FileStats:
    """
    Get comprehensive statistics for a file.
    
    Args:
        base_dir: Base metadata directory
        file_base: Base filename without extension
        suffix: Optional suffix to append (e.g., '_stataonly')
    
    Returns:
        FileStats named tuple
    """
    # Handle special case for dataflows directory
    if file_base == 'dataflows/*.yaml':
        if suffix:
            dataflows_dir = base_dir / f'dataflows{suffix}'
        else:
            dataflows_dir = base_dir / 'dataflows'
        
        if not dataflows_dir.exists():
            return FileStats(exists=False, records=None, lines=None, non_missing_attrs=None, has_header=False, header_keys=[])
        
        yaml_files = list(dataflows_dir.glob('*.yaml'))
        count = len(yaml_files)
        
        # Count total lines and non-missing attrs across all files
        total_lines = sum(count_lines(f) for f in yaml_files)
        total_non_missing = 0
        
        # Check header on first file and count attrs
        has_header = False
        header_keys = []
        for yf in yaml_files:
            _, non_missing, hdr, hkeys = count_records_in_yaml(yf)
            total_non_missing += non_missing if non_missing else 0
            if not has_header and hdr:
                has_header = hdr
                header_keys = hkeys
        
        return FileStats(
            exists=count > 0,
            records=count if count > 0 else None,
            lines=total_lines if count > 0 else None,
            non_missing_attrs=total_non_missing if count > 0 else None,
            has_header=has_header,
            header_keys=header_keys
        )
    
    # Regular files
    filename = f"{file_base}{suffix}.yaml"
    
    filepath = base_dir / filename
    
    if not filepath.exists():
        return FileStats(exists=False, records=None, lines=None, non_missing_attrs=None, has_header=False, header_keys=[])
    
    lines = count_lines(filepath)
    records, non_missing_attrs, has_header, header_keys = count_records_in_yaml(filepath)
    
    return FileStats(
        exists=True,
        records=records,
        lines=lines,
        non_missing_attrs=non_missing_attrs,
        has_header=has_header,
        header_keys=header_keys
    )


def generate_status_table(detailed: bool = False) -> List[Dict]:
    """Generate the status table data."""
    results = []
    
    for file_base in METADATA_FILES:
        row = {'file': f"`{file_base}.yaml`" if file_base != 'dataflows/*.yaml' else '`dataflows/*.yaml`'}
        
        for platform, (base_dir, suffix) in PLATFORM_CONFIG.items():
            stats = get_file_stats(base_dir, file_base, suffix)
            
            if detailed:
                if stats.exists and stats.records is not None:
                    header_mark = "📋" if stats.has_header else "⚠️"
                    row[platform] = f"✓ ({stats.records}) [{stats.lines}L] {header_mark}"
                elif stats.exists:
                    header_mark = "📋" if stats.has_header else "⚠️"
                    row[platform] = f"✓ [{stats.lines}L] {header_mark}"
                else:
                    row[platform] = "✗"
                
                # Store detailed info for later
                row[f"{platform}_stats"] = stats
            else:
                if stats.exists and stats.records is not None:
                    row[platform] = f"✓ ({stats.records})"
                elif stats.exists:
                    row[platform] = "✓"
                else:
                    row[platform] = "✗"
        
        results.append(row)
    
    return results


def format_markdown_table(data: List[Dict], detailed: bool = False) -> str:
    """Format the data as a markdown table."""
    platforms = ['Python', 'R', 'Stata (Python)', 'Stata (only)']
    
    # Header
    lines = [
        "### Metadata File Status Summary",
        "",
    ]
    
    if detailed:
        lines.append("| File | " + " | ".join(platforms) + " |")
        lines.append("|------|" + "|".join(["------" for _ in platforms]) + "|")
    else:
        lines.append("| File | " + " | ".join(platforms) + " |")
        lines.append("|------|" + "|".join(["------" for _ in platforms]) + "|")
    
    # Data rows
    for row in data:
        cells = [row['file']] + [row.get(p, "✗") for p in platforms]
        lines.append("| " + " | ".join(cells) + " |")
    
    # Legend
    lines.extend([
        "",
        "**Legend:**",
        "- **Python**: Files in `python/metadata/current/`",
        "- **R**: Files in `R/metadata/current/`",
        "- **Stata (Python)**: Standard files in `stata/metadata/current/` (generated with Python assistance)",
        "- **Stata (only)**: Files with `_stataonly` suffix in `stata/metadata/current/` (pure Stata parser)",
    ])
    
    if detailed:
        lines.extend([
            "",
            "**Format:** `✓ (records) [lines] header_status`",
            "- 📋 = Has metadata header",
            "- ⚠️ = Missing metadata header",
        ])
    
    return "\n".join(lines)


def format_detailed_report(data: List[Dict]) -> str:
    """Generate a detailed report with all statistics."""
    platforms = ['Python', 'R', 'Stata (Python)', 'Stata (only)']
    
    lines = [
        "## Detailed Metadata File Report",
        "",
        f"Generated: {__import__('datetime').datetime.now().isoformat()}",
        "",
    ]
    
    for row in data:
        lines.append(f"### {row['file']}")
        lines.append("")
        lines.append("| Platform | Exists | Records | Lines | Header | Header Keys |")
        lines.append("|----------|--------|---------|-------|--------|-------------|")
        
        for platform in platforms:
            stats_key = f"{platform}_stats"
            if stats_key in row:
                stats = row[stats_key]
                exists = "✓" if stats.exists else "✗"
                records = str(stats.records) if stats.records is not None else "-"
                file_lines = str(stats.lines) if stats.lines is not None else "-"
                header = "✓" if stats.has_header else "✗"
                header_keys = ", ".join(stats.header_keys[:3]) if stats.header_keys else "-"
                if len(stats.header_keys) > 3:
                    header_keys += "..."
                
                lines.append(f"| {platform} | {exists} | {records} | {file_lines} | {header} | {header_keys} |")
        
        lines.append("")
    
    return "\n".join(lines)


def format_csv(data: List[Dict], detailed: bool = False) -> str:
    """Format the data as CSV."""
    platforms = ['Python', 'R', 'Stata (Python)', 'Stata (only)']
    
    if detailed:
        headers = ["File"]
        for p in platforms:
            headers.extend([f"{p}_exists", f"{p}_records", f"{p}_lines", f"{p}_has_header"])
        lines = [",".join(headers)]
        
        for row in data:
            cells = [row['file'].replace('`', '')]
            for p in platforms:
                stats_key = f"{p}_stats"
                if stats_key in row:
                    stats = row[stats_key]
                    cells.extend([
                        str(stats.exists),
                        str(stats.records) if stats.records else "",
                        str(stats.lines) if stats.lines else "",
                        str(stats.has_header)
                    ])
                else:
                    cells.extend(["False", "", "", "False"])
            lines.append(",".join(cells))
    else:
        lines = ["File," + ",".join(platforms)]
        for row in data:
            cells = [row['file'].replace('`', '')] + [row.get(p, "✗") for p in platforms]
            lines.append(",".join(cells))
    
    return "\n".join(lines)


def compare_platforms(data: List[Dict]) -> Tuple[bool, str]:
    """
    Compare record counts, lines, and non-missing attributes across all four platforms.
    
    Returns:
        Tuple of (all_match, comparison_report)
    """
    platforms = ['Python', 'R', 'Stata (Python)', 'Stata (only)']
    
    lines = [
        "## Metadata Comparison Report",
        "",
        f"Generated: {__import__('datetime').datetime.now().isoformat()}",
        "",
        "### Record Count Comparison",
        "",
        "| File | Python | R | Stata (Python) | Stata (only) | Status |",
        "|------|--------|---|----------------|--------------|--------|",
    ]
    
    all_match = True
    mismatches = []
    missing_files = []
    
    # Collect stats for detailed tables
    lines_data = []
    attrs_data = []
    
    for row in data:
        file_name = row['file']
        counts = {}
        file_lines = {}
        file_attrs = {}
        
        for platform in platforms:
            stats_key = f"{platform}_stats"
            if stats_key in row and row[stats_key].exists:
                counts[platform] = row[stats_key].records
                file_lines[platform] = row[stats_key].lines
                file_attrs[platform] = row[stats_key].non_missing_attrs
            else:
                counts[platform] = None
                file_lines[platform] = None
                file_attrs[platform] = None
        
        lines_data.append((file_name, file_lines))
        attrs_data.append((file_name, file_attrs))
        
        # Build display strings
        displays = []
        for platform in platforms:
            if counts[platform] is not None:
                displays.append(str(counts[platform]))
            else:
                displays.append("-")
        
        # Check if all existing platforms match
        existing_counts = [c for c in counts.values() if c is not None]
        
        if len(existing_counts) == 0:
            status = "⚠️ Missing"
            missing_files.append(file_name)
            all_match = False
        elif len(set(existing_counts)) == 1:
            if len(existing_counts) == len(platforms):
                status = "✅ Match"
            else:
                status = f"⚠️ Partial ({len(existing_counts)}/4)"
                all_match = False
        else:
            status = "❌ Mismatch"
            mismatches.append((file_name, counts))
            all_match = False
        
        lines.append(f"| {file_name} | {' | '.join(displays)} | {status} |")
    
    # Add Lines comparison table
    lines.extend([
        "",
        "### Line Count Comparison",
        "",
        "| File | Python | R | Stata (Python) | Stata (only) |",
        "|------|--------|---|----------------|--------------|",
    ])
    
    for file_name, file_lines in lines_data:
        displays = []
        for platform in platforms:
            val = file_lines.get(platform)
            displays.append(f"{val:,}" if val is not None else "-")
        lines.append(f"| {file_name} | {' | '.join(displays)} |")
    
    # Add Non-missing attributes comparison table
    lines.extend([
        "",
        "### Non-Missing Attributes Comparison",
        "",
        "| File | Python | R | Stata (Python) | Stata (only) |",
        "|------|--------|---|----------------|--------------|",
    ])
    
    for file_name, file_attrs in attrs_data:
        displays = []
        for platform in platforms:
            val = file_attrs.get(platform)
            displays.append(f"{val:,}" if val is not None else "-")
        lines.append(f"| {file_name} | {' | '.join(displays)} |")
    
    # Summary
    lines.extend([
        "",
        "### Summary",
        "",
    ])
    
    if all_match:
        lines.append("✅ **All platforms have matching record counts!**")
    else:
        if mismatches:
            lines.append(f"❌ **{len(mismatches)} file(s) with mismatched counts:**")
            for file_name, counts in mismatches:
                count_str = ", ".join([f"{p}: {c}" for p, c in counts.items() if c is not None])
                lines.append(f"  - {file_name}: {count_str}")
            lines.append("")
        
        if missing_files:
            lines.append(f"⚠️ **{len(missing_files)} file(s) missing on some platforms:**")
            for file_name in missing_files:
                lines.append(f"  - {file_name}")
    
    return all_match, "\n".join(lines)


def main():
    parser = argparse.ArgumentParser(description='Generate metadata status summary table')
    parser.add_argument('--output', '-o', choices=['markdown', 'csv', 'both', 'report'], 
                        default='markdown', help='Output format')
    parser.add_argument('--detailed', '-d', action='store_true',
                        help='Include line counts and header status')
    parser.add_argument('--compare', '-c', action='store_true',
                        help='Compare record counts across all four platforms')
    parser.add_argument('--save', '-s', action='store_true',
                        help='Save output to file(s)')
    parser.add_argument('--verbose', '-v', action='store_true',
                        help='Enable verbose logging')
    args = parser.parse_args()
    
    if args.verbose:
        logger.setLevel(logging.DEBUG)
    
    print("Scanning metadata directories...")
    print(f"  Repository root: {REPO_ROOT}")
    print()
    
    # Check directories exist
    for platform, path in METADATA_DIRS.items():
        exists = "✓" if path.exists() else "✗"
        print(f"  {platform}: {path} [{exists}]")
    print()
    
    # Generate table
    data = generate_status_table(detailed=args.detailed or args.output == 'report')
    
    if args.output == 'report':
        report = format_detailed_report(data)
        print(report)
        
        if args.save:
            output_path = SCRIPT_DIR / 'metadata_status_report.md'
            with open(output_path, 'w', encoding='utf-8') as f:
                f.write(report)
            print(f"\nSaved to: {output_path}")
    
    elif args.output in ['markdown', 'both']:
        md_output = format_markdown_table(data, detailed=args.detailed)
        print(md_output)
        
        if args.save:
            output_path = SCRIPT_DIR / 'metadata_status.md'
            with open(output_path, 'w', encoding='utf-8') as f:
                f.write(md_output)
            print(f"\nSaved to: {output_path}")
    
    if args.output in ['csv', 'both']:
        csv_output = format_csv(data, detailed=args.detailed)
        if args.output == 'both':
            print("\n--- CSV Format ---\n")
        print(csv_output)
        
        if args.save:
            output_path = SCRIPT_DIR / 'metadata_status.csv'
            with open(output_path, 'w', encoding='utf-8') as f:
                f.write(csv_output)
            print(f"\nSaved to: {output_path}")
    
    # Run comparison if requested
    if args.compare:
        # Need detailed stats for comparison
        if not args.detailed and args.output != 'report':
            data = generate_status_table(detailed=True)
        
        all_match, comparison_report = compare_platforms(data)
        
        print("\n" + "=" * 70)
        print(comparison_report)
        
        if args.save:
            output_path = SCRIPT_DIR / 'metadata_comparison.md'
            with open(output_path, 'w', encoding='utf-8') as f:
                f.write(comparison_report)
            print(f"\nSaved to: {output_path}")
        
        # Return exit code based on comparison result
        return 0 if all_match else 1
    
    return 0


if __name__ == '__main__':
    sys.exit(main())
