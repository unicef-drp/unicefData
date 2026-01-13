# Quick Start Checklist - Indicator Validation Suite

## ✅ Pre-Flight Checklist (5 minutes)

### Install Dependencies

- [ ] **Python**
  ```bash
  pip install pyyaml pandas
  cd c:\GitHub\myados\unicefData
  pip install -e python/
  ```

- [ ] **R**
  ```r
  install.packages(c("unicefData", "dplyr", "readr", "stringr"))
  ```

- [ ] **Stata**
  ```stata
  net install unicefdata, from(https://raw.githubusercontent.com/unicef-drp/unicefData/main/stata/ssc)
  ```

### Verify Installation

- [ ] **Python**: Run `python -c "from unicef_api import unicefData; print('OK')"`
- [ ] **R**: Run `Rscript -e "library(unicefData); print('OK')"`
- [ ] **Stata**: Run `stata-cli --version` and `unicefdata, help`

---

## 🚀 First Run (Pick One)

### Option A: Interactive Guide (Recommended for First Time)
```bash
cd c:\GitHub\myados\unicefData
python validation/quick_start_indicator_validation.py
```
**Time**: 5-15 min  
**Difficulty**: ⭐ Easy  
**Output**: Full results in `validation/results/`

### Option B: Test First 5 Indicators (5 minutes)
```bash
python validation/test_all_indicators_comprehensive.py --limit 5
```
**Time**: 2-3 min  
**Difficulty**: ⭐ Easy  
**Output**: CSV and markdown reports

### Option C: Test One Indicator Thoroughly (3 minutes)
```bash
python validation/test_all_indicators_comprehensive.py --indicators CME_MRY0T4
```
**Time**: 1-2 min  
**Difficulty**: ⭐ Easy  
**Output**: All three languages tested

### Option D: Full Cross-Platform (30 minutes)
```powershell
cd c:\GitHub\myados\unicefData
.\validation\orchestrator_full_indicator_tests.ps1 -Limit 50
```
**Time**: 15-20 min  
**Difficulty**: ⭐⭐ Medium  
**Output**: Cross-language comparison report

---

## 📊 After Your First Run

### 1. Check Results
```bash
# View summary report (recommended first look)
cat validation/results/indicator_validation_*/SUMMARY.md

# View detailed CSV results
cat validation/results/indicator_validation_*/detailed_results.csv

# View any failures
ls validation/results/indicator_validation_*/*/failed/
```

### 2. Interpret Results

**All Success?** ✅
- Indicators are working correctly across all languages
- No action needed

**Some Failures?** ⚠️
- Check `failed/` directory for error messages
- Common issues:
  - 404: Indicator not found in API
  - Network timeout: API unavailable
  - Language mismatch: Implementation difference

**Read**: [INDICATOR_TESTING_GUIDE.md](INDICATOR_TESTING_GUIDE.md) section "Interpreting Results"

### 3. Debug Failures (Optional)
```bash
# View specific error
cat validation/results/*/*/failed/INDICATOR_CODE.error

# Test with verbose Python
python validation/test_all_indicators_comprehensive.py \
    --indicators FAILED_CODE \
    --languages python  # Start with Python (fastest)
```

---

## 🎯 Common Next Steps

### I want to...

**...test a specific set of indicators**
```bash
python validation/test_all_indicators_comprehensive.py \
    --indicators CME_MRY0T4 WSHPOL_SANI_TOTAL NUTRI_STU_0TO4_TOT
```

**...test for a specific country or year**
```bash
python validation/test_all_indicators_comprehensive.py \
    --countries ALB DZA AGO \
    --year 2018 \
    --limit 20
```

**...test only Python (fastest way to check API)**
```bash
python validation/test_all_indicators_comprehensive.py \
    --languages python \
    --limit 50
```

**...test only R or Stata**
```bash
python validation/test_all_indicators_comprehensive.py \
    --languages r --limit 20

python validation/test_all_indicators_comprehensive.py \
    --languages stata --limit 20
```

**...run R or Stata independently**
```bash
Rscript validation/test_indicator_suite.R

stata-cli do validation/test_indicator_suite.do
```

**...save results to custom location**
```bash
python validation/test_all_indicators_comprehensive.py \
    --output-dir ./my_custom_results --limit 10
```

**...run full cross-platform suite**
```powershell
.\validation\orchestrator_full_indicator_tests.ps1 -Limit 100 -Verbose
```

---

## 📚 Read Next (In Order)

1. **[README_INDICATOR_VALIDATION.md](README_INDICATOR_VALIDATION.md)** (5 min)
   - Overview and quick reference
   - Common use cases
   - Output structure

2. **[INDICATOR_TESTING_GUIDE.md](INDICATOR_TESTING_GUIDE.md)** (15 min)
   - Complete reference
   - All command options
   - Troubleshooting guide

3. **[IMPLEMENTATION_SUMMARY.md](IMPLEMENTATION_SUMMARY.md)** (10 min)
   - What was created and why
   - Architecture overview
   - Integration examples

---

## 🆘 Troubleshooting

### Scripts won't run
```bash
# Check Python
python --version
python -m pip list | grep pyyaml
python -c "import unicef_api; print('OK')"

# Check R
Rscript --version
Rscript -e "library(unicefData)"

# Check Stata
stata-cli --version
stata-cli do /dev/null
```

### Results all failures (404)
- API may be down - try again in 5 minutes
- Check network: `ping sdmx.data.unicef.org`
- Try with Python only (no R/Stata overhead)

### Timeout errors
- Network is slow - try testing fewer indicators with `--limit 5`
- API is under load - try during off-peak hours
- Increase timeout in scripts if needed

### Module not found errors
```bash
# Reinstall unicefData packages
cd c:\GitHub\myados\unicefData
pip install -e python/

Rscript -e "devtools::install_local('R/')"
```

### Still stuck?
1. Read error file: `cat validation/results/*/*/failed/*.error`
2. Check [INDICATOR_TESTING_GUIDE.md](INDICATOR_TESTING_GUIDE.md) Troubleshooting
3. File GitHub issue with error log

---

## 💡 Pro Tips

### Speed: Test Python First
```bash
python validation/test_all_indicators_comprehensive.py \
    --languages python --limit 20
```
- Fastest way to identify API issues
- Results in 30-40 seconds

### Quality: Test One Indicator Thoroughly
```bash
python validation/test_all_indicators_comprehensive.py \
    --indicators YOUR_CODE
```
- Tests all 3 languages
- Helps identify language-specific bugs
- Results in 1-2 minutes

### Monitoring: Save Baseline & Compare
```bash
# Week 1
python validation/test_all_indicators_comprehensive.py > baseline.json

# Week 2
python validation/test_all_indicators_comprehensive.py > latest.json

# Compare
diff baseline.json latest.json
```

### Automation: Use PowerShell Orchestrator
```powershell
.\validation\orchestrator_full_indicator_tests.ps1 -Limit 200
```
- Runs all 3 languages automatically
- Generates unified report
- Takes 30-40 minutes

---

## ✨ You're Ready!

Choose your first test above and run it now! 🚀

Expected result: Within 5-15 minutes, you'll have:
- ✅ CSV results showing all indicator tests
- ✅ Markdown summary with success rates
- ✅ Error logs for any failures
- ✅ Downloaded data for successful tests

**Start with**: Option A or B above 👆

---

**Questions?** Check the three documentation files linked above.  
**Issues?** Check troubleshooting section or GitHub issues.  
**Want to contribute?** File a PR with improvements!
