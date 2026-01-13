"""Quick test of Stata runner with a single indicator"""
import sys
sys.path.insert(0, 'C:/GitHub/myados/unicefData/validation')

from test_all_indicators_comprehensive import StataTestRunner
from pathlib import Path

# Create test output directory
output_dir = Path("C:/GitHub/myados/unicefData/validation/test_single_stata")
output_dir.mkdir(exist_ok=True)

# Initialize runner
runner = StataTestRunner(output_dir)

# Test a known-good indicator
print("Testing ECD_CHLD_36-59M_EDU-PGM...")
result = runner.test_indicator("ECD_CHLD_36-59M_EDU-PGM", use_cache=False, force_fresh=True)

print(f"\nResult:")
print(f"  Status: {result.status.value}")
print(f"  Rows: {result.rows_returned}")
print(f"  Time: {result.execution_time_sec:.2f}s")
if result.error_message:
    print(f"  Error: {result.error_message}")
if result.output_file:
    print(f"  Output: {result.output_file}")
