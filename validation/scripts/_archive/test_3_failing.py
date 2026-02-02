"""Test 3 failing indicators from different domains"""
import sys
sys.path.insert(0, 'C:/GitHub/myados/unicefData/validation')

from test_all_indicators_comprehensive import (
    PythonTestRunner, RTestRunner, StataTestRunner
)
from pathlib import Path

# Test indicators from different domains with different failure patterns
test_indicators = [
    "COD_ALCOHOL_USE_DISORDERS",  # COD domain - Python works, R/Stata fail
    "DM_HH_INTERNET",              # DM domain - 404 across all
    "PT_CM_EMPLOY_12M"             # PT domain - Mixed results
]

# Create test output directory
output_base = Path("C:/GitHub/myados/unicefData/validation/test_3_failing")
output_base.mkdir(exist_ok=True)

for indicator in test_indicators:
    print(f"\n{'='*80}")
    print(f"Testing: {indicator}")
    print(f"{'='*80}")
    
    for lang in ["python", "r", "stata"]:
        lang_dir = output_base / lang
        lang_dir.mkdir(exist_ok=True)
        
        print(f"\n--- {lang.upper()} ---")
        
        if lang == "python":
            runner = PythonTestRunner(lang_dir)
        elif lang == "r":
            runner = RTestRunner(lang_dir)
        else:
            runner = StataTestRunner(lang_dir)
        
        try:
            result = runner.test_indicator(indicator, use_cache=False, force_fresh=True)
            
            print(f"Status: {result.status.value}")
            print(f"Rows: {result.rows_returned}")
            print(f"Time: {result.execution_time_sec:.2f}s")
            
            if result.error_message:
                print(f"Error: {result.error_message[:200]}")
            
            if result.output_file:
                print(f"Output: {result.output_file}")
                
                # Show error file contents if it exists
                if str(result.output_file).endswith('.error'):
                    try:
                        with open(result.output_file, 'r', encoding='utf-8') as f:
                            error_content = f.read()
                            if error_content:
                                print(f"Error file content: {error_content[:500]}")
                    except Exception as e:
                        print(f"Could not read error file: {e}")
        
        except Exception as e:
            print(f"EXCEPTION: {str(e)[:200]}")
    
    print()

print(f"\n{'='*80}")
print("Test complete. Check output directory:")
print(f"  {output_base}")
print(f"{'='*80}")
