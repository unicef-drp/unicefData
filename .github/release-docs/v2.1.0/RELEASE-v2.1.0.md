# Release v2.1.0

**Release Date:** February 8, 2026
**Type:** Minor Version
**Status:** Production Ready
**Breaking Changes:** None

---

## 🎯 Overview

Version 2.1.0 delivers significant quality improvements across all three language implementations (Python, R, and Stata), focusing on cross-platform testing, documentation enhancements, and critical bug fixes.

---

## ✨ What's New

### 🧪 Cross-Language Testing
- **14 shared fixture tests** validating structural consistency across Python, R, and Stata
- Shared test fixtures ensure identical behavior across platforms
- Expected output validation for columns, data types, and error messages

### 🐍 Python Enhancements

#### Documentation
- PyPI version badge and download statistics
- "What's New in 2.1.0" section in README
- Improved installation instructions (PyPI + development modes)
- Enhanced GETTING_STARTED.md with clearer examples
- Fixed timeout documentation (corrected default: 60s)

#### Technical
- Enhanced cache management (5-layer clearing, 30-day staleness)
- Improved 404 errors (includes tried dataflows)
- YAML schema documentation (all 7 file types)
- Version alignment (all sub-modules match package version)
- Removed hardcoded paths (dynamic resolution)

**Install:** `pip install unicefdata==2.1.0`
**PyPI:** https://pypi.org/project/unicefdata/2.1.0/

### 📊 Stata Enhancements

#### New Metadata Examples
- **Example 6:** Add UNICEF region classification
- **Example 7:** Add World Bank income group
- **Example 8:** Multiple metadata (region + income_group + continent)

```stata
* Example usage
unicefdata, indicator(CME_MRY0T4) addmeta(region) latest clear
unicefdata, indicator(CME_MRY0T4) addmeta(income_group) latest clear
unicefdata, indicator(CME_MRY0T4) addmeta(region income_group continent) latest clear
```

#### Documentation
- Updated `04_metadata_options.do` with comprehensive examples
- Added usage notes for `addmeta()` option
- Achieved cross-language parity with R and Python

### 🔧 R Package Updates

#### Critical Fix
- **Package name casing** in `config_loader.R`
  - Fixed: `package = "unicefdata"` → `package = "unicefData"`
  - **Impact:** Now works correctly on case-sensitive filesystems (Linux, macOS)

#### Documentation
- Improved roxygen documentation in `metadata_sync.R`
- Accurate description of metadata directory fallback paths
- Documents `inst/metadata/current` and user cache behavior

#### Testing
- Enhanced test coverage (`test_pipeline_fixtures.R`, `test_pipeline_mocked.R`)
- Updated core functions (`unicefData.R`, `unicef_core.R`, `get_sdmx.R`)
- Improved flows and indicator registry handling

---

## 🐛 Bug Fixes

### Critical
- **[R]** Package name casing (`unicefdata` → `unicefData`) - prevents failures on case-sensitive systems
- **[Python]** Test schema validation (`test_metadata_manager.py`) - fixed KeyError on 'id'

### Documentation
- **[All]** Updated CONTRIBUTING.md with correct Python module path
- **[Python]** Clarified loop example in `examples/README.md` (prevents user confusion)
- **[Python]** Fixed timeout documentation (120s → 60s)

---

## 🔒 Security & Infrastructure

### Repository Management
- Implemented whitelist-based sync workflow (improved security)
- Removed private development content from public repo
- Enhanced `.gitignore` (prevents dev test artifacts)
- Added `.gitattributes` (cross-platform file consistency)

### File Handling
- Binary handling for CSV test fixtures (byte-for-byte reproducibility)
- Consistent line endings across platforms
- Export-ignore rules for cleaner `git archive`

---

## 🧪 Testing

### Test Status
- ✅ **Python:** 44 tests passing (1 skipped - requires API)
- ✅ **R:** Enhanced test suite with pipeline tests
- ✅ **Stata:** Updated QA tests with new metadata examples
- ✅ **Cross-language:** 14 shared fixture tests
- ✅ **CI/CD:** All workflows passing

### Test Infrastructure
- Shared fixtures: `tests/fixtures/api_responses/`, `tests/fixtures/expected/`
- Expected outputs: Column mappings, error messages, data validation
- Mocked tests: Pipeline validation without API calls

---

## 📦 Installation

### Python
```bash
pip install unicefdata==2.1.0
```

Verify:
```python
import unicefdata
print(unicefdata.__version__)  # Should print: 2.1.0
```

### R
```r
# From CRAN (when available)
install.packages("unicefData")

# From GitHub
remotes::install_github("unicef-drp/unicefData@v2.1.0")
```

### Stata
```stata
* From SSC (when available)
ssc install unicefdata

* From GitHub - download from releases page
```

---

## 🔄 Upgrade Guide

### From v2.0.x → v2.1.0

**No breaking changes** - drop-in replacement.

#### Python
```bash
pip install --upgrade unicefdata
```

#### R
```r
update.packages("unicefData")
```

#### Stata
```stata
adoupdate unicefdata, update
```

### What to Verify After Upgrade

1. Cache clearing (if using custom cache paths)
2. New Stata metadata options (`addmeta()`)
3. Improved error messages (404 handling)

---

## 📊 Platform Compatibility

| Platform | Version | Status |
|----------|---------|--------|
| Python | 3.9+ | ✅ All tests passing |
| R | 3.5.0+ | ✅ All tests passing |
| Stata | 13+ | ✅ QA tests passing |

**Tested on:** Ubuntu 22.04, Windows, macOS

---

## 🔗 Links

- **GitHub Release:** https://github.com/unicef-drp/unicefData/releases/tag/v2.1.0
- **PyPI Package:** https://pypi.org/project/unicefdata/2.1.0/
- **Issue Tracker:** https://github.com/unicef-drp/unicefData/issues
- **Pull Request:** https://github.com/unicef-drp/unicefData/pull/36
- **Full Changelog:** https://github.com/unicef-drp/unicefData/compare/v2.0.0...v2.1.0

---

## 📚 Documentation

### Updated
- README files (all platforms) with new badges and examples
- CONTRIBUTING.md with correct module paths
- GETTING_STARTED.md (Python) with clearer structure
- Example files (Stata) with new metadata use cases

### New
- YAML schema documentation (7 file types documented)
- DEPLOYMENT.md (sync workflow details)
- TEST-ARTIFACTS-MANAGEMENT.md (dev repo only)

---

## 🙏 Credits

### Lead Developer
**João Pedro Azevedo**
Chief Statistician, UNICEF Data and Analytics Section
Email: jpazevedo@unicef.org
Website: https://jpazvd.github.io/

### Contributors
- GitHub Copilot - Code review and suggestions
- Claude Sonnet 4.5 - Development assistance

### Code Review
This release incorporates all suggestions from automated code review:
- Package naming consistency
- Documentation accuracy
- Example code clarity
- Cross-platform compatibility

---

## 📅 Release Timeline

- **Development:** January - February 2026
- **Testing:** February 2026
- **Python PyPI:** ✅ Published February 8, 2026
- **GitHub Release:** ✅ Tagged v2.1.0 February 8, 2026
- **R CRAN:** Pending submission
- **Stata SSC:** Pending submission

---

## 💡 Next Steps

### For Users

1. **Python:** Package available on PyPI
   ```bash
   pip install unicefdata==2.1.0
   ```

2. **R:** Install from GitHub or wait for CRAN
   ```r
   remotes::install_github("unicef-drp/unicefData@v2.1.0")
   ```

3. **Stata:** Download from GitHub releases

4. **All:** Review updated documentation and new examples

### For Developers

1. Submit R package to CRAN
2. Submit Stata package to SSC
3. Update documentation websites
4. Announce to stakeholder community

---

## ❓ Support

### Questions or Issues?

- **GitHub Issues:** https://github.com/unicef-drp/unicefData/issues
- **Email:** jpazevedo@unicef.org
- **Documentation:** See updated README files in each platform directory

### Reporting Bugs

Please include:
- Platform (Python/R/Stata)
- Version number (`unicefdata.__version__` for Python)
- Operating system
- Minimal reproducible example

---

## 🎉 Thank You

Thank you to all users who provided feedback and testing support during the development of this release.

Special thanks to:
- UNICEF Data and Analytics Section
- Open source community contributors
- Early adopters who tested pre-release versions
- Automated code review tools (GitHub Copilot, Claude)

---

**Questions?** Open an issue: https://github.com/unicef-drp/unicefData/issues
**Documentation:** See README files in `python/`, `R/`, and `stata/` directories
