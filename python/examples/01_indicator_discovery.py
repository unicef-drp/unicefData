"""
01_indicator_discovery.py - Discover Available Indicators
==========================================================

Demonstrates how to search and discover UNICEF indicators.
Matches: R/examples/01_indicator_discovery.R

Examples:
  1. List all categories
  2. Search by keyword
  3. Search within category
  4. Get indicator info
  5. List dataflows
"""
import sys
import os
sys.path.insert(0, '..')

from unicef_api import (
    list_categories,
    search_indicators, 
    get_indicator_info,
    list_dataflows,
    get_dataflow_for_indicator
)

# Setup data directory
DATA_DIR = os.path.join(os.path.dirname(__file__), 'data')
if not os.path.exists(DATA_DIR):
    os.makedirs(DATA_DIR)

print("=" * 70)
print("01_indicator_discovery.py - Discover UNICEF Indicators")
print("=" * 70)

# =============================================================================
# Example 1: List All Categories
# =============================================================================
print("\n--- Example 1: List All Categories ---\n")

list_categories()

# =============================================================================
# Example 2: Search by Keyword
# =============================================================================
print("\n--- Example 2: Search by Keyword ---")
print("Searching for 'mortality'...\n")

search_indicators("mortality", limit=5)

# =============================================================================
# Example 3: Search Within Category
# =============================================================================
print("\n--- Example 3: Search Within Category ---")
print("Searching in NUTRITION category...\n")

search_indicators(category="NUTRITION", limit=5)

# =============================================================================
# Example 4: Get Indicator Info
# =============================================================================
print("\n--- Example 4: Get Indicator Info ---")
print("Getting info for CME_MRY0T4...\n")

info = get_indicator_info("CME_MRY0T4")
if info:
    print(f"Code: {info.get('code', 'N/A')}")
    print(f"Name: {info.get('name', 'N/A')}")
    print(f"Category: {info.get('category', 'N/A')}")

# =============================================================================
# Example 5: Auto-detect Dataflow
# =============================================================================
print("\n--- Example 5: Auto-detect Dataflow ---")
print("Detecting dataflows for various indicators...\n")

indicators = [
    "CME_MRY0T4",          # Child Mortality
    "NT_ANT_HAZ_NE2_MOD",  # Nutrition
    "ED_CR_L1_UIS_MOD",    # Education (needs override)
    "PT_F_20-24_MRD_U18_TND",  # Child Marriage (needs override)
]

for ind in indicators:
    df = get_dataflow_for_indicator(ind)
    print(f"  {ind} -> {df}")

# =============================================================================
# Example 6: List Available Dataflows
# =============================================================================
print("\n--- Example 6: List Available Dataflows ---\n")

flows = list_dataflows()
print(f"Total dataflows: {len(flows)}")
print("\nKey dataflows:")
key_flows = ["CME", "NUTRITION", "EDUCATION_UIS_SDG", "IMMUNISATION", "MNCH", "PT", "PT_CM", "PT_FGM"]
print(flows[flows['id'].isin(key_flows)][['id', 'agency']].to_string(index=False))
flows.to_csv(os.path.join(DATA_DIR, '01_ex6_dataflows.csv'), index=False)

print("\n" + "=" * 70)
print("Indicator Discovery Complete!")
print("=" * 70)
