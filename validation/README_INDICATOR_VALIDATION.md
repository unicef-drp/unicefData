# Indicator Validation Suite

Comprehensive cross-platform testing framework for validating all UNICEF indicators across Python, R, and Stata implementations.

## 📋 Quick Summary

| Component | Purpose | Language |
|-----------|---------|----------|
| `test_all_indicators_comprehensive.py` | Master test orchestrator | Python |
| `test_indicator_suite.R` | R language test harness | R |
| `test_indicator_suite.do` | Stata language test harness | Stata |
| `orchestrator_full_indicator_tests.ps1` | Full cross-platform orchestrator | PowerShell |
| `quick_start_indicator_validation.py` | Interactive examples | Python |
| `INDICATOR_TESTING_GUIDE.md` | Complete documentation | Markdown |

## 🚀 Quick Start (60 seconds)

### Option 1: Test First 5 Indicators (Python)

```bash
cd c:\GitHub\myados\unicefData
python validation/test_all_indicators_comprehensive.py --limit 5
```

### Option 2: Test One Indicator (All Languages)

```bash
python validation/test_all_indicators_comprehensive.py --indicators CME_MRY0T4
```

### Option 3: Full Cross-Platform (PowerShell)

```powershell
cd c:\GitHub\myados\unicefData
.\validation\orchestrator_full_indicator_tests.ps1 -Limit 10
```

### Option 4: Interactive Quick Start

```bash
python validation/quick_start_indicator_validation.py
```

## 📊 Output

Each test generates:

1. **CSV Results** (`detailed_results.csv`)
   - Indicator, language, status, rows, error message, execution time
   
2. **Markdown Summary** (`SUMMARY.md`)
   - Executive summary with success rates
   - Failures by indicator
   - Performance metrics

3. **JSON Results** (`detailed_results.json`)
   - Machine-readable format for CI/CD integration

4. **Error Logs** (`python/failed/`, `r/failed/`, `stata/failed/`)
   - Detailed error messages per failed test

5. **Success Data** (`python/success/`, `r/success/`, `stata/success/`)
   - Downloaded CSV data for successful indicators

## 📈 Test Results Interpretation

### ✅ Success
```
CME_MRY0T4: SUCCESS (25 rows)
```
Indicator downloaded successfully with data.

### ⚠️ No Data
```
WSHPOL_SANI_TOTAL: NO DATA (0 rows)
```
API returned success but no data for these countries/year.

### ❌ Failed
```
NUTRI_STU_0TO4_TOT: FAILED - HTTPError 404
```
API error or connection issue. Check error log for details.

### 🔄 Cross-Language Mismatch
```
INDICATOR: 
  python - success (28 rows)
  r      - success (28 rows)
  stata  - not_found (0 rows)
```
Possible dataflow mapping issue. Investigate Stata implementation.

## 🔧 Common Use Cases

### Test Recently Added Indicators
```bash
python validation/test_all_indicators_comprehensive.py \
    --indicators NEW_IND_CODE1 NEW_IND_CODE2 NEW_IND_CODE3
```

### Validate After API Update
```bash
python validation/test_all_indicators_comprehensive.py \
    --output-dir ./api_validation_2026_01_10
```

### Test Specific Countries
```bash
python validation/test_all_indicators_comprehensive.py \
    --countries ALB DZA AGO --limit 20
```

### Quick R-Only Validation
```bash
Rscript validation/test_indicator_suite.R
```

### Stata Implementation Check
```bash
stata-cli do validation/test_indicator_suite.do
```

## 📁 Output Structure

```
validation/results/
├── indicator_validation_20260110_143000/
│   ├── SUMMARY.md                    # Main report
│   ├── detailed_results.csv          # Results table
│   ├── detailed_results.json         # JSON results
│   ├── python/
│   │   ├── test_log.txt
│   │   ├── success/
│   │   │   ├── CME_MRY0T4.csv
│   │   │   └── ...
│   │   └── failed/
│   │       ├── INDICATOR.error
│   │       └── ...
│   ├── r/
│   │   ├── test_log.txt
│   │   ├── success/
│   │   └── failed/
│   └── stata/
│       ├── test_log.txt
│       ├── success/
│       └── failed/
```

## 🛠️ Setup Requirements

### Python
```bash
pip install pyyaml pandas
cd c:\GitHub\myados\unicefData
pip install -e python/
```

### R
```r
install.packages(c("unicefData", "dplyr", "readr", "stringr"))
```

### Stata
```stata
net install unicefdata, from(https://raw.githubusercontent.com/unicef-drp/unicefData/main/stata/ssc)
```

## 📖 Detailed Documentation

See [INDICATOR_TESTING_GUIDE.md](INDICATOR_TESTING_GUIDE.md) for:
- Complete API reference
- Advanced usage patterns
- Troubleshooting guide
- Performance metrics
- CI/CD integration examples

## 🔍 Advanced Examples

### Limit Tests to Python Only (Fast)
```bash
python validation/test_all_indicators_comprehensive.py \
    --languages python --limit 50
```

### Test With Custom Countries and Year
```bash
python validation/test_all_indicators_comprehensive.py \
    --countries USA BRA IND KEN CHN ZAF \
    --year 2015 \
    --limit 30
```

### Full Cross-Platform Suite (PowerShell)
```powershell
.\validation\orchestrator_full_indicator_tests.ps1 `
    -Limit 100 `
    -Verbose
```

### Generate Only for Specific Languages
```powershell
.\validation\orchestrator_full_indicator_tests.ps1 -OnlyR -Limit 20
.\validation\orchestrator_full_indicator_tests.ps1 -OnlyStata -Limit 20
```

## 📊 Monitoring Success Rates

Track over time to identify API degradation:

```bash
# Week 1
python validation/test_all_indicators_comprehensive.py > results_week1.json

# Week 2
python validation/test_all_indicators_comprehensive.py > results_week2.json

# Compare
diff results_week1.json results_week2.json
```

## 🐛 Debugging Failed Tests

### View Detailed Error
```bash
cat validation/results/*/failed/INDICATOR_CODE.error
```

### Check Python Logs
```bash
tail -f validation/results/*/python/test_log.txt
```

### Check R Logs
```bash
cat validation/results/*/r/test_log.txt
```

### Check Stata Logs
```bash
cat validation/results/*/stata/test_log.txt
```

## 🔗 Integration

### With CI/CD (GitHub Actions)

```yaml
- name: Validate Indicators
  run: |
    python validation/test_all_indicators_comprehensive.py \
      --limit 50 \
      --output-dir ./test_results
    
- name: Upload Results
  uses: actions/upload-artifact@v2
  with:
    name: indicator-test-results
    path: test_results/
```

### With Scheduled Tests

```powershell
# PowerShell scheduled task
$trigger = New-ScheduledTaskTrigger -Weekly -DaysOfWeek Monday -At 3AM
$action = New-ScheduledTaskAction -Execute "powershell" `
  -Argument ".\validation\orchestrator_full_indicator_tests.ps1"
Register-ScheduledTask -TaskName "UCNIEFIndicatorValidation" `
  -Trigger $trigger -Action $action
```

## 📝 Interpreting CSV Results

| Column | Meaning | Example |
|--------|---------|---------|
| `indicator_code` | Indicator ID | CME_MRY0T4 |
| `language` | Test language | python, r, stata |
| `status` | Test result | success, failed, not_found, timeout |
| `rows_returned` | Records downloaded | 25 |
| `execution_time_sec` | Duration | 3.5 |
| `error_message` | Error detail (if failed) | HTTPError 404 |
| `output_file` | Path to downloaded data | python/success/CME_MRY0T4.csv |

## ⚡ Performance Tips

- **Test Python first**: Fastest way to identify API issues
- **Use `--limit 10`**: Quick sanity check (5-10 minutes)
- **Test during off-hours**: Reduces API load competition
- **Parallelize**: Run multiple test sessions with different indicator ranges

## 🚨 Troubleshooting

### "No module named 'unicef_api'"
```bash
pip install -e python/  # Install from source
```

### "R package 'unicefData' not found"
```r
devtools::install_local("R/", dependencies = TRUE)
```

### "Stata not found"
```powershell
# Ensure Stata is in PATH or use full path
"C:\Program Files\Stata17\stata-cli.exe" do test.do
```

### Timeout Errors
Increase timeout in test scripts or test fewer indicators at once.

## 📞 Support

For issues or feature requests:
1. Check [INDICATOR_TESTING_GUIDE.md](INDICATOR_TESTING_GUIDE.md) Troubleshooting section
2. File GitHub issue with:
   - Failed indicator code(s)
   - Error log content
   - Test command used
   - System info (OS, Python/R/Stata versions)

## 📄 License

MIT - See repo LICENSE

---

**Version**: 1.0.0  
**Last Updated**: 2026-01-10  
**Maintained by**: UNICEF Data and Analytics
