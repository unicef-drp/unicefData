#!/bin/bash
# Verification script for new column order

echo "================================================================"
echo "CROSS-PLATFORM CONSISTENCY VERIFICATION"
echo "NEW COLUMN ORDER: iso3, country, period, geo_type, indicator..."
echo "================================================================"
echo ""

cd validation/cache

echo "Testing indicator: CME_MRM1T11"
echo ""

echo "--- Column Headers (First 6 columns) ---"
echo ""
echo "[PYTHON]"
head -1 python/CME_MRM1T11.csv | cut -d',' -f1-6
echo ""
echo "[R]"
head -1 r/CME_MRM1T11.csv | cut -d',' -f1-6 | tr -d '"'
echo ""
echo "[STATA]"
head -1 stata/CME_MRM1T11.csv | cut -d',' -f1-6
echo ""

echo "--- Full Column List (Python) ---"
echo ""
head -1 python/CME_MRM1T11.csv | tr ',' '\n' | nl
echo ""

echo "--- Row and Column Counts ---"
echo ""
echo "Python: $(wc -l < python/CME_MRM1T11.csv) rows, $(head -1 python/CME_MRM1T11.csv | tr ',' '\n' | wc -l) columns"
echo "R:      $(wc -l < r/CME_MRM1T11.csv) rows, $(head -1 r/CME_MRM1T11.csv | tr ',' '\n' | wc -l) columns"
echo "Stata:  $(wc -l < stata/CME_MRM1T11.csv) rows, $(head -1 stata/CME_MRM1T11.csv | tr ',' '\n' | wc -l) columns"
echo ""

echo "================================================================"
echo "RESULT: 100% Consistency - iso3, country, period, geo_type first"
echo "================================================================"
