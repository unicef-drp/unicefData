# GitHub Copilot Instructions for `unicefData`

This document provides guidance for AI coding agents working within the `unicefData` repository. The goal is to ensure productive and context-aware contributions to the codebase.

## Repository Overview

The `unicefData` repository is designed for managing, validating, and analyzing UNICEF-related datasets. It includes workflows for data processing, metadata generation, and statistical analysis. The repository is structured as an R package, with additional support for Python and Stata scripts.

### Key Directories
- **`R/`**: Contains R scripts for data processing and analysis.
- **`python/`**: Python scripts for automation and data manipulation.
- **`stata/`**: Stata scripts, including metadata generation.
- **`tests/` and `testthat/`**: Unit tests for validating code functionality.
- **`docs/`**: Documentation for workflows and methodologies.
- **`metadata/`**: Stores metadata files for datasets.
- **`validation/`**: Scripts and data for validating workflows.

## Development Workflows

### 1. Setting Up the Environment

#### R Environment
- Use `unicefData.Rproj` to open the project in RStudio.
- Ensure R is installed (download from https://cran.r-project.org/).
- Add `Rscript` to your system PATH, or the scripts will auto-detect common installation paths:
  - Windows: `C:\Program Files\R\R-x.x.x\bin\Rscript.exe`
  - macOS: `/usr/local/bin/Rscript` or `/opt/homebrew/bin/Rscript`
- Install required R packages by running in R:
  ```R
  install.packages(c("httr", "jsonlite", "yaml"))
  ```

#### Python Environment
- Ensure the required Python packages are installed from `python/requirements.txt`.
- Use a virtual environment (recommended: `C:\GitHub\.venv` or `<repo>\.venv`).
- Install dependencies:
  ```bash
  pip install -r python/requirements.txt
  ```

#### Stata Environment
- Run `.do` files in Stata for metadata generation.
- The `unicefdata` ado files must be installed from `stata/src/` before running sync commands.
- Common Stata paths searched: `C:\Program Files\Stata17\`, `C:\Program Files\Stata18\`

### 2. Running Tests
- **R Tests**: Use `testthat` to run unit tests:
  ```R
  library(testthat)
  test_dir("tests")
  ```
- **Python Tests**: If Python scripts include tests, use `pytest`:
  ```bash
  pytest
  ```

### 3. Validating Metadata
- Use the `validation/` directory for scripts to validate dataset metadata.
- Follow instructions in `TODO_yaml_metadata.md` for YAML-based metadata validation.

### 4. Regenerating Metadata
Use the PowerShell script `tests/regenerate_metadata.ps1` to regenerate metadata across platforms:

```powershell
# Interactive mode (prompts if files exist)
.\tests\regenerate_metadata.ps1 -All          # All platforms
.\tests\regenerate_metadata.ps1 -Python       # Python only
.\tests\regenerate_metadata.ps1 -R            # R only
.\tests\regenerate_metadata.ps1 -Stata        # Stata only

# Force overwrite without prompts
.\tests\regenerate_metadata.ps1 -All -Force

# Verbose mode for debugging
.\tests\regenerate_metadata.ps1 -All -Verbose
```

**Prompt options when files exist:**
- **Y** = Overwrite existing files
- **N** = Abort regeneration
- **S** = Skip this platform

### 5. Comparing Metadata Across Platforms
Use the comparison script to verify consistency:

```powershell
python tests/generate_metadata_status.py --compare --detailed
```

This compares record counts, line counts, and attributes between Python, R, and Stata outputs.

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

### Platform-Specific Scripts

#### Python (`python/unicef_api/`)

| Script | Function | Output Files |
|--------|----------|--------------|
| `run_sync.py` | **Main entry point** - orchestrates all sync operations | Calls other modules |
| `schema_sync.py` | Fetches dataflow DSDs, samples data for dimension values | `dataflows/*.yaml` |
| `indicator_registry.py` | Fetches `CL_UNICEF_INDICATOR` codelist, caches with 30-day staleness | `unicef_indicators_metadata.yaml` |

**Key functions:**
```python
# schema_sync.py
sync_dataflow_schemas()  # Main sync function

# indicator_registry.py
refresh_indicator_cache()  # Force refresh from API
get_dataflow_for_indicator(code)  # Lookup with override table
get_cache_info()  # Check cache status
```

#### R (`R/`)

| Script | Function | Output Files |
|--------|----------|--------------|
| `metadata_sync.R` | Fetches core metadata (dataflows, codelists, countries, regions, indicators) | `_unicefdata_*.yaml` (5 files) |
| `schema_sync.R` | Fetches dataflow DSDs, samples data for dimension values | `dataflow_index.yaml`, `dataflows/*.yaml` |
| `indicator_registry.R` | Fetches `CL_UNICEF_INDICATOR` codelist, caches with 30-day staleness | `unicef_indicators_metadata.yaml` |

**Key functions:**
```r
# metadata_sync.R
sync_all_metadata(verbose = TRUE, output_dir = "R/metadata/current")

# schema_sync.R
sync_dataflow_schemas(verbose = TRUE, output_dir = "R/metadata/current")

# indicator_registry.R
refresh_indicator_cache()  # Force refresh from API
get_dataflow_for_indicator(code)  # Lookup with override table
get_cache_info()  # Check cache status
```

#### Stata (`stata/src/u/`)

| Script | Function | Output Files |
|--------|----------|--------------|
| `unicefdata_sync.ado` | **All-in-one** - contains all sync logic in subprograms | All files |

**Subprograms within `unicefdata_sync.ado`:**

| Subprogram | Function |
|------------|----------|
| `_unicefdata_sync_dataflows` | Fetches dataflow list |
| `_unicefdata_sync_codelists` | Fetches dimension codelists |
| `_unicefdata_sync_countries` | Fetches `CL_REF_AREA` country codes |
| `_unicefdata_sync_regions` | Filters regional aggregates |
| `_unicefdata_sync_indicators` | Creates indicator→dataflow mapping |
| `_unicefdata_sync_ind_meta` | Fetches full `CL_UNICEF_INDICATOR` codelist (uses Python helper) |

**Python Helper Infrastructure:**

Stata has a fundamental limitation with macro length (~645,216 characters max) that prevents parsing large XML files inline. To work around this, Stata uses Python helper scripts for large files:

| Component | Location | Purpose |
|-----------|----------|---------|
| `unicefdata_xmltoyaml.ado` | `stata/src/u/` | Wrapper that auto-selects Python for files >500KB |
| `unicefdata_xmltoyaml_py.ado` | `stata/src/u/` | Stata-to-Python bridge |
| `unicefdata_xml2yaml.py` | `stata/src/u/` | Python XML parser (handles all SDMX types) |
| `_xmltoyaml_get_schema.ado` | `stata/src/_/` | Schema registry for XML element mappings |

**Important:** When running Stata sync, ensure the adopath includes all required directories:
```stata
adopath ++ "stata/src/u"
adopath ++ "stata/src/p"
adopath ++ "stata/src/_"
```

**Usage:**
```stata
// Full sync (all files)
unicefdata_sync, verbose

// Force refresh (bypass 30-day cache)
unicefdata_sync, verbose force

// Use Python XML parser (recommended for large files)
unicefdata_sync, verbose forcepython

// Use pure Stata parser (limited to small files only)
unicefdata_sync, verbose forcestata
```

**Parser Selection:**
- `forcepython`: Always use Python (required for `unicef_indicators_metadata.yaml`)
- `forcestata`: Always use Stata (will fail on large XML files like the indicator codelist)
- Default: Auto-select based on file size (>500KB → Python)

### Indicator Registry Architecture

The `unicef_indicators_metadata.yaml` file is special - it contains the full UNICEF indicator codelist (~733 indicators) with metadata. All three platforms now generate this file with aligned structure:

#### File Format (all platforms)
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

#### Caching Behavior

All platforms implement 30-day staleness checking:

| Platform | Cache Check | Force Refresh |
|----------|-------------|---------------|
| Python | Reads `last_updated` from file, skips if < 30 days | `refresh_indicator_cache()` always fetches |
| R | Reads `last_updated` from file, skips if < 30 days | `refresh_indicator_cache()` always fetches |
| Stata | Reads `last_updated` from file, skips if < 30 days | `unicefdata_sync, force` option |

#### Dataflow Override Table

Some indicators exist in different dataflows than their prefix suggests. All platforms maintain an override table:

```python
# Example overrides (same in Python, R, Stata)
"PT_F_20-24_MRD_U18_TND" -> "PT_CM"      # Child Marriage (not PT)
"PT_F_15-49_FGM" -> "PT_FGM"              # FGM (not PT)
"ED_CR_L1_UIS_MOD" -> "EDUCATION_UIS_SDG" # UIS indicators (not EDUCATION)
```

### Orchestration Script

The PowerShell script `tests/regenerate_metadata.ps1` orchestrates metadata generation across all platforms:

```
regenerate_metadata.ps1
├── Regenerate-PythonMetadata()
│   └── Calls: python -m unicef_api.run_sync
│       ├── schema_sync.sync_dataflow_schemas()
│       └── indicator_registry.refresh_indicator_cache()
│
├── Regenerate-RMetadata()
│   ├── Step 1: Rscript metadata_sync.R → sync_all_metadata()
│   ├── Step 2: Rscript schema_sync.R → sync_dataflow_schemas()
│   └── Step 3: Rscript indicator_registry.R → refresh_indicator_cache()
│
└── Regenerate-StataMetadata()
    └── Runs Stata: unicefdata_sync, verbose forcepython force
        └── Requires adopath: stata/src/u, stata/src/p, stata/src/_
```

**Stata Setup for Manual Testing:**
```stata
* Ensure all required directories are in adopath
cd "C:\GitHub\others\unicefData"
adopath ++ "stata/src/u"
adopath ++ "stata/src/p"
adopath ++ "stata/src/_"

* Run sync with Python helper
unicefdata_sync, verbose forcepython force
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

## Integration Points
- **R and Python**: Ensure seamless integration between R and Python scripts.
- **Stata**: Use Stata scripts for metadata generation and validation.

## External Dependencies
- R packages listed in `DESCRIPTION`.
- Python packages (if any) should be listed in a `requirements.txt` file.
- Stata software for `.do` file execution.

## Contribution Guidelines
- Follow the repository's coding conventions.
- Write unit tests for new features.
- Document changes in `NEWS.md`.

## Notes for AI Agents
- Focus on maintaining compatibility between R, Python, and Stata components.
- Prioritize metadata validation and consistency.
- Ensure outputs adhere to UNICEF data standards.
- **Stata Limitation**: Stata has a ~645,216 character macro length limit. Large XML files (like the indicator codelist) MUST be parsed via the Python helper infrastructure (`unicefdata_xmltoyaml`), not inline Stata code.
- When modifying Stata sync code, always consider whether the XML response might exceed macro limits.

For further clarification, refer to the `README.md` or `docs/` directory.

## Additional Guidance for AI Agents

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
- To ensure scripts work regardless of the current working directory, dynamically locate the repository root by searching for the `.git` folder.
- Example for PowerShell:
  ```powershell
  function Get-RepoRoot {
      $currentDir = Get-Location
      while (-Not (Test-Path "$currentDir\.git")) {
          $parentDir = $currentDir.Parent
          if (-Not $parentDir) {
              throw "Unable to locate repository root. Ensure the script is run within a Git repository."
          }
          $currentDir = $parentDir
      }
      return $currentDir
  }
  $RepoRoot = Get-RepoRoot
  ```
- Use `$RepoRoot` to construct relative paths for scripts and commands.

## Contact and Support
For any questions or further assistance, please refer to the repository maintainers or the documentation provided within the `docs/` directory.   