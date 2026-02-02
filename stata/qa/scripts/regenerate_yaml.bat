@echo off
REM Batch file to regenerate YAML files using Stata
REM Date: 2026-01-24

echo ================================================================================
echo UNICEF YAML Metadata Regeneration
echo ================================================================================
echo.

cd /d "%~dp0"

"C:\Program Files\Stata17\StataMP-64.exe" /e do regenerate_yaml.do

echo.
echo ================================================================================
echo Regeneration complete. Check regenerate_yaml.log for details.
echo ================================================================================

pause
