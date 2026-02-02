@echo off
cd /d C:\GitHub\myados\unicefData-dev
echo Starting validation at %date% %time%
C:\GitHub\.venv\Scripts\python.exe validation\scripts\core_validation\test_all_indicators_comprehensive.py --limit 20 --seed 42 --random-stratified --valid-only --languages python r stata --refresh-cache
echo.
echo Finished at %date% %time%
pause
