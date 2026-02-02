# XVAL - Cross-Platform Validation Framework

Deterministic, reliable cross-platform testing for UNICEF indicator data across Python, R, and Stata.

## Key Differences from `core_validation`

| Feature | core_validation | xval |
|---------|-----------------|------|
| Indicator pool | All 738+ from API | 25 curated "golden" indicators |
| Expected outcome | Some failures OK | Should ALWAYS pass |
| Column comparison | All columns | Core columns only |
| Row tolerance | Exact match | ±5% tolerance |
| Purpose | Discovery/exploration | Regression testing/CI |

## Quick Start

```bash
# Test all 25 golden indicators
python validation/xval/run_xval.py

# Quick smoke test (5 critical indicators)
python validation/xval/run_xval.py --quick

# Test specific indicator
python validation/xval/run_xval.py --indicator CME_MRY0T4

# Skip Stata (faster)
python validation/xval/run_xval.py --platforms python r

# Force fresh fetch (ignore cache)
python validation/xval/run_xval.py --force-fresh

# Use predefined filter presets for stable tests
python validation/xval/run_xval.py --preset minimal     # 5 countries, 3 years
python validation/xval/run_xval.py --preset standard    # 10 countries, 6 years

# Custom filters
python validation/xval/run_xval.py --countries USA GBR IND --start-year 2015 --end-year 2020
```

## Query Parameters

All three platforms (Python, R, Stata) support consistent query parameters for filtering data.

### Year Parameter

The `year` parameter supports three formats, handled identically across all platforms:

| Format | Meaning | Python | R | Stata |
|--------|---------|--------|---|-------|
| **Single** | Just one year | `year=2015` | `year=2015` | `year(2015)` |
| **Range** | All years between start:end | `year="2015:2020"` or `year=(2015,2020)` | `year="2015:2020"` | `year(2015:2020)` |
| **List** | Only specific years | `year="2015,2018,2020"` or `year=[2015,2018,2020]` | `year="2015,2018,2020"` or `year=c(2015,2018,2020)` | `year(2015,2018,2020)` |
| **All** | No filter (all years) | `year=None` | `year=NULL` | *(omit option)* |

**Examples:**
- `year=2020` → Only 2020
- `year="2015:2020"` → 2015, 2016, 2017, 2018, 2019, 2020 (6 years)
- `year="2015,2020"` → Only 2015 and 2020 (2 years)

### Other Parameters

| Parameter | Default | Python | R | Stata |
|-----------|---------|--------|---|-------|
| countries | All | `countries=["USA","GBR"]` | `countries=c("USA","GBR")` | `countries(USA GBR)` |
| format | long | `format="wide"` | `format="wide"` | `wide` |
| sex | _T (total) | `sex="_T"` | `sex="_T"` | `sex(_T)` |
| totals | False | `totals=False` | `totals=FALSE` | `nosparse` |

### Per-Indicator Query Filters

Each indicator in `golden_indicators.yaml` can define its own query filters:

```yaml
NT_ANT_HAZ_NE2:
  name: "Stunting prevalence"
  query_filters:
    years: {start: 2015, end: 2023}  # Range filter
    countries: null                   # All countries
    data_format: long

CME_MRY0T4:
  query_filters: null  # Uses global defaults (all data)
```

Filter priority:
1. Per-indicator `query_filters` (if defined)
2. CLI arguments (`--preset`, `--countries`, `--start-year`, etc.)
3. Global config in `test_config` section
4. No filter = fetch all data

## Files

```
xval/
├── README.md                 # This file
├── golden_indicators.yaml    # Curated indicator definitions
├── run_xval.py              # Main runner script
└── results/                  # Output directory
    └── YYYYMMDD_HHMMSS/
        ├── SUMMARY.md       # Human-readable report
        └── results.json     # Machine-readable results
```

## Golden Indicators

The `golden_indicators.yaml` file contains ~25 indicators that are:

1. **Verified** - Manually confirmed to return data on all platforms
2. **Representative** - Cover key dataflows (CME, NT, IM, ED, etc.)
3. **Stable** - Not deprecated or frequently renamed

### Priority Levels

- **critical** (5): Core indicators that must always work
- **high** (12): Important indicators for comprehensive testing
- **medium** (8): Additional coverage indicators

### Adding New Golden Indicators

Before adding an indicator to `golden_indicators.yaml`:

1. Verify it returns data in Python: `unicefData(indicator="XXX")`
2. Verify it returns data in R: `unicefData(indicator = "XXX")`
3. Verify it returns data in Stata: `unicefdata, indicator(XXX)`
4. Confirm row counts are similar (±5%) across platforms
5. Add entry with appropriate priority level
6. Define expected columns (required, optional, indicator_specific)

### Expected Columns Configuration

Each indicator can define expected columns:

```yaml
CME_MRY0T4:
  name: "Under-five mortality rate"
  dataflow: CME
  expected_rows_min: 5000
  priority: critical
  expected_columns:
    required: [iso3, country, period, indicator, value, sex]  # MUST be present
    optional: [lower_bound, upper_bound, obs_status]           # Nice to have
    indicator_specific: []                                      # Domain columns
```

- **required**: Test FAILS if any platform is missing these
- **optional**: Logged as warning, but test passes
- **indicator_specific**: Domain-specific columns (e.g., `vaccine` for immunization)

## Consistency Rules

xval considers platforms **consistent** when:

1. **Row counts match** within ±5% tolerance
2. **Required columns present** (per-indicator, defined in golden_indicators.yaml)

### Column Validation Levels

| Level | Columns | On Missing |
|-------|---------|------------|
| **critical** | iso3, country, period, indicator, value | Test FAILS |
| **required** | Indicator-specific (e.g., `sex` for CME) | Test FAILS |
| **optional** | Common extras (e.g., `lower_bound`) | Warning only |
| **indicator_specific** | Domain columns (e.g., `vaccine`, `ecd_domain`) | Informational |

These are **NOT considered failures**:
- Different total column counts (platforms have different metadata)
- Missing optional or indicator-specific columns
- Column ordering differences

## Integration with CI

xval is designed for CI pipelines:

```yaml
# GitHub Actions example
- name: Run xval quick test
  run: |
    cd validation
    python xval/run_xval.py --quick --platforms python r
```

Exit codes:
- `0` = All indicators consistent
- `1` = One or more inconsistencies (indicates a bug)

## Relationship to Other Tests

```
┌─────────────────────────────────────────────────────────────┐
│                    Testing Hierarchy                         │
├─────────────────────────────────────────────────────────────┤
│  Level 1: Unit Tests                                        │
│  - python/tests/test_*.py (pytest)                          │
│  - tests/testthat/test-*.R (testthat)                       │
│  - Fast, isolated, mock API responses                       │
├─────────────────────────────────────────────────────────────┤
│  Level 2: Integration Tests                                 │
│  - R/tests/run_tests.R                                      │
│  - python/tests/run_tests.py                                │
│  - Test actual API calls, single platform                   │
├─────────────────────────────────────────────────────────────┤
│  Level 3: XVAL (Cross-Platform)  <-- YOU ARE HERE           │
│  - validation/xval/run_xval.py                              │
│  - Golden indicators, all platforms, deterministic          │
├─────────────────────────────────────────────────────────────┤
│  Level 4: Discovery/Exploration                             │
│  - validation/scripts/core_validation/                      │
│  - All 738 indicators, find new working ones                │
└─────────────────────────────────────────────────────────────┘
```

## Troubleshooting

### "Indicator not found" on all platforms

The indicator may have been deprecated. Check the UNICEF SDMX API directly:
```
https://sdmx.data.unicef.org/ws/public/sdmxapi/rest/data/UNICEF,CME,1.0/XXX
```

### Row count mismatch > 5%

Check filtering defaults:
- Python: `totals=False` by default
- R: `totals=FALSE` by default
- Stata: Check `nosparse` option

### Stata "not found" but Python/R work

Stata metadata may be stale. Run:
```stata
unicefdata_sync
```

### Adding Stata support to CI

Stata requires a license. For CI without Stata:
```bash
python run_xval.py --platforms python r
```
