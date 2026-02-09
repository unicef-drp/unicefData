# Respond to Issues - Quick Action Guide

**Copy-paste these responses directly to GitHub**

---

## 🔴 Issue #30 - CRITICAL (Do This First!)

**URL:** https://github.com/unicef-drp/unicefData/issues/30

**Click:** "Comment" button at bottom

**Paste this:**

```markdown
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

### 🚨 Urgency & Impact

**Severity:** 🔴 **CRITICAL**
- Affects core dataflow download functionality
- Infinite loop can hang user sessions
- HTTP 400 blocks entire workflow

**Users affected:** Anyone downloading whole dataflows

**Workaround:** Use `get_sdmx(flow = "CME")` instead of `unicefData_raw()`

### 📋 Immediate Actions

1. **Verify the fix** - You mentioned having a fix ready
2. **Can you point to the commit/PR?**
3. **Add regression tests** - Prevent future breakage

### 🏷️ Labels Added
- `priority: high`
- `type: bug`
- `component: r`
- `component: api`
- `status: needs-review`

### 📝 Release Plan

**Urgent fix candidate for v2.1.1 (patch release):**
- Fix HTTP 400 error
- Fix pagination loop
- Add regression tests
- Release within 1 week

**Can you provide:**
1. Link to your fix in `develop` branch?
2. Steps to reproduce the issues?
3. Expected vs actual behavior details?

I'm ready to review and help merge the fix ASAP!
```

**Then:** Add labels (priority: high, type: bug, component: r, component: api)

---

## 🟡 Issue #24 - Documentation

**URL:** https://github.com/unicef-drp/unicefData/issues/24

**Click:** "Comment" button

**Paste this:**

```markdown
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
#   1. Imports & Setup
#   2. Utilities
#   3. SDMX Fetchers
#   4. Main API
#   5. Post-Processing
#   6. Reference Data
#   7. Convenience Wrappers
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

**Status Update:** Partially complete - navigation done, roxygen standardization ongoing

**Links:**
- v2.1.0 Release: https://github.com/unicef-drp/unicefData/releases/tag/v2.1.0
```

**Then:** Add labels (priority: medium, type: documentation, status: in-progress, help wanted)

---

## 🔵 Issue #27 - Performance

**URL:** https://github.com/unicef-drp/unicefData/issues/27

**Click:** "Comment" button

**Paste this:**

```markdown
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

### 💭 Considerations

**Pros of data.table:**
- ✅ Faster for large datasets
- ✅ Lower memory usage

**Cons of data.table:**
- ❌ Steeper learning curve
- ❌ Different syntax (less "tidy")

**Hybrid approach (recommended):**
- Keep `dplyr` for small/medium datasets
- Use `data.table` backend for large datasets (threshold: 100K rows?)
- Auto-switch based on data size

### 📋 Next Steps

1. **Create benchmark script** - Test current performance
2. **Implement data.table prototype** - Core operations only
3. **Compare results** - Speed, memory, readability
4. **Document findings** - Share results in issue

### 🎯 Success Criteria

Worth switching if:
- ✅ >2x speed improvement on typical datasets
- ✅ >30% memory reduction
- ✅ Minimal code complexity increase

If you'd like to proceed, I can help review benchmark code and implementation PRs!
```

**Then:** Add labels (priority: low, type: performance, type: research, component: r, good first issue)

---

## 🔵 Issue #26 - Feature Request

**URL:** https://github.com/unicef-drp/unicefData/issues/26

**Click:** "Comment" button

**Paste this:**

```markdown
Thank you for this feature request! Adding shapefile export functionality would be valuable for spatial analysis workflows.

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

1. **Gather requirements** - What geometry resolution needed?
2. **Choose geometry source** - Natural Earth? Built-in?
3. **Prototype in R** - Test with `sf` package
4. **Extend to Python** - Use `geopandas`
5. **Document examples** - Show spatial visualization workflows

### 🗳️ Community Input

Would you prefer:
- **Option A:** Built-in shapefile export function
- **Option B:** Return spatial object (user exports as needed)
- **Option C:** Separate package (`unicefDataGeo`) for spatial functions

Please comment with your preference!

**Status:** Feature request - planned for future release (v2.2.0 candidate)
```

**Then:** Add labels (priority: medium, type: feature, component: r, component: python, help wanted)

---

## 🔒 PR #28 - Close as Superseded

**URL:** https://github.com/unicef-drp/unicefData/pull/28

**Click:** Comment box at bottom

**Paste:** Full text from `PR28_CLOSING_COMMENT.md`

**Then:** Click "Close pull request" button

---

## ✅ After Posting All Responses

1. **Create Milestones:**
   - Go to: https://github.com/unicef-drp/unicefData/milestones/new
   - Create "v2.1.1" (due in 1 week) - assign Issue #30
   - Create "v2.2.0" (due March 31, 2026) - assign Issues #24, #26, #27

2. **Verify Labels:**
   - Each issue should have appropriate labels added
   - Create any missing labels from ISSUE_MANAGEMENT_PLAN.md

---

**Total time:** 20-30 minutes to post all responses

**Let me know when you're done, or if you need help with any specific issue!**
