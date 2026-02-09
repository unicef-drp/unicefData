# Release v2.1.0 - Cross-Language Enhancements & Quality Improvements

**Release Date:** February 2026
**Type:** Minor Version (Feature Additions + Enhancements)
**Status:** Production Ready

---

## 🎯 Overview

Version 2.1.0 brings significant improvements across all three language implementations (Python, R, and Stata), with a focus on documentation quality, cross-platform testing, and code reliability. This release includes comprehensive metadata examples, enhanced cache management, and critical bug fixes identified through automated code review.

---

## 🌟 Highlights

- 🧪 **Cross-language test suite** with 14 shared fixtures ensuring consistency
- 📚 **Enhanced documentation** across all platforms with new examples
- 🔧 **Critical bug fixes** for cross-platform compatibility
- 🗑️ **Improved cache management** with 5-layer clearing system
- ✅ **Repository infrastructure** improvements for better development workflow

---

## 📊 What's New by Platform

### 🐍 **Python Enhancements**

#### Documentation Improvements
- ✨ **New badges:** PyPI version, download statistics, Python 3.9+ requirement
- 📖 **"What's New in 2.1.0"** section in README
- 🔧 **Fixed timeout documentation** (corrected default 60s, was incorrectly stated as 120s)
- 📝 **Improved installation instructions** (PyPI + development modes)
- 📚 **Enhanced GETTING_STARTED.md** with clearer examples and better structure
- 🔍 **Loop example clarification** in examples/README.md (prevents user confusion)

#### Technical Improvements
- 🧪 **Cross-language test suite** (14 shared fixture tests)
- 📋 **YAML schema documentation** for all 7 file types
- 🗑️ **Enhanced cache management** (5-layer clearing, 30-day staleness threshold)
- 🔍 **Improved 404 errors** (includes tried dataflows in error messages)
- 🔄 **Version alignment** (all sub-modules match package version)
- 🧹 **Removed hardcoded paths** (all resolution now dynamic)
- ✅ **Fixed test_metadata_manager.py** (schema validation now correct)

**PyPI Package:** https://pypi.org/project/unicefdata/2.1.0/

---

### 📊 **Stata Enhancements**

#### New Metadata Examples
- **Example 6:** Add UNICEF region classification
  ```stata
  unicefdata, indicator(CME_MRY0T4) addmeta(region) latest
  ```
- **Example 7:** Add World Bank income group
  ```stata
  unicefdata, indicator(CME_MRY0T4) addmeta(income_group) latest
  ```
- **Example 8:** Multiple metadata (region + income + continent)
  ```stata
  unicefdata, indicator(CME_MRY0T4) addmeta(region income_group continent) latest
  ```

#### Documentation Updates
- 📝 **Updated `04_metadata_options.do`** with comprehensive metadata examples
- 📖 **Added usage notes** for `addmeta()` option
- ✅ **Cross-language parity** achieved with R and Python examples

---

### 🔧 **R Package Updates**

#### Code Improvements
- 🐛 **Critical fix:** Package name casing in `config_loader.R`
  - Changed `package = "unicefdata"` → `package = "unicefData"`
  - Ensures compatibility with case-sensitive filesystems (Linux, macOS)
- 📖 **Improved roxygen documentation** in `metadata_sync.R`
  - Accurate description of fallback paths
  - Documents `inst/metadata/current` and user cache behavior

#### Test Enhancements
- ✅ **Enhanced test coverage** (`test_pipeline_fixtures.R`, `test_pipeline_mocked.R`)
- 🔄 **Updated core functions** (`unicefData.R`, `unicef_core.R`, `get_sdmx.R`)
- 📊 **Improved flows** and indicator registry handling
- 🔄 **Enhanced metadata** synchronization logic

---

## 🔒 **Security & Infrastructure**

### Repository Management
- ✅ **Removed private development content** from public repo
- ✅ **Implemented whitelist-based sync workflow** (improved security)
- ✅ **Enhanced .gitignore** (prevents dev test artifacts)
- ✅ **Added .gitattributes** (cross-platform file consistency)
- ✅ **Updated LICENSE files** across all platforms

### Development Workflow
- 🔄 **Automated sync:** `unicefData-dev` → `unicefData/stage` → `unicefData/develop`
- 📝 **Better documentation:** FILE-ORGANIZATION, DEPLOYMENT guides
- 🧪 **Test artifact management** (dev-only files properly ignored)
- 📋 **Consistent file handling** (line endings, binary files)

---

## 🐛 **Bug Fixes**

### Critical Fixes
- 🔴 **R package name casing** (`config_loader.R`) - breaks on case-sensitive systems
- 🔴 **Python test schema validation** (`test_metadata_manager.py`) - KeyError on 'id'

### Documentation Fixes
- 📝 **CONTRIBUTING.md:** Updated Python module path (`unicef_api` → `unicefdata`)
- 📝 **Python examples:** Clarified loop variable naming (prevents confusion)
- 📝 **R roxygen:** Accurate documentation of metadata directory fallback

---

## 🧪 **Testing**

### Test Suite Status
- ✅ **Python:** 44 tests passing (1 skipped - requires API)
- ✅ **R:** Enhanced test suite with pipeline tests
- ✅ **Stata:** Updated QA tests with new metadata examples
- ✅ **Cross-language:** 14 shared fixture tests passing
- ✅ **CI/CD:** All workflows passing

### Test Infrastructure
- 📋 **Shared fixtures:** `tests/fixtures/api_responses/`, `tests/fixtures/expected/`
- 📊 **Expected outputs:** Column mappings, error messages, data validation
- 🔧 **Mocked tests:** Pipeline validation without API calls

---

## 📦 **Installation**

### Python
```bash
pip install unicefdata==2.1.0
```

### R
```r
# CRAN (once published)
install.packages("unicefData")

# Development version
remotes::install_github("unicef-drp/unicefData")
```

### Stata
```stata
* SSC (once published)
ssc install unicefdata

* Or download from GitHub releases
```

---

## 🔄 **Upgrade Guide**

### From v2.0.x to v2.1.0

**No breaking changes** - this is a drop-in replacement.

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

### What to Test After Upgrading

1. **Verify cache clearing** (if you use custom cache paths)
2. **Test metadata additions** (new `addmeta()` options in Stata)
3. **Check error messages** (improved 404 handling in Python)

---

## 📚 **Documentation**

### Updated Documentation
- 📖 **README files** (all platforms) with new badges and examples
- 📝 **CONTRIBUTING.md** with correct module paths
- 📋 **GETTING_STARTED.md** (Python) with clearer structure
- 📊 **Example files** (Stata) with new metadata use cases

### New Documentation
- 📚 **YAML schema documentation** (7 file types documented)
- 🔧 **DEPLOYMENT.md** (sync workflow details)
- 🧪 **TEST-ARTIFACTS-MANAGEMENT.md** (dev repo only)

---

## 🙏 **Acknowledgments**

### Contributors
- **João Pedro Azevedo** - Lead developer, UNICEF Chief Statistician
- **GitHub Copilot** - Code review and suggestions
- **Claude Sonnet 4.5** - Development assistance

### Code Review
This release incorporates all suggestions from automated code review:
- Package naming consistency
- Documentation accuracy
- Example code clarity
- Cross-platform compatibility

---

## 🔗 **Links**

- **PyPI:** https://pypi.org/project/unicefdata/2.1.0/
- **GitHub:** https://github.com/unicef-drp/unicefData
- **Issues:** https://github.com/unicef-drp/unicefData/issues
- **Pull Request:** https://github.com/unicef-drp/unicefData/pull/36

---

## 📅 **Release Timeline**

- **Development:** January - February 2026
- **Testing:** February 2026
- **Python PyPI Release:** ✅ Published
- **R CRAN Submission:** Pending
- **Stata SSC Submission:** Pending
- **GitHub Release:** February 2026

---

## 🚀 **Next Steps**

After installing v2.1.0:

1. ✅ **Python users:** Package already available on PyPI
2. 📦 **R users:** Install from GitHub or wait for CRAN publication
3. 📋 **Stata users:** Install from GitHub or wait for SSC publication
4. 📖 **All users:** Review updated documentation and new examples

---

**Questions or issues?** Please open an issue on GitHub:
https://github.com/unicef-drp/unicefData/issues

**Thank you for using unicefData!** 🎉
