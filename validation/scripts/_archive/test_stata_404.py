"""Test Stata runner with a 404 indicator"""
import sys
sys.path.insert(0, 'C:/GitHub/myados/unicefData/validation')

from test_all_indicators_comprehensive import StataTestRunner
from pathlib import Path

# Create test output directory
output_dir = Path("C:/GitHub/myados/unicefData/validation/test_stata_404")
output_dir.mkdir(exist_ok=True)

# Initialize runner
runner = StataTestRunner(output_dir)

# Test a 404 indicator
print("Testing CME_COVID_DEATHS_SHARE (404)...")
result = runner.test_indicator("CME_COVID_DEATHS_SHARE", use_cache=False, force_fresh=True)

print(f"\nResult:")
print(f"  Status: {result.status.value}")
print(f"  Rows: {result.rows_returned}")
print(f"  Time: {result.execution_time_sec:.2f}s")
if result.error_message:
    print(f"  Error: {result.error_message}")
if result.output_file:
    print(f"  Output: {result.output_file}")
    
# Check if error file was created
import pathlib
error_file = pathlib.Path(output_dir) / "failed" / "CME_COVID_DEATHS_SHARE.error"
if error_file.exists():
    print(f"\nError file contents:")
    print(error_file.read_text())
