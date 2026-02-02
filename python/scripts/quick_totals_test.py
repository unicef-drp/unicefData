import os, sys
HERE = os.path.dirname(os.path.abspath(__file__))
# Add package root: unicefData-dev/python
PKG_ROOT = os.path.abspath(os.path.join(HERE, os.pardir))
if PKG_ROOT not in sys.path:
    sys.path.insert(0, PKG_ROOT)

from unicef_api.core import unicefData

if __name__ == "__main__":
    # Test with totals mode enabled
    indicators = ["COD_ALCOHOL_USE_DISORDERS", "HVA_PREV_TEST_RES_12"]
    out_path = os.path.join(HERE, "quick_totals_test.out")
    with open(out_path, "w", encoding="utf-8") as fh:
        for ind in indicators:
            fh.write(f"\n=== Testing {ind} (totals=True) ===\n")
            try:
                df = unicefData(indicator=ind, year=None, totals=True, tidy=True)
                fh.write(f"Rows: {len(df)}; Columns: {list(df.columns)}\n")
                fh.write(df.head(3).to_string(index=False))
                fh.write("\n")
            except Exception as e:
                fh.write(f"Error for {ind}: {e}\n")
    print(f"Wrote results to {out_path}")
