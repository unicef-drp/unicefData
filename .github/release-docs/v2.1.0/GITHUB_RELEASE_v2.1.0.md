# Release v2.1.0: Cross-Language Enhancements & Quality Improvements

## 🎯 Overview

Version 2.1.0 brings significant improvements across Python, R, and Stata implementations, focusing on documentation quality, cross-platform testing, and code reliability.

## 🌟 Key Features

### 🐍 Python
- ✨ PyPI version badge and download statistics
- 📖 "What's New in 2.1.0" section in README
- 🧪 Cross-language test suite (14 shared fixtures)
- 🗑️ Enhanced cache management (5-layer clearing)
- 🔍 Improved 404 error messages

**Install:** `pip install unicefdata==2.1.0`

### 📊 Stata
- ✨ New metadata examples (region, income_group, continent)
- 📝 Enhanced `04_metadata_options.do` documentation
- ✅ Cross-language parity with R and Python

### 🔧 R
- 🐛 **Critical fix:** Package name casing for case-sensitive systems
- 📖 Improved roxygen documentation
- ✅ Enhanced test coverage

## 🐛 Bug Fixes

- 🔴 **R:** Fixed package name casing (`unicefdata` → `unicefData`)
- 🔴 **Python:** Fixed test schema validation (KeyError on 'id')
- 📝 **Docs:** Updated CONTRIBUTING.md paths
- 📝 **Examples:** Clarified loop variable naming

## 🧪 Testing

- ✅ Python: 44 tests passing
- ✅ R: Enhanced test suite
- ✅ Stata: Updated QA tests
- ✅ Cross-language: 14 shared fixture tests
- ✅ CI/CD: All workflows passing

## 📦 Installation

### Python
```bash
pip install unicefdata==2.1.0
```

### R
```r
remotes::install_github("unicef-drp/unicefData@v2.1.0")
```

### Stata
```stata
* Download from GitHub releases
```

## 🔄 Upgrade Notes

**No breaking changes** - drop-in replacement for v2.0.x

## 🙏 Acknowledgments

- **João Pedro Azevedo** - Lead Developer, UNICEF Chief Statistician
- **GitHub Copilot** - Code Review
- **Claude Sonnet 4.5** - Development Assistance

## 📚 Full Release Notes

See [RELEASE_NOTES_v2.1.0.md](RELEASE_NOTES_v2.1.0.md) for complete details.

---

**Questions?** Open an issue: https://github.com/unicef-drp/unicefData/issues
