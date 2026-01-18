# TODO: YAML Metadata Enhancements for unicefData

**Created:** 2025-12-05  
**Status:** Phase 1 COMPLETE ✅ | Phase 2 Next  
**Affects:** R, Python, Stata implementations

---

## Overview

Implement consistent YAML metadata generation and usage across all three language implementations (R, Python, Stata) with proper watermarking, versioning, age warnings, and user feedback.

### Phase 1 Summary (COMPLETE)
- ✅ Python: `MetadataSync.sync_all()` with watermarks and new file naming
- ✅ R: `sync_metadata()` with watermarks and new file naming  
- ✅ Stata: `unicefdata_sync` command created with help file

### Next: Phase 2 - Metadata Age Checking
- Add age warnings to `get_unicef()` functions in all languages
- Warn if metadata > 30 days old

---

## 0. File Naming Convention (DECISION REQUIRED)

### Current State
| Language | Location | Current Names |
|----------|----------|---------------|
| R | `inst/extdata/metadata/` | `dataflows.yaml`, `indicators.yaml`, `codelists.yaml` |
| Python | `python/unicef_api/data/` | `dataflows.yaml`, `indicators.yaml`, `codelists.yaml` |
| Stata | `stata/metadata/` | `dataflows.yaml`, `indicators.yaml`, `codelists.yaml` |

### Options for Standardized Naming

#### Option A: Simple names (CURRENT)
```
dataflows.yaml
indicators.yaml
codelists.yaml
```
- ✅ Clean and simple
- ✅ Already in use
- ❌ Not immediately identifiable as unicefData files

#### Option B: Package prefix with underscore
```
unicefdata_dataflows.yaml
unicefdata_indicators.yaml
unicefdata_codelists.yaml
```
- ✅ Clearly identifies source package
- ✅ Consistent with Stata naming conventions (lowercase)
- ✅ Easy to glob: `unicefdata_*.yaml`
- ❌ Longer filenames

#### Option C: Package prefix with hyphen
```
unicefdata-dataflows.yaml
unicefdata-indicators.yaml
unicefdata-codelists.yaml
```
- ✅ Clearly identifies source package
- ✅ More readable than underscores
- ❌ Hyphens can be problematic in some contexts

#### Option D: Namespaced with dots
```
unicef.dataflows.yaml
unicef.indicators.yaml
unicef.codelists.yaml
```
- ✅ Namespace-style (like Java packages)
- ❌ Dots can confuse file extension detection

### **DECISION: Option B variant** (`_unicefdata_<name>.yaml`)

Leading underscore chosen because:
1. **Stata compatibility**: Underscores are standard in Stata naming
2. **Glob-friendly**: Easy to find all files with `_unicefdata_*.yaml`
3. **Clear provenance**: Immediately obvious these are unicefData files
4. **Sorted first**: Leading underscore sorts before alphabetical files
5. **Convention**: Leading underscore often indicates "system/config" files

### Standard File Names (FINAL)
```
_unicefdata_dataflows.yaml      # SDMX dataflow definitions
_unicefdata_indicators.yaml     # Indicator → dataflow mappings
_unicefdata_codelists.yaml      # Valid dimension codes (sex, age, wealth, etc.)
_unicefdata_countries.yaml      # Country ISO3 codes (separate from codelists)
_unicefdata_regions.yaml        # Regional/aggregate codes (separate from codelists)
_unicefdata_sync_history.yaml   # Sync timestamps and versions
```

### Migration Plan
- [x] Decision made: `_unicefdata_<name>.yaml` format
- [x] Python: New file naming implemented (2025-12-05)
- [x] R: New file naming implemented (2025-12-05)
- [x] Stata: New file naming implemented (2025-12-05)
- [ ] Clean up old files in `metadata/current/` directories
- [ ] Update `.gitignore` patterns if needed

---

## 0.1 Unified Directory Structure (ALL LANGUAGES)

### Confirmed Structure
All three languages will follow the **same directory structure**:

```
{language_root}/metadata/
├── _unicefdata_dataflows.yaml
├── _unicefdata_indicators.yaml
├── _unicefdata_codelists.yaml
├── _unicefdata_countries.yaml
├── _unicefdata_regions.yaml
└── _unicefdata_sync_history.yaml
```

### Language-Specific Roots
| Language | Root | Full Metadata Path |
|----------|------|-------------------|
| R | `inst/extdata/` | `inst/extdata/metadata/_unicefdata_*.yaml` |
| Python | `python/unicef_api/data/` | `python/unicef_api/data/metadata/_unicefdata_*.yaml` |
| Stata | `stata/` | `stata/metadata/_unicefdata_*.yaml` |

### Shared Master Location
Additionally, a **master copy** will be maintained at the repo root:
```
unicefData/
├── metadata/
│   ├── current/
│   │   ├── _unicefdata_dataflows.yaml
│   │   ├── _unicefdata_indicators.yaml
│   │   ├── _unicefdata_codelists.yaml
│   │   ├── _unicefdata_countries.yaml
│   │   ├── _unicefdata_regions.yaml
│   │   └── _unicefdata_sync_history.yaml
│   └── vintages/
│       └── YYYY-MM-DD/
│           └── ... (archived versions)
```

### Sync Strategy
1. **Primary source**: `metadata/current/` (repo root)
2. **Language copies**: Synced from primary via script or CI
3. **Package installation**: Each language includes its copy

---

## 1. YAML File Watermark/Header ✅ COMPLETE

### Requirements
- [x] All generated YAML files must include a standard header with:
  - `platform`: Platform name (R/Python/Stata)
  - `version`: Metadata version (e.g., `2.0.0`)
  - `synced_at`: ISO 8601 timestamp
  - `source`: API URL used
  - `agency`: Data provider agency (UNICEF)
  - `content_type`: Type of content in the file
  - `counts`: Record counts for the content

### Implemented Header Structure
```yaml
_metadata:
  platform: Python
  version: "2.0.0"
  synced_at: "2025-12-05T10:30:00Z"
  source: "https://sdmx.data.unicef.org/ws/public/sdmxapi/rest"
  agency: UNICEF
  content_type: dataflows
  counts:
    dataflows: 69
```

### Implementation Status
- [x] Python: `MetadataSync._create_watermarked_dict()` in `metadata.py`
- [x] R: `.create_watermarked_list()` in `metadata.R`
- [x] Stata: `_unicef_add_watermark` in `unicefdata_sync.ado`

---

## 2. Centralized YAML Storage Location

### Requirements
- [x] All YAML files saved to language-specific metadata directories
- [x] Structure: `metadata/` for active files
- [x] File naming: `_unicefdata_*.yaml` pattern

### Current Directory Structure
```
unicefData/
├── python/metadata/current/    # Python metadata files
│   ├── _unicefdata_dataflows.yaml
│   ├── _unicefdata_indicators.yaml
│   ├── _unicefdata_codelists.yaml
│   ├── _unicefdata_countries.yaml
│   ├── _unicefdata_regions.yaml
│   └── _unicefdata_sync_history.yaml
├── R/metadata/current/         # R metadata files
│   └── ... (same structure)
└── stata/metadata/             # Stata metadata files
    └── ... (same structure)
```

### Remaining Tasks (Phase 3)
- [ ] Create central `metadata/current/` at repo root as master copy
- [ ] Create sync script to propagate from central to language-specific folders
- [ ] Set up CI/CD to run sync on schedule

---

## 3. Generation Summary Messages ✅ COMPLETE

### Requirements
- [x] When metadata is generated, display summary with:
  - File being created (name and path)
  - Number of dataflows
  - Number of indicators (total and per dataflow)
  - Number of country/regional codes
  - Total YAML files created
  - Output location

### Example Output (Implemented)
```
================================================================================
                     UNICEF Metadata Sync Summary
================================================================================
Synced at: 2025-12-05 10:30:00
Output location: ./python/metadata/current/

Files created:
  ✓ _unicefdata_dataflows.yaml    -  69 dataflows
  ✓ _unicefdata_indicators.yaml   -  25 indicators
  ✓ _unicefdata_codelists.yaml    -   5 codelists
  ✓ _unicefdata_countries.yaml    - 453 countries
  ✓ _unicefdata_regions.yaml      - 111 regions
  ✓ _unicefdata_sync_history.yaml - sync history

Total: 6 files created
================================================================================
```

### Implementation Status
- [x] Python: `sync_all()` with verbose output
- [x] R: `sync_metadata()` with verbose output  
- [x] Stata: `unicefdata_sync` with display messages

---

## 4. Metadata Age Check and Warnings ⏳ PHASE 2

### Requirements
- [ ] On each API call, check age of metadata files
- [ ] Display extraction date of YAML files being used
- [ ] Warn if metadata is older than 30 days
- [ ] Recommend update command

### Example Warning
```
Note: Using metadata from 2025-11-01 (34 days old)
Warning: Metadata is older than 30 days. Consider updating:
  R:      unicefData::sync_metadata()
  Python: unicef_api.sync_metadata()
  Stata:  unicefdata_sync
```

### Tasks
- [ ] R: Add age check to `get_unicef()` 
- [ ] Python: Add age check to `get_unicef()`
- [ ] Stata: Add age check to `unicefdata`
- [ ] Create consistent warning message format

---

## 5. Sync Functions per Language

### R Implementation
```r
# R/metadata.R
sync_metadata <- function(output_dir = NULL, verbose = TRUE) {

  # ... implementation
}
```

**Tasks:**
- [x] Update function signature ✅ (2025-12-05)
- [x] Add watermark to YAML output ✅ (2025-12-05)
- [x] Add verbose summary messages ✅ (2025-12-05)
- [x] Save to shared `metadata/current/` ✅ (2025-12-05)
- [x] Add `sync_countries()` for CL_COUNTRY ✅ (2025-12-05)
- [x] Add `sync_regions()` for CL_WORLD_REGIONS ✅ (2025-12-05)

### Python Implementation
```python
# python/unicef_api/metadata_sync.py
def sync_metadata(output_dir: Optional[Path] = None, verbose: bool = True) -> dict:
    # ... implementation
```

**Tasks:**
- [x] Update function signature ✅ (2025-12-05)
- [x] Add watermark to YAML output ✅ (2025-12-05)
- [x] Add verbose summary messages ✅ (2025-12-05)
- [x] Save to shared `metadata/current/` ✅ (2025-12-05)
- [x] Separate countries/regions from codelists ✅ (2025-12-05)
- [x] Use correct UNICEF codelists (CL_COUNTRY, CL_WORLD_REGIONS) ✅ (2025-12-05)

### Stata Implementation
```stata
* stata/src/u/unicefdata_sync.ado
program define unicefdata_sync
    * ... implementation
end
```

**Tasks:**
- [x] Create new `unicefdata_sync.ado` command ✅ (2025-12-05)
- [x] Use direct file write to create YAML with watermark ✅ (2025-12-05)
- [x] Add display summary messages ✅ (2025-12-05)
- [x] Save to `stata/metadata/` ✅ (2025-12-05)
- [x] Create `unicefdata_sync.sthlp` help file ✅ (2025-12-05)

---

## 6. Implementation Priority

### Phase 1: Core Infrastructure (High Priority)
1. [x] Define standard YAML header format (shared spec) ✅
2. [x] Update Python `sync_metadata()` with watermark and summary ✅ (2025-12-05)
3. [x] Update R `sync_metadata()` with watermark and summary ✅ (2025-12-05)
4. [x] Create Stata `unicefdata_sync` command ✅ (2025-12-05)

### Phase 2: Age Checking (Medium Priority)
5. [ ] Add metadata age check to Python `get_unicef()`
6. [ ] Add metadata age check to R `get_unicef()`
7. [ ] Add metadata age check to Stata `unicefdata`
8. [ ] Create consistent warning message format

### Phase 3: Centralization (Lower Priority)
9. [ ] Set up shared `metadata/current/` structure
10. [ ] Create cross-platform sync script
11. [ ] Update all language implementations to use shared location
12. [ ] Add CI/CD to auto-sync metadata weekly

---

## 7. Testing Checklist

### Phase 1 Testing (Sync Functions)
- [x] Python: Test `sync_metadata()` generates correct watermark ✅
- [x] Python: Test `sync_all()` creates all 6 YAML files ✅
- [x] R: Test `sync_metadata()` generates correct watermark ✅
- [x] R: Test all 6 YAML files created ✅
- [ ] Stata: Test `unicefdata_sync` generates correct watermark (needs Stata runtime)
- [ ] Cross-platform: Verify YAML files have consistent structure

### Phase 2 Testing (Age Warnings)
- [ ] Python: Test `get_unicef()` shows age warning for old metadata
- [ ] R: Test `get_unicef()` shows age warning for old metadata
- [ ] Stata: Test `unicefdata` shows age warning for old metadata

---

## 8. Documentation Updates

- [ ] R: Update `man/sync_metadata.Rd`
- [ ] Python: Update docstrings and README
- [ ] Stata: Update `unicefdata.sthlp` with metadata section
- [ ] Main README: Add metadata management section

---

## Notes

- Stata implementation depends on `yaml.ado` package (v1.3.0+)
- Consider using `ruamel.yaml` in Python to preserve comments/formatting
- R `yaml` package handles comments via `handlers` argument
- All timestamps should be UTC in ISO 8601 format

---

## Related Files

| Language | Sync Function | Data Function | Metadata Location |
|----------|---------------|---------------|-------------------|
| R | `R/metadata.R::sync_metadata()` | `R/get_unicef.R` | `R/metadata/current/` |
| Python | `python/unicef_api/metadata.py::sync_all()` | `python/unicef_api/api.py` | `python/metadata/current/` |
| Stata | `stata/src/u/unicefdata_sync.ado` | `stata/src/u/unicefdata.ado` | `stata/metadata/` |

