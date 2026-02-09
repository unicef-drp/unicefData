# Release Notes - Version 2.1.0

**Release Date:** February 8, 2026
**Release Type:** Minor Version (Feature Additions + Enhancements)
**Breaking Changes:** None

---

## Summary

Version 2.1.0 delivers significant quality improvements across all three language implementations (Python, R, and Stata), focusing on cross-platform testing, documentation enhancements, and critical bug fixes. This release ensures better consistency between implementations and improves the developer and user experience.

---

## New Features

### Cross-Language Testing
- **Cross-language test suite** with 14 shared fixture tests validating structural consistency across Python, R, and Stata implementations
- Shared test fixtures in `tests/fixtures/` ensure identical behavior across platforms
- Expected output validation for columns, data types, and error messages

### Python
- **Enhanced documentation**
  - Added PyPI version badge and download statistics to README
  - New "What's New in 2.1.0" section
  - Improved installation instructions covering PyPI and development modes
  - Enhanced GETTING_STARTED.md with clearer examples

- **Improved cache management**
  - 5-layer cache clearing system (`clear_cache()`)
  - 30-day staleness threshold for automatic cleanup
  - Better cache organization and lifecycle management

- **Better error handling**
  - 404 errors now include all tried dataflows in error messages
  - More informative error messages for debugging

- **YAML schema documentation**
  - Comprehensive documentation for all 7 YAML file types
  - Schema validation guidelines

### Stata
- **New metadata examples** (Examples 6-8)
  - Example 6: Add UNICEF region classification
  - Example 7: Add World Bank income group classification
  - Example 8: Multiple metadata (region + income_group + continent)

- **Enhanced documentation**
  - Updated `04_metadata_options.do` with comprehensive metadata examples
  - Added usage notes for `addmeta()` option
  - Achieved cross-language documentation parity

### R
- **Improved documentation**
  - Enhanced roxygen documentation in `metadata_sync.R`
  - Accurate description of metadata directory fallback paths
  - Documents both `inst/metadata/current` and `tools::R_user_dir()` behavior

### Repository Infrastructure
- **Enhanced .gitignore**
  - Added patterns for dev-only test artifacts
  - Prevents accidental commits of test execution outputs
  - Cleaner repository state

- **New .gitattributes**
  - Cross-platform file consistency (line endings, binary handling)
  - Binary handling for CSV test fixtures (byte-for-byte reproducibility)
  - Export-ignore rules for cleaner `git archive`

---

## Bug Fixes

### Critical
- **[R] Package name casing bug** (`config_loader.R`)
  - Fixed: `package = "unicefdata"` → `package = "unicefData"`
  - Impact: Package now works correctly on case-sensitive filesystems (Linux, macOS strict mode)
  - Severity: Critical - Would cause failures on non-Windows systems

- **[Python] Test schema validation** (`test_metadata_manager.py`)
  - Fixed: KeyError on `schema['id']`
  - Changed validation to check `dimensions` and `time_dimension` fields
  - Impact: Python test suite now passes completely

### Documentation
- **[All] CONTRIBUTING.md path update**
  - Fixed: Outdated Python module path (`python/unicef_api/core.py` → `python/unicefdata/unicefdata.py`)
  - Impact: Helps contributors find correct files

- **[Python] Timeout documentation**
  - Fixed: Corrected default timeout value (was incorrectly stated as 120s, actual default is 60s)
  - Impact: Users now have accurate configuration information

- **[Python] Loop example clarity** (`python/examples/README.md`)
  - Fixed: Misleading loop that overwrites variable
  - Changed: `df` → `df_single` with clarified comment
  - Impact: Prevents user confusion when copying examples

---

## Improvements

### Code Quality
- **Version alignment**: All sub-modules now match package version
- **Removed hardcoded paths**: All path resolution is now dynamic
- **Dynamic User-Agent strings**: Includes version information in API calls

### Testing
- **Python**: 44 tests passing (1 skipped - requires API connection)
- **R**: Enhanced test coverage with pipeline tests
- **Stata**: Updated QA tests with new metadata examples
- **Cross-language**: 14 shared fixture tests ensuring consistency
- **CI/CD**: All workflows passing

---

## Technical Details

### Changed Dependencies
- No dependency changes in this release

### API Changes
- No breaking API changes
- All existing code remains compatible

### Deprecated Features
- None

### Removed Features
- Removed hardcoded path references (replaced with dynamic resolution)
- Cleaned up private development content from public repository

---

## Upgrade Instructions

### From v2.0.x to v2.1.0

This is a **drop-in replacement** with no breaking changes.

#### Python
```bash
pip install --upgrade unicefdata
```

Verify installation:
```python
import unicefdata
print(unicefdata.__version__)  # Should show: 2.1.0
```

#### R
```r
# From CRAN (when available)
update.packages("unicefData")

# From GitHub
remotes::install_github("unicef-drp/unicefData@v2.1.0")
```

#### Stata
```stata
* From SSC (when available)
adoupdate unicefdata, update

* From GitHub
* Download and install manually from releases
```

### What to Verify After Upgrade

1. **Cache clearing** (if using custom cache paths)
2. **Metadata additions** (test new `addmeta()` options in Stata)
3. **Error messages** (verify improved 404 handling)

---

## Known Issues

- None reported for this release

---

## Migration Notes

### For Package Maintainers
- `.gitattributes` file added - may normalize line endings on next checkout
- `.gitignore` updated - dev artifacts now properly ignored
- No code changes required

### For Users
- No migration steps required
- All existing code continues to work without modification

---

## Security

- **Repository sync workflow** now uses whitelist-based approach (improved security)
- **Private content removed** from public repository
- **Enhanced file handling** prevents accidental exposure of dev artifacts

---

## Performance

- **Python cache**: First search call ~9s (parse + build), subsequent <0.5s (cache hit)
- **No performance regressions** identified
- **Test execution**: All test suites run within expected timeframes

---

## Platform Compatibility

### Python
- **Supported versions**: Python 3.9+
- **Tested on**: Ubuntu 22.04, Windows, macOS
- **Status**: ✅ All tests passing

### R
- **Supported versions**: R 3.5.0+
- **Tested on**: Ubuntu 22.04, Windows, macOS
- **Status**: ✅ All tests passing

### Stata
- **Supported versions**: Stata 13+
- **Tested on**: Windows, Linux via StataNow
- **Status**: ✅ QA tests passing

---

## Distribution

- **Python**: Published to PyPI - https://pypi.org/project/unicefdata/2.1.0/
- **R**: Available on GitHub, CRAN submission pending
- **Stata**: Available on GitHub releases, SSC submission pending

---

## Credits

### Lead Developer
**João Pedro Azevedo**
Chief Statistician, UNICEF Data and Analytics Section
Email: jpazevedo@unicef.org

### Contributors
- GitHub Copilot - Code review and suggestions
- Claude Sonnet 4.5 - Development assistance

### Code Review
This release incorporates suggestions from automated code review:
- Package naming consistency (R)
- Documentation accuracy (all platforms)
- Example code clarity (Python)
- Cross-platform compatibility (R)

---

## Links

- **GitHub Repository**: https://github.com/unicef-drp/unicefData
- **GitHub Release**: https://github.com/unicef-drp/unicefData/releases/tag/v2.1.0
- **PyPI Package**: https://pypi.org/project/unicefdata/2.1.0/
- **Issue Tracker**: https://github.com/unicef-drp/unicefData/issues
- **Pull Request**: https://github.com/unicef-drp/unicefData/pull/36

---

## Support

For questions, issues, or feature requests:
- **GitHub Issues**: https://github.com/unicef-drp/unicefData/issues
- **Email**: jpazevedo@unicef.org

---

## Acknowledgments

Thank you to all users who provided feedback and testing support during the development of this release.

Special thanks to:
- UNICEF Data and Analytics Section
- Open source community contributors
- Early adopters who tested pre-release versions

---

**Full Changelog**: https://github.com/unicef-drp/unicefData/compare/v2.0.0...v2.1.0
