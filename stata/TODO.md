# Stata `unicefdata` Implementation TODO

## Phase 1: Discovery Functions (HIGH Priority)

### 1.1 List Dataflows Subcommand
- [x] Create `_unicef_list_dataflows.ado` helper program
- [x] Parse `dataflows.yaml` to display available dataflows
- [x] Add `flows` option to main `unicefdata.ado` syntax
- [x] Display as formatted table (ID, Name, Version)
- [x] Add return values (`r(dataflows)`, `r(n_dataflows)`)
- [x] Test with `unicefdata, flows`

### 1.2 Search Indicators Subcommand
- [x] Create `_unicef_search_indicators.ado` helper program
- [x] Load indicators from `indicators.yaml`
- [x] Implement case-insensitive keyword search
- [x] Search in both indicator code and name
- [x] Add `search(string)` option to main syntax
- [x] Display results with indicator, name, dataflow columns
- [x] Add `limit(n)` option for max results
- [x] Test with `unicefdata, search("mortality")`

### 1.3 List Indicators in Dataflow
- [x] Create `_unicef_list_indicators.ado` helper program
- [x] Filter indicators.yaml by dataflow
- [x] Add `indicators(dataflow)` option to main syntax
- [x] Display indicator list for specific dataflow
- [x] Test with `unicefdata, indicators(CME)`

### 1.4 Get Indicator Info
- [x] Create `_unicef_indicator_info.ado` helper program
- [x] Display full metadata for single indicator
- [x] Show: code, name, dataflow, description, dimensions
- [x] Add `info(indicator)` option to main syntax
- [x] Test with `unicefdata, info(CME_MRY0T4)`

## Phase 2: Enhanced Output (MEDIUM Priority)

### 2.1 Wide Indicators Format
- [x] Add `wide_indicators` option to syntax
- [x] Implement reshape: indicators become columns
- [x] Handle column naming (remove "value" prefix)
- [x] Filter to totals before reshape to avoid conflicts
- [x] Test with multiple indicators
- [x] Update help file

### 2.2 Metadata Enrichment
- [x] Create metadata lookup in main ado file
  - [x] Include: iso3, region, income_group, continent
  - [x] Source from World Bank/UNICEF classifications
- [x] Add `addmeta(string)` option to syntax
- [x] Implement merge after data retrieval
- [x] Support: region, income_group, continent
- [x] Test with `unicefdata, indicator(CME_MRY0T4) addmeta(region)`

### 2.3 Geo Type Classification
- [x] Add `geo_type` variable after data retrieval
- [x] Classify: "country" vs "aggregate"
- [x] Use ISO3 validation or known aggregate list
- [x] Add variable label

### 2.4 Dataflow Fallback on 404
- [x] Create `_unicef_fetch_with_fallback.ado` helper
- [x] Define alternative dataflows by prefix
- [x] Try alternatives when primary returns 404
- [x] Log which dataflow succeeded
- [x] Update verbose output
- [x] Add `fallback` and `nofallback` options

## Phase 3: Additional Features (LOW Priority)

### 3.1 Wide Sex/Age Formats
- [ ] Add `wide_sex` option
- [ ] Add `wide_age` option
- [ ] Implement reshape for disaggregation pivots

### 3.2 Session Caching
- [ ] Track downloaded data in global macros
- [ ] Check cache before API call
- [ ] Add `nocache` option to force fresh fetch
- [ ] Add `clearcache` option

### 3.3 Vintage Commands
- [ ] Add `vintage list` subcommand
- [ ] Add `vintage compare(v1 v2)` subcommand

## Testing & Documentation

### Tests
- [x] Create `tests/test_new_features.do` - Tests helper programs directly
- [x] Create `tests/test_integrated_features.do` - Tests via main command
- [ ] Create additional edge case tests
- [ ] Run validation against Python/R outputs

### Documentation
- [x] Update `unicefdata.sthlp` help file
- [x] Add examples for all new features
- [ ] Update README.md with new syntax

---

## Progress Tracking

| Task | Status | Date |
|------|--------|------|
| 1.1 List Dataflows | ✅ Complete | 2025-12-09 |
| 1.2 Search Indicators | ✅ Complete | 2025-12-09 |
| 1.3 List Indicators | ✅ Complete | 2025-12-09 |
| 1.4 Indicator Info | ✅ Complete | 2025-12-09 |
| 2.1 Wide Indicators | ✅ Complete | 2025-12-09 |
| 2.2 Metadata Enrichment | ✅ Complete | 2025-12-09 |
| 2.3 Geo Type | ✅ Complete | 2025-12-09 |
| 2.4 Dataflow Fallback | ✅ Complete | 2025-12-09 |
| Documentation | ✅ Complete | 2025-12-09 |

Legend: ⬜ Not Started | 🔄 In Progress | ✅ Complete | ❌ Blocked
