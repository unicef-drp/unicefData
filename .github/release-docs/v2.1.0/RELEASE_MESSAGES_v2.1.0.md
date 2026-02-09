# Release Messages for v2.1.0

## 📧 Email Announcement (Professional)

**Subject:** unicefData v2.1.0 Released - Cross-Language Enhancements & Quality Improvements

Dear unicefData Users,

We are pleased to announce the release of **unicefData v2.1.0**, bringing significant improvements across all three language implementations (Python, R, and Stata).

**Key Highlights:**

✨ **Enhanced Documentation** - New examples, badges, and improved guides across all platforms

🧪 **Cross-Language Testing** - 14 shared test fixtures ensure consistency between Python, R, and Stata

🐛 **Critical Bug Fixes** - R package compatibility on case-sensitive systems, Python test improvements

📊 **New Stata Features** - Metadata examples for region, income group, and continent classifications

🔧 **Better Infrastructure** - Improved cache management, error messages, and development workflows

**Installation:**

- **Python:** `pip install unicefdata==2.1.0` (already on PyPI)
- **R:** `remotes::install_github("unicef-drp/unicefData@v2.1.0")`
- **Stata:** Download from GitHub releases

**What's Changed:**

This is a minor version release with no breaking changes - it's a drop-in replacement for v2.0.x. All tests pass across platforms, and CI/CD workflows are green.

**Resources:**

- GitHub Release: https://github.com/unicef-drp/unicefData/releases/tag/v2.1.0
- PyPI Package: https://pypi.org/project/unicefdata/2.1.0/
- Full Release Notes: See RELEASE_NOTES_v2.1.0.md

Thank you for using unicefData!

Best regards,
João Pedro Azevedo
Chief Statistician, UNICEF Data and Analytics Section

---

## 🐦 Twitter/X Post (280 characters)

🎉 unicefData v2.1.0 is out!

✨ Cross-language tests (Python/R/Stata)
📚 Enhanced docs & examples
🐛 Critical bug fixes
🗺️ New Stata metadata features

Install: pip install unicefdata==2.1.0

Release notes: https://github.com/unicef-drp/unicefData/releases/tag/v2.1.0

#OpenData #UNICEF #DataScience

---

## 📱 LinkedIn Post

🎉 Excited to announce unicefData v2.1.0!

This release brings major quality improvements to our trilingual (Python/R/Stata) package for accessing UNICEF SDG indicators via SDMX API.

🌟 What's New:

✅ Cross-language test suite with 14 shared fixtures ensuring consistency
✅ Enhanced documentation with new examples across all platforms
✅ Critical bug fixes for cross-platform compatibility
✅ New Stata metadata examples (region, income group, continent)
✅ Improved cache management and error handling

📦 Installation:
• Python: pip install unicefdata==2.1.0 (now on PyPI)
• R: Available on GitHub
• Stata: Download from releases

This minor version has no breaking changes - upgrade safely!

👉 Full release notes: https://github.com/unicef-drp/unicefData/releases/tag/v2.1.0

#OpenData #UNICEF #DataScience #SDGs #Python #Rstats #Stata

---

## 📢 GitHub Release Description (Web UI)

### Release v2.1.0: Cross-Language Enhancements & Quality Improvements

This minor release brings significant improvements across all three language implementations, focusing on documentation quality, cross-platform testing, and code reliability.

#### 🌟 Highlights

- 🧪 **Cross-language test suite** with 14 shared fixtures
- 📚 **Enhanced documentation** across Python, R, and Stata
- 🐛 **Critical bug fixes** for cross-platform compatibility
- 🗑️ **Improved cache management** in Python (5-layer clearing)
- 📊 **New Stata examples** for metadata (region, income_group, continent)

#### 📦 Installation

**Python:**
```bash
pip install unicefdata==2.1.0
```

**R:**
```r
remotes::install_github("unicef-drp/unicefData@v2.1.0")
```

**Stata:**
Download from the assets below or install from SSC (pending).

#### 🐛 Bug Fixes

- 🔴 **Critical:** Fixed R package name casing for case-sensitive filesystems
- 🔴 Fixed Python test schema validation (test_metadata_manager.py)
- 📝 Updated CONTRIBUTING.md with correct Python module paths
- 📝 Clarified Python loop examples to prevent user confusion

#### 🧪 Testing

- ✅ Python: 44 tests passing
- ✅ R: Enhanced test coverage
- ✅ Stata: Updated QA tests with new examples
- ✅ Cross-language: 14 shared fixture tests
- ✅ All CI/CD workflows passing

#### 📚 Documentation

See **RELEASE_NOTES_v2.1.0.md** for comprehensive release notes.

#### 🔄 Upgrade Notes

**No breaking changes** - this is a drop-in replacement for v2.0.x.

#### 🙏 Acknowledgments

- João Pedro Azevedo - Lead Developer
- GitHub Copilot - Code Review
- Claude Sonnet 4.5 - Development Assistance

---

**Questions?** Open an issue: https://github.com/unicef-drp/unicefData/issues

---

## 📝 Changelog Entry (CHANGELOG.md format)

## [2.1.0] - 2026-02-08

### Added
- Cross-language test suite with 14 shared fixture tests
- New Stata metadata examples: region, income_group, continent (Examples 6-8)
- Enhanced Python documentation with PyPI badges and download stats
- "What's New in 2.1.0" section to Python README
- YAML schema documentation for all 7 file types
- .gitattributes file for cross-platform file consistency
- Enhanced .gitignore for dev test artifacts

### Changed
- Improved Python cache management (5-layer clearing, 30-day staleness)
- Enhanced 404 error messages (includes tried dataflows)
- Updated GETTING_STARTED.md with clearer structure
- Aligned all sub-module versions to match package version
- Improved R roxygen documentation in metadata_sync.R
- Clarified Python loop examples (renamed df → df_single)

### Fixed
- **CRITICAL:** R package name casing (unicefdata → unicefData) for case-sensitive systems
- Python test_metadata_manager.py schema validation (KeyError on 'id')
- CONTRIBUTING.md Python module path (unicef_api → unicefdata)
- Python timeout documentation (120s → 60s)
- Removed hardcoded paths (all resolution now dynamic)

### Security
- Implemented whitelist-based sync workflow
- Removed private development content from public repo
- Enhanced repository file handling and artifact management

---

## 🗣️ Verbal Announcement (Meeting/Presentation)

"I'm happy to announce that we've just released version 2.1.0 of unicefData.

This is our trilingual package for accessing UNICEF SDG indicators, and this release brings some really important improvements:

First, we now have a cross-language test suite with 14 shared tests that run across Python, R, and Stata - this ensures all three implementations work consistently.

Second, we've enhanced documentation across all platforms with new examples. For Stata users specifically, we've added three new examples showing how to add region classifications, income groups, and continent data to your queries.

Third, we fixed a critical bug in the R package that was causing issues on Linux and Mac systems - it was a simple casing problem, but it's now resolved.

The Python package is already live on PyPI, and R users can install from GitHub. This is a minor version release with no breaking changes, so you can upgrade safely.

Full details are in the release notes on GitHub."

---

## 📋 Internal Team Update (Slack/Teams)

### 🎉 unicefData v2.1.0 Released!

Hey team! :tada:

We just shipped v2.1.0 - great work everyone! Here's what made it in:

**Shipped:**
- ✅ Cross-language test suite (finally!)
- ✅ All the doc improvements from the backlog
- ✅ Critical R package bug fix (case-sensitivity issue)
- ✅ New Stata metadata examples
- ✅ Python is live on PyPI

**Testing:**
- All green - 44 Python tests, R suite enhanced, Stata QA passing
- CI/CD workflows all passed

**Next steps:**
- [ ] R CRAN submission (need to coordinate)
- [ ] Stata SSC submission
- [ ] Announce to stakeholders
- [ ] Update documentation sites

**Links:**
- Release: https://github.com/unicef-drp/unicefData/releases/tag/v2.1.0
- PyPI: https://pypi.org/project/unicefdata/2.1.0/

No breaking changes - smooth upgrade for users! 🚀

---

## 📊 Executive Summary (One-Pager)

### unicefData v2.1.0 Release Summary

**Release Date:** February 8, 2026
**Type:** Minor Version (Feature Additions + Enhancements)
**Status:** Production Ready

#### Key Achievements

1. **Quality Assurance**
   - Implemented cross-language test suite (14 shared tests)
   - All CI/CD workflows passing
   - Enhanced test coverage across Python, R, and Stata

2. **User Experience**
   - Improved documentation across all platforms
   - New examples for Stata metadata features
   - Better error messages and cache management

3. **Technical Debt**
   - Fixed critical cross-platform compatibility bug (R package)
   - Resolved test validation issues (Python)
   - Updated outdated documentation references

4. **Infrastructure**
   - Enhanced repository management
   - Improved development workflow
   - Better file handling for cross-platform consistency

#### Distribution

- **Python:** Published to PyPI (https://pypi.org/project/unicefdata/2.1.0/)
- **R:** Available on GitHub, CRAN submission pending
- **Stata:** Available on GitHub, SSC submission pending

#### Impact

- **No breaking changes** - seamless upgrade path for existing users
- **44 passing tests** in Python, enhanced coverage in R and Stata
- **Improved reliability** through cross-language testing

#### Next Steps

1. Submit R package to CRAN
2. Submit Stata package to SSC
3. Announce to stakeholder community
4. Update documentation websites

---

## 🎤 Conference/Workshop Announcement

**Title Slide Text:**

unicefData v2.1.0
Cross-Language Enhancements & Quality Improvements

João Pedro Azevedo
Chief Statistician, UNICEF Data and Analytics Section

**Bullet Points for Presentation:**

- Trilingual package (Python, R, Stata) for UNICEF SDG indicators
- Version 2.1.0 released February 2026
- Key improvements:
  - Cross-language test suite ensures consistency
  - Enhanced documentation with new examples
  - Critical bug fixes for cross-platform compatibility
  - Better cache management and error handling
- Available now on PyPI, GitHub
- Free and open source (MIT License)

---

**Choose the format that best fits your needs!**
