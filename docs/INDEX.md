# Documentation Index

Technical documentation for the **unicefData** package. See the [main README](../README.md) for installation and quick start.

## Repository Structure

The repository is organized as a multi-language project:

```
unicefData-dev/
├── r/              # R package (CRAN-ready)
│   ├── R/          # Source code
│   ├── NEWS.md     # R-specific changelog
│   └── ...
├── python/         # Python package (PyPI)
│   ├── CHANGELOG.md # Python-specific changelog
│   └── ...
├── stata/          # Stata package (SSC)
│   ├── CHANGELOG.md # Stata-specific changelog
│   └── ...
├── paper/          # Academic documentation (LaTeX)
├── docs/           # This directory - shared technical docs
├── tests/          # Cross-language validation tests
├── metadata/       # Shared YAML/CSV metadata
└── README.md       # Repository overview (start here)
```

**Language-Specific READMEs:**
- [r/README.md](../r/README.md) — R package installation & usage
- [python/README.md](../python/README.md) — Python package installation & usage
- [stata/README.md](../stata/README.md) — Stata package installation & usage

**Language-Specific Changelogs:**
- [r/NEWS.md](../r/NEWS.md) — R package changes (CRAN submissions)
- [python/CHANGELOG.md](../python/CHANGELOG.md) — Python package changes
- [stata/CHANGELOG.md](../stata/CHANGELOG.md) — Stata package changes
- [CHANGELOG.md](../CHANGELOG.md) — Multi-language overview

---

## Architecture & Design

| Document | Description |
|----------|-------------|
| [ARCHITECTURE_COMPARISON.md](ARCHITECTURE_COMPARISON.md) | Cross-platform architecture comparison (Python, R, Stata) |
| [SCHEMA_SPECIFICATION.md](SCHEMA_SPECIFICATION.md) | Unified column schema specification across all platforms |

## Metadata

| Document | Description |
|----------|-------------|
| [METADATA_GENERATION_GUIDE.md](METADATA_GENERATION_GUIDE.md) | How metadata is generated and synchronized |
| [UTF8_ENCODING_SUPPORT.md](UTF8_ENCODING_SUPPORT.md) | Character encoding considerations for international data |

## API Reference

| Document | Description |
|----------|-------------|
| [UNICEF_Open_Data_API_Comprehensive_Guide.md](UNICEF_Open_Data_API_Comprehensive_Guide.md) | Comprehensive guide to the UNICEF SDMX API |

## Governance

| Document | Description |
|----------|-------------|
| [governance_overview.md](governance_overview.md) | Data governance framework and decision-making |

## Release History

| Document | Description |
|----------|-------------|
| [RELEASE_NOTES_v1.10.0.md](RELEASE_NOTES_v1.10.0.md) | Release notes for v1.10.0 |

**Language-Specific Changelogs:**
- [r/NEWS.md](../r/NEWS.md) — R package changes (CRAN submissions, v2.3.0)
- [python/CHANGELOG.md](../python/CHANGELOG.md) — Python package changes (v2.1.0)
- [stata/CHANGELOG.md](../stata/CHANGELOG.md) — Stata package changes (v2.3.0)
- [CHANGELOG.md](../CHANGELOG.md) — Multi-language changelog overview
