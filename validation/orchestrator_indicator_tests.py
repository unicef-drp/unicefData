#!/usr/bin/env python3
"""
orchestrator_indicator_tests.py
===============================

Simplified orchestrator for comprehensive indicator testing.
Manages execution, error handling, and detailed result compilation.

Usage:
    python validation/orchestrator_indicator_tests.py --help
    python validation/orchestrator_indicator_tests.py --quick
    python validation/orchestrator_indicator_tests.py --full --output results.json
"""

import subprocess
import sys
from pathlib import Path

SCRIPT_DIR = Path(__file__).parent
TEST_SCRIPT = SCRIPT_DIR / "test_all_indicators_comprehensive.py"


def main():
    if not TEST_SCRIPT.exists():
        print(f"Error: {TEST_SCRIPT} not found")
        sys.exit(1)
    
    # Pass through all arguments
    result = subprocess.run(
        [sys.executable, str(TEST_SCRIPT)] + sys.argv[1:],
        cwd=SCRIPT_DIR.parent
    )
    
    sys.exit(result.returncode)


if __name__ == "__main__":
    main()
