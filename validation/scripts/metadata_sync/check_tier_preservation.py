#!/usr/bin/env python3
"""
Check tier preservation between two YAML metadata files.

Usage:
  python check_tier_preservation.py --before C:\\Users\\jpazevedo\\ado\\plus\\__unicefdata_indicators_metadata.yaml 
                                    --after  C:\\temp\\indicators_enriched.yaml

Exits with non-zero code if any indicator tier fields differ.

Requires: PyYAML
"""
import argparse
import sys
import yaml
from collections import defaultdict


def load_yaml_map(path: str):
    with open(path, 'r', encoding='utf-8') as f:
        data = yaml.safe_load(f)
    # Expect either a list of indicators or a dict with a key
    items = []
    if isinstance(data, list):
        items = data
    elif isinstance(data, dict):
        # Try common keys
        for key in ("indicators", "items", "data"):
            if key in data and isinstance(data[key], list):
                items = data[key]
                break
        if not items:
            # Fallback: treat dict values as items when values are dicts with code
            for v in data.values():
                if isinstance(v, dict) and "code" in v:
                    items.append(v)
    # Build map: code -> tier tuple
    result = {}
    for it in items:
        code = it.get("code") or it.get("id") or it.get("indicator")
        if not code:
            # skip entries without a code
            continue
        tier = it.get("tier")
        treason = it.get("tier_reason")
        tsub = it.get("tier_subcategory")
        result[code] = (tier, treason, tsub)
    return result


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--before', required=True, help='Path to current installed YAML with tier fields')
    ap.add_argument('--after', required=True, help='Path to newly enriched YAML to compare against')
    args = ap.parse_args()

    before = load_yaml_map(args.before)
    after = load_yaml_map(args.after)

    mismatches = []
    missing_after = []
    missing_before = []

    # Compare tiers for codes present in both
    for code, btuple in before.items():
        atuple = after.get(code)
        if atuple is None:
            missing_after.append(code)
            continue
        if btuple != atuple:
            mismatches.append((code, btuple, atuple))

    # Also report codes present only in after
    for code in after.keys():
        if code not in before:
            missing_before.append(code)

    # Summary
    print(f"Compared {len(before)} (before) vs {len(after)} (after) indicators")
    print(f"Tier mismatches: {len(mismatches)}")
    print(f"Missing in after: {len(missing_after)}")
    print(f"Missing in before: {len(missing_before)}")

    if mismatches:
        print("\nFirst 10 mismatches:")
        for code, btuple, atuple in mismatches[:10]:
            print(f"  {code}: before={btuple} after={atuple}")

    # Exit non-zero if any tier fields differ
    if mismatches:
        sys.exit(1)
    sys.exit(0)


if __name__ == '__main__':
    main()
