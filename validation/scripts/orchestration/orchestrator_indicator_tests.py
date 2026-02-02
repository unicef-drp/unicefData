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

SCRIPT_DIR = Path(__file__).resolve().parent
SCRIPTS_ROOT = SCRIPT_DIR.parent
VALIDATION_ROOT = SCRIPTS_ROOT.parent
TEST_SCRIPT = SCRIPTS_ROOT / "core_validation" / "test_all_indicators_comprehensive.py"


def main():
    if not TEST_SCRIPT.exists():
        print(f"Error: {TEST_SCRIPT} not found")
        sys.exit(1)
    
    # Pass through all arguments
    # Use CREATE_NEW_PROCESS_GROUP to isolate from parent's Ctrl+C signals on Windows
    import signal
    creationflags = subprocess.CREATE_NEW_PROCESS_GROUP if sys.platform == "win32" else 0
    result = subprocess.run(
        [sys.executable, str(TEST_SCRIPT)] + sys.argv[1:],
        cwd=VALIDATION_ROOT,
        creationflags=creationflags,
    )
    
    sys.exit(result.returncode)


if __name__ == "__main__":
    main()
