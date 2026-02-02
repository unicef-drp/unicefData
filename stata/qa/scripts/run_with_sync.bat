@echo off
REM Run tests with SYNC enabled
REM Date: 2026-01-24

echo ===============================================================================
echo Running unicefdata Test Suite with SYNC Tests ENABLED
echo ===============================================================================
echo.
echo Expected: 37 tests (34 existing + 3 SYNC tests)
echo Results will be appended to test_history.txt
echo.
echo ===============================================================================
echo.

cd /d "%~dp0"

"C:\Program Files\Stata17\StataMP-64.exe" /e do run_tests.do

echo.
echo ===============================================================================
echo Test run complete. Check test_history.txt for results.
echo ===============================================================================

pause
