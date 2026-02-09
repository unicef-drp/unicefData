# Issue Responses for unicefData Repository

---

## Issue #24: Documentation & Navigation Improvements

### Response to Post

Great news! The navigation improvements from this issue have been **partially addressed in v2.1.0** (released February 8, 2026).

### ✅ Completed in v2.1.0

**File Navigation & Structure:**
- ✅ Added comprehensive section headers to `unicefData.R` and `unicef_core.R`
- ✅ Implemented numbered sections (1-7) for RStudio document outline
- ✅ Created logical code organization with clear section markers
- ✅ Enhanced file headers with PURPOSE and STRUCTURE documentation

**Example of new structure:**
```r
# =============================================================================
# unicefData.R - R interface to UNICEF SDMX Data API
# =============================================================================
# STRUCTURE:
#   1. Imports & Setup - Package dependencies and operators
#   2. Utilities - Year parsing, circa matching helpers
#   3. SDMX Fetchers - Low-level HTTP and flow listing
#   4. Main API - unicefData() entry point
#   5. Post-Processing - Metadata, MRV, latest, format transforms
#   6. Reference Data - Region/income/continent mappings
#   7. Convenience Wrappers - Python-compatible aliases
# =============================================================================
```

**Related PR #28:**
PR #28 (which addressed navigation) has been superseded by v2.1.0 improvements. The navigation enhancements are now in production with additional refinements.

### ⏳ Remaining Work

**Roxygen Standardization:**
- Some functions have enhanced roxygen (e.g., `metadata_sync.R`)
- Full standardization across all functions still pending

### 📋 Next Steps

1. **Close navigation portion** - File navigation is complete ✅
2. **Keep open for roxygen work** - Standardizing function documentation
3. **Create checklist** - Track which functions need roxygen updates
4. **Consider PR template** - Require roxygen docs for new functions

### 🏷️ Suggested Labels
- `documentation`
- `in-progress`
- `help wanted` (for roxygen standardization)

---

**Status Update:** Partially complete - navigation done, roxygen standardization ongoing

**Links:**
- v2.1.0 Release: https://github.com/unicef-drp/unicefData/releases/tag/v2.1.0
- CONTRIBUTING.md: See repository root

---

## Issue #26: Indicator Map Function (Shapefile Export)

### Response to Post

Thank you for this feature request! Adding shapefile export functionality would be valuable for spatial analysis workflows.

### 🎯 Request Summary

**Requested functionality:**
- Input: List of indicators, countries, and years
- Output: Shapefile with indicator values

### 📊 Related Progress in v2.1.0

While we haven't added shapefile export yet, v2.1.0 includes **metadata enhancements** that lay groundwork:

**New in v2.1.0:**
- ✅ Region classification support (UNICEF regions)
- ✅ Income group support (World Bank classification)
- ✅ Continent metadata
- ✅ Multiple metadata combinations

**Stata example:**
```stata
unicefdata, indicator(CME_MRY0T4) addmeta(region income_group continent) latest
```

**Python/R:** Similar metadata enrichment available

### 🔄 Implementation Considerations

**For shapefile export, we'd need to decide:**

1. **Dependency approach:**
   - Add `sf` package dependency (R)
   - Add `geopandas` (Python)
   - Add Stata geospatial commands

2. **Geometry source:**
   - Bundle country boundaries (increases package size)
   - Fetch from external source (e.g., Natural Earth)
   - Require user to provide geometry

3. **Function signature:**
   ```r
   # Possible R implementation
   unicefData_spatial(
     indicator = c("CME_MRY0T4", "NT_ANT_HAZ_NE2"),
     countries = c("ALB", "USA", "BRA"),
     year = 2020,
     geometry_source = "naturalearth",  # or user-provided
     output_format = "sf"  # or "shapefile", "geojson"
   )
   ```

### 💡 Recommended Approach

**Phase 1 (v2.2.0 candidate):**
1. Add `add_geometry = TRUE` parameter to `unicefData()`
2. Return `sf` object with country boundaries joined
3. User can save as shapefile with `st_write()`

**Example:**
```r
df_spatial <- unicefData(
  indicator = "CME_MRY0T4",
  countries = c("ALB", "BRA", "USA"),
  year = 2020,
  add_geometry = TRUE
)

# User saves as needed
sf::st_write(df_spatial, "output.shp")
```

**Advantages:**
- Flexible output format (sf object can export to many formats)
- User controls file location and format
- Smaller scope for initial implementation

### 📋 Next Steps

1. **Gather requirements** - What geometry resolution needed? (country-level sufficient?)
2. **Choose geometry source** - Natural Earth? Built-in?
3. **Prototype in R** - Test with `sf` package
4. **Extend to Python** - Use `geopandas`
5. **Document examples** - Show spatial visualization workflows

### 🏷️ Suggested Labels
- `enhancement`
- `feature request`
- `spatial analysis`
- `help wanted`

### 🗳️ Community Input

Would you prefer:
- **Option A:** Built-in shapefile export function
- **Option B:** Return spatial object (user exports as needed)
- **Option C:** Separate package (`unicefDataGeo`) for spatial functions

Please comment with your preference!

---

**Status:** Feature request - planned for future release (v2.2.0 candidate)

**Assignee:** Unassigned - seeking contributor

---

## Issue #27: data.table Backend Performance Exploration

### Response to Post

Thank you for proposing this performance exploration, @lucashertzog!

### 🎯 Proposal Summary

Experiment with `data.table` backend instead of `dplyr` to assess:
- Performance improvements
- Memory efficiency gains

### 📊 Current State (v2.1.0)

**Backend:** `dplyr` + `magrittr` (`%>%`)

**Performance characteristics:**
- Works well for typical use cases (hundreds to thousands of rows)
- Not optimized for very large datasets (>1M rows)

### 🔬 Suggested Benchmarking Approach

**Test Scenarios:**

1. **Small dataset** (100 rows, 10 cols)
2. **Medium dataset** (10K rows, 20 cols)
3. **Large dataset** (1M rows, 30 cols)
4. **Wide dataset** (1K rows, 100 cols)

**Operations to benchmark:**
- Filtering by country/year
- Pivoting (long ↔ wide)
- Metadata joins
- Aggregations (latest value, MRV)

**Example benchmark structure:**
```r
library(bench)
library(data.table)
library(dplyr)

# Current dplyr approach
benchmark_dplyr <- function(df) {
  df %>%
    filter(iso3 %in% c("ALB", "USA")) %>%
    filter(year >= 2015) %>%
    group_by(iso3) %>%
    slice_max(year, n = 1)
}

# Proposed data.table approach
benchmark_dt <- function(df) {
  dt <- as.data.table(df)
  dt[iso3 %in% c("ALB", "USA") & year >= 2015,
     .SD[which.max(year)],
     by = iso3]
}

# Run benchmarks
results <- bench::mark(
  dplyr = benchmark_dplyr(test_data),
  dt = benchmark_dt(test_data),
  iterations = 100
)
```

### 💭 Considerations

**Pros of data.table:**
- ✅ Faster for large datasets
- ✅ Lower memory usage
- ✅ Reference semantics (modify in-place)

**Cons of data.table:**
- ❌ Steeper learning curve
- ❌ Different syntax (less "tidy")
- ❌ Additional dependency

**Hybrid approach (recommended):**
- Keep `dplyr` for small/medium datasets
- Use `data.table` backend for large datasets (threshold: 100K rows?)
- Auto-switch based on data size

### 📋 Next Steps

1. **Create benchmark script** - Test current performance
2. **Implement data.table prototype** - Core operations only
3. **Compare results** - Speed, memory, readability
4. **Document findings** - Share results in issue
5. **Decision point** - Keep dplyr, switch to dt, or hybrid?

### 🎯 Success Criteria

Worth switching if:
- ✅ >2x speed improvement on typical datasets
- ✅ >30% memory reduction
- ✅ Minimal code complexity increase

### 🏷️ Suggested Labels
- `performance`
- `enhancement`
- `research`
- `good first issue` (for benchmarking)

### 📝 Recommendation

**Start with benchmarking:**
1. Create `benchmarks/` directory
2. Add benchmark scripts
3. Run on realistic UNICEF datasets
4. Share results before full implementation

If you'd like to proceed, I can help review benchmark code and implementation PRs!

---

**Status:** Open for exploration - benchmarking phase

**Assignee:** @lucashertzog

**Milestone:** v2.2.0 (if results are positive)

---

## Issue #30: Dataflow Download Problems (HTTP 400 & Pagination)

### Response to Post

Thank you for reporting these critical bugs! These issues affect core functionality and need immediate attention.

### 🔴 Critical Issues Identified

**Issue 1: HTTP 400 Error**
```r
# Fails with HTTP 400
unicefData_raw(dataflow = "CME")

# Works correctly
get_sdmx(flow = "CME")
```

**Issue 2: Infinite Pagination Loop**
- API returns all 79,602 rows in first page
- But function keeps requesting subsequent pages
- Each page returns duplicate data
- Loop never terminates

### 📊 v2.1.0 Status

**What was NOT fixed:**
- ❌ HTTP 400 error remains
- ❌ Pagination logic still broken

**What WAS improved:**
- ✅ Better error messages (404s now include tried dataflows)
- ✅ Enhanced test coverage

### 🔍 Root Cause Analysis

**HTTP 400 Issue:**
Likely caused by:
- Incorrect URL construction in `unicefData_raw()`
- Missing/incorrect query parameters
- API endpoint differences

**Pagination Issue:**
```r
# Problem: API ignores startPeriod/endPeriod parameters
# Returns all data regardless of pagination params
# Function doesn't detect "all data received" condition
```

### 💡 Proposed Solutions

**Fix 1: HTTP 400 Error**
```r
# Before (broken)
unicefData_raw(dataflow = "CME")
# URL: .../data/CME (missing required params?)

# After (should work)
unicefData_raw(dataflow = "CME", ...)
# URL: .../data/CME/... (correct endpoint)
```

**Fix 2: Pagination Logic**
```r
# Add termination conditions:
while (has_more_data && page < max_pages) {
  response <- fetch_page(page)

  # Check if we got new data
  if (nrow(response) == 0) break
  if (identical(response, previous_response)) break  # Duplicate detection
  if (nrow(all_data) >= total_count) break  # Got everything

  all_data <- rbind(all_data, response)
  page <- page + 1
}
```

### 🚨 Urgency & Impact

**Severity:** 🔴 **CRITICAL**
- Affects core dataflow download functionality
- Infinite loop can hang user sessions
- HTTP 400 blocks entire workflow

**Users affected:** Anyone downloading whole dataflows

**Workaround:** Use `get_sdmx(flow = "CME")` instead of `unicefData_raw()`

### 📋 Immediate Actions Needed

1. **Verify the fix** - You mentioned having a fix ready
2. **Review fix in `develop` branch** - Can you point to the commit/PR?
3. **Add regression tests** - Prevent future breakage
4. **Document workaround** - Until fix is released

### 🧪 Test Cases to Add

```r
test_that("unicefData_raw handles full dataflow download", {
  # Should not error with HTTP 400
  result <- unicefData_raw(dataflow = "CME")
  expect_true(nrow(result) > 0)
})

test_that("pagination terminates correctly", {
  # Should not loop infinitely
  result <- fetch_with_pagination("CME", page_size = 10000)
  expect_true(nrow(result) == total_expected_rows)
})
```

### 📝 Release Plan

**Urgent fix candidate for v2.1.1 (patch release):**
- Fix HTTP 400 error
- Fix pagination loop
- Add regression tests
- Release within 1 week

### 🏷️ Suggested Labels
- `bug`
- `priority: high`
- `needs: review`
- `affects: core functionality`

### 🤝 Next Steps

**Can you provide:**
1. Link to your fix in `develop` branch?
2. Steps to reproduce the issues?
3. Expected vs actual behavior details?

I'm ready to review and help merge the fix ASAP!

---

**Status:** 🔴 Critical bug - fix ready for review

**Priority:** HIGH - target v2.1.1 patch release

**Assignee:** @liuyanguu (has fix ready)

---

