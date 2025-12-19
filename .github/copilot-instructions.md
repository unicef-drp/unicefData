# unicefData Repository - AI Agent Instructions

This file provides high-level guidance for AI coding agents working within this repository. **For detailed language-specific instructions, see the `.copilot-context.md` files in each language directory.**

## Overview

- **Repository Purpose**: Provides tools for accessing UNICEF data from the SDMX API across multiple platforms (R, Python, Stata).
- **Key Features**:
  - R package for downloading UNICEF datasets
  - Python module for metadata generation and API access
  - Stata ado-files for command-line data access

## Language-Specific Context Files

Detailed instructions for each language are maintained in separate files:

| Language | Context File | Key Content |
|----------|-------------|-------------|
| **R** | [R/.copilot-context.md](../R/.copilot-context.md) | roxygen2 workflow, devtools commands, documentation guardrails |
| **Python** | [python/.copilot-context.md](../python/.copilot-context.md) | virtual environment, pytest, module structure |
| **Stata** | [stata/.copilot-context.md](../stata/.copilot-context.md) | ado-file system, PyStata integration, SMCL help files |

**Important:** When working in a specific language directory, consult the corresponding `.copilot-context.md` file for detailed patterns and workflows.

---

## Quick Reference

### Environment Paths (This Machine)

| Platform | Path | Version |
|----------|------|---------|
| **R** | `C:\Program Files\R\R-4.5.1` | R 4.5.1 (64-bit) |
| **Python** | `C:\GitHub\.venv\Scripts\python.exe` | Python 3.11.5 (venv) |
| **Stata** | `C:\Program Files\Stata17\StataMP-64.exe` | Stata 17 MP (64-bit) |

### Common Commands

```powershell
# R - Package development
Rscript -e "devtools::document()"
Rscript -e "devtools::check()"
Rscript -e "devtools::test()"

# Python - Module execution
python -m unicef_api.run_sync --verbose
pytest python/tests/

# Stata - Run from command line
& "C:\Program Files\Stata17\StataMP-64.exe" /e do "script.do"
```

---

## Cross-Platform Development Workflow

### When Modifying Function Parameters

When changing function signatures (adding, removing, renaming parameters), ensure alignment across ALL platforms:

| Platform | Primary File | Documentation | Regenerate Docs |
|----------|-------------|---------------|-----------------|
| **R** | `R/unicefData.R` | roxygen2 comments | `devtools::document()` |
| **Python** | `python/unicef_api/core.py` | docstrings | N/A (inline) |
| **Stata** | `stata/src/u/unicefdata.ado` | `.sthlp` file | Manual edit |

### Running Tests

```powershell
# R Tests
Rscript -e "devtools::test()"

# Python Tests
pytest python/tests/

# Stata (manual validation in Stata)
discard
unicefdata, indicator(CME_MRY0T4) clear
```

### Validating Metadata

Use the `validation/` directory for scripts to validate dataset metadata.

### Regenerating Metadata

Use the PowerShell script `tests/regenerate_metadata.ps1` to regenerate metadata across platforms:

```powershell
# Interactive mode (prompts if files exist)
.\tests\regenerate_metadata.ps1 -All          # All platforms
.\tests\regenerate_metadata.ps1 -Python       # Python only
.\tests\regenerate_metadata.ps1 -R            # R only
.\tests\regenerate_metadata.ps1 -Stata        # Stata only

# Force overwrite without prompts
.\tests\regenerate_metadata.ps1 -All -Force
```

### Comparing Metadata Across Platforms

```powershell
python tests/generate_metadata_status.py --compare --detailed
```

---

## Metadata Generation Architecture

The repository generates YAML metadata files from the UNICEF SDMX API across three platforms (Python, R, Stata). Each platform has specialized modules that fetch, parse, and save metadata to platform-specific directories.

### Directory Structure

```
unicefData/
├── python/
│   ├── metadata/current/           # Python-generated metadata
│   │   ├── _unicefdata_*.yaml      # Core metadata (5 files)
│   │   ├── unicef_indicators_metadata.yaml  # Full indicator codelist
│   │   └── dataflows/*.yaml        # Individual dataflow schemas
│   └── unicef_api/
│       ├── run_sync.py             # Main entry point
│       ├── schema_sync.py          # Dataflow schema sync
│       └── indicator_registry.py   # Indicator codelist sync
├── R/
│   ├── metadata/current/           # R-generated metadata
│   │   ├── _unicefdata_*.yaml      # Core metadata (5 files)
│   │   ├── unicef_indicators_metadata.yaml  # Full indicator codelist
│   │   ├── dataflow_index.yaml     # Dataflow summary
│   │   └── dataflows/*.yaml        # Individual dataflow schemas
│   ├── metadata_sync.R             # Core metadata sync
│   ├── schema_sync.R               # Dataflow schema sync
│   └── indicator_registry.R        # Indicator codelist sync
└── stata/
    ├── metadata/current/           # Stata-generated metadata
    │   ├── _unicefdata_*.yaml      # Core metadata (5 files)
    │   ├── unicef_indicators_metadata.yaml  # Full indicator codelist
    │   └── dataflow_index.yaml     # Dataflow summary
    └── src/u/
        └── unicefdata_sync.ado     # All-in-one sync command
```

### Generated Files Overview

| File | Description | Records | Python | R | Stata |
|------|-------------|---------|--------|---|-------|
| `_unicefdata_dataflows.yaml` | Dataflow definitions | ~69 | ✅ | ✅ | ✅ |
| `_unicefdata_codelists.yaml` | Dimension codelists | ~5 | ✅ | ✅ | ✅ |
| `_unicefdata_countries.yaml` | Country ISO3 codes | ~453 | ✅ | ✅ | ✅ (via Python) |
| `_unicefdata_regions.yaml` | Regional aggregates | ~111 | ✅ | ✅ | ✅ (via Python) |
| `_unicefdata_indicators.yaml` | Indicator→dataflow map | ~25 | ✅ | ✅ | ✅ |
| `unicef_indicators_metadata.yaml` | Full indicator codelist | ~733 | ✅ | ✅ | ✅ (requires Python) |
| `dataflow_index.yaml` | Dataflow summary index | ~69 | ❌ | ✅ | ⚠️ (macro limit) |
| `dataflows/*.yaml` | Individual dataflow schemas | ~69 | ✅ | ✅ | ❌ |

**Notes:**
- Stata files marked "(via Python)" use the Python helper for robust XML parsing
- Stata's `unicef_indicators_metadata.yaml` **requires** Python due to macro length limitations
- Stata's `dataflow_index.yaml` may fail due to macro length limits on large XML responses

### Indicator Registry Architecture

The `unicef_indicators_metadata.yaml` file is special - it contains the full UNICEF indicator codelist (~733 indicators) with metadata. All three platforms now generate this file with aligned structure:

```yaml
metadata:
  version: '1.0'
  source: UNICEF SDMX Codelist CL_UNICEF_INDICATOR
  url: https://sdmx.data.unicef.org/ws/public/sdmxapi/rest/codelist/UNICEF/CL_UNICEF_INDICATOR/1.0
  last_updated: '2025-12-08T10:30:00Z'
  description: Comprehensive UNICEF indicator codelist with metadata (auto-generated)
indicators:
  CME_MRY0T4:
    code: CME_MRY0T4
    name: 'Under-five mortality rate'
    description: '...'
    urn: 'urn:sdmx:org.sdmx.infomodel.codelist.Code=UNICEF:CL_UNICEF_INDICATOR(1.0).CME_MRY0T4'
    category: CME
```

### Caching Behavior

All platforms implement 30-day staleness checking:

| Platform | Cache Check | Force Refresh |
|----------|-------------|---------------|
| Python | Reads `last_updated` from file, skips if < 30 days | `refresh_indicator_cache()` always fetches |
| R | Reads `last_updated` from file, skips if < 30 days | `refresh_indicator_cache()` always fetches |
| Stata | Reads `last_updated` from file, skips if < 30 days | `unicefdata_sync, force` option |

### Dataflow Override Table

Some indicators exist in different dataflows than their prefix suggests. All platforms maintain an override table:

```python
# Example overrides (same in Python, R, Stata)
"PT_F_20-24_MRD_U18_TND" -> "PT_CM"      # Child Marriage (not PT)
"PT_F_15-49_FGM" -> "PT_FGM"              # FGM (not PT)
"ED_CR_L1_UIS_MOD" -> "EDUCATION_UIS_SDG" # UIS indicators (not EDUCATION)
```

### API Endpoints Used

| Endpoint | Purpose | Used By |
|----------|---------|---------|
| `/dataflow/UNICEF` | List all dataflows | All platforms |
| `/dataflow/UNICEF/{id}?references=all` | Get dataflow DSD | Python, R (schemas) |
| `/codelist/UNICEF/CL_REF_AREA` | Country/region codes | All platforms |
| `/codelist/UNICEF/CL_UNICEF_INDICATOR` | Full indicator list | All platforms |
| `/data/UNICEF/{dataflow}?...` | Sample data for dimension values | Python, R (schemas) |

---

## Project-Specific Conventions

### File Naming
- Use descriptive and consistent names for scripts and outputs.
- Follow R package conventions for function and file names.

### Documentation
- Update `README.md` and `docs/` for any significant changes.
- Use `NEWS.md` to log updates.

### Metadata Management
- YAML is the preferred format for metadata.
- Ensure metadata files are validated before use.

---

## Notes for AI Agents

### Critical Limitations

1. **Stata Macro Length Limit**: Stata has a ~645,216 character macro length limit. Large XML files (like the indicator codelist) MUST be parsed via the Python helper infrastructure (`unicefdata_xmltoyaml`), not inline Stata code.

2. **R Documentation Sync**: After changing R function signatures, ALWAYS run `devtools::document()` to regenerate `.Rd` files. CI will fail if code and docs are misaligned.

3. **Cross-Platform Consistency**: When modifying function parameters, update ALL platforms (R, Python, Stata) to maintain API consistency.

### Preventing Hallucinations
- Ensure all code suggestions are grounded in the repository's existing patterns and workflows.
- Avoid introducing new methodologies or dependencies unless explicitly requested.
- Cross-reference outputs and metadata with existing files to ensure consistency.

### Reproducibility Focus
- Prioritize reproducibility in all Python, R, and Stata scripts.
- Ensure that all scripts can be executed independently with minimal setup.
- Validate outputs against expected results to maintain accuracy.

### Output Handling
- Outputs generated by Python, R, and Stata scripts are never to be edited by Copilot.
- Focus on improving the scripts themselves, not the generated outputs.
- If output modifications are required, defer to human review and approval.

### Reference for Stata Scripts
- The `wbopendata` Stata ado scripts located in `C:\GitHub\myados\wbopendata` can be used as a reference for designing similar scripts in Stata.
- Review these scripts to understand best practices for structuring and documenting Stata code.

### Locating the Repository Root
To ensure scripts work regardless of the current working directory, dynamically locate the repository root by searching for the `.git` folder:
```powershell
function Get-RepoRoot {
    $currentDir = Get-Location
    while (-Not (Test-Path "$currentDir\.git")) {
        $parentDir = $currentDir.Parent
        if (-Not $parentDir) {
            throw "Unable to locate repository root."
        }
        $currentDir = $parentDir
    }
    return $currentDir
}
$RepoRoot = Get-RepoRoot
```

---

## Contact and Support

For any questions or further assistance, please refer to the repository maintainers or the documentation provided within the `docs/` directory.
