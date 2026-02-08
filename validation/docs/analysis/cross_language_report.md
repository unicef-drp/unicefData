# Cross-Language Validation Report

**Comparing:** python vs r
**Generated:** 2025-12-09 16:57:20

## Summary

| File | Status | Rows | Columns | Core Data | Values |
|------|--------|------|---------|-----------|--------|
| 00_ex1_mortality.csv | PASS | 27 | ✓ | ✓ | ✓ |
| 00_ex2_mult_mortality.csv | PASS | 996 | ✓ | ✓ | ✓ |
| 01_ex6_dataflows.csv | WARN | 69 | ✓ | ✓ | ⚠ 1 |
| 02_ex1_child_mortality.csv | PASS | 126 | ✓ | ✓ | ✓ |
| 02_ex2_nutrition.csv | PASS | 161 | ✓ | ✓ | ✓ |
| 02_ex3_education.csv | PASS | 190 | ✓ | ✓ | ✓ |
| 02_ex4_child_marriage.csv | WARN | 10 | ✓ | ✓ | ⚠ 1 |
| 02_ex5_wash.csv | PASS | 130 | ✓ | ✓ | ✓ |

## Detailed Findings

### 00_ex1_mortality.csv

**Status:** PASS

### 00_ex2_mult_mortality.csv

**Status:** PASS

### 01_ex6_dataflows.csv

**Status:** WARN

**Value Differences:**
| Column | Type | Count | Details |
|--------|------|-------|---------|
| name | string | 69 |   |

### 02_ex1_child_mortality.csv

**Status:** PASS

### 02_ex2_nutrition.csv

**Status:** PASS

**Case Differences:**
- `reporting_lvl` ↔ `REPORTING_LVL`
- `obs_footnote` ↔ `OBS_FOOTNOTE`
- `sowc_flag_a` ↔ `SOWC_FLAG_A`
- `data_source_priority` ↔ `DATA_SOURCE_PRIORITY`
- `publication_date` ↔ `PUBLICATION_DATE`
- `obs_conf` ↔ `OBS_CONF`
- `series_footnote` ↔ `SERIES_FOOTNOTE`
- `freq_coll` ↔ `FREQ_COLL`
- `indicator_metadata` ↔ `INDICATOR_METADATA`
- `unit_multiplier` ↔ `UNIT_MULTIPLIER`

### 02_ex3_education.csv

**Status:** PASS

**Case Differences:**
- `indicator_uis` ↔ `INDICATOR_UIS`
- `unit_multiplier` ↔ `UNIT_MULTIPLIER`

### 02_ex4_child_marriage.csv

**Status:** WARN

**Case Differences:**
- `sowc_flag_b` ↔ `SOWC_FLAG_B`
- `obs_footnote` ↔ `OBS_FOOTNOTE`
- `education_level` ↔ `EDUCATION_LEVEL`
- `religious_group` ↔ `RELIGIOUS_GROUP`
- `school_ed_level` ↔ `SCHOOL_ED_LEVEL`
- `m49` ↔ `M49`
- `ch_marriage_status` ↔ `CH_MARRIAGE_STATUS`
- `sowc_flag_a` ↔ `SOWC_FLAG_A`
- `ethnic_group` ↔ `ETHNIC_GROUP`
- `obs_conf` ↔ `OBS_CONF`

**Value Differences:**
| Column | Type | Count | Details |
|--------|------|-------|---------|
| obs_conf | string | 10 |   |

### 02_ex5_wash.csv

**Status:** PASS

**Case Differences:**
- `service_type` ↔ `SERVICE_TYPE`
- `obs_footnote` ↔ `OBS_FOOTNOTE`
- `obs_conf` ↔ `OBS_CONF`
- `series_footnote` ↔ `SERIES_FOOTNOTE`
- `freq_coll` ↔ `FREQ_COLL`
- `unit_multiplier` ↔ `UNIT_MULTIPLIER`
- `time_period_method` ↔ `TIME_PERIOD_METHOD`
- `source_link` ↔ `SOURCE_LINK`
- `coverage_time` ↔ `COVERAGE_TIME`


## Legend

- **PASS**: All checks passed
- **WARN**: Non-critical differences (column case, extra columns)
- **FAIL**: Core data mismatch (iso3, indicator, period, value)
- **SKIP**: File missing in one language
- **Core columns**: country, indicator, iso3, period, value
- **Ignored columns**: geo_type