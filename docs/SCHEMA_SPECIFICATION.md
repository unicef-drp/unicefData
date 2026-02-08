# UNICEF Data API: Cross-Platform Schema Specification

**Version**: 1.0.0
**Date**: 2026-01-31
**Status**: Draft
**Authors**: UNICEF Data Team

---

## Table of Contents

1. [Overview](#1-overview)
2. [Design Principles](#2-design-principles)
3. [Schema Levels](#3-schema-levels)
4. [Column Specifications](#4-column-specifications)
5. [Format Behaviors](#5-format-behaviors)
6. [Platform API Reference](#6-platform-api-reference)
7. [Migration Guide](#7-migration-guide)
8. [Appendix](#appendix)

---

## 1. Overview

### 1.1 Purpose

This document defines a unified column schema for UNICEF indicator data across three platforms:
- **Python** (`unicef_api` package)
- **R** (`unicefData` package)
- **Stata** (`unicefdata` command)

A consistent schema enables:
- **Data merging** across indicators and dataflows
- **Cross-platform reproducibility** of analyses
- **Automated validation** and testing
- **Interoperability** between tools and pipelines

### 1.2 Problem Statement

Without a unified schema, users encounter:

```stata
* Stata: 15 columns
unicefdata, indicator(CME_MRY0T4) clear
* Python: 21 columns
* R: 21 columns

* Merge FAILS due to column mismatch
append using other_indicator_data
```

### 1.3 Solution

A tiered schema system with explicit levels:

| Schema Level | Columns | Primary Use Case |
|--------------|---------|------------------|
| `minimal` | 5 | Quick lookups, dashboards |
| `standard` | 15 | Database storage, pipelines |
| `extended` | 21 | General analysis (default) |
| `full` | 30 | Publications, documentation |

---

## 2. Design Principles

### 2.1 Rectangular Guarantee

**All columns in a schema level are ALWAYS present**, even if empty.

```
# Indicator A has wealth data, Indicator B does not
# Both return the same columns - wealth_quintile is empty for B

Indicator A: iso3, country, ..., wealth_quintile, ...
Indicator B: iso3, country, ..., wealth_quintile, ...  (empty but present)
```

This enables safe appending/merging without column alignment issues.

### 2.2 Column Order Consistency

Columns appear in **identical order** across all platforms:

```
Position 1:  iso3
Position 2:  country
Position 3:  indicator
Position 4:  period
Position 5:  value
...
```

### 2.3 Naming Conventions

| Convention | Example | Rule |
|------------|---------|------|
| Lowercase | `iso3`, `country` | All column names lowercase |
| Underscores | `wealth_quintile` | Multi-word names use underscores |
| `_name` suffix | `sex_name` | Human-readable label for code column |
| No spaces | `maternal_edu_lvl` | Never use spaces in column names |

### 2.4 ID vs Label Columns

**ID columns** contain codes:
```
sex = "M", "F", "_T"
age = "Y0T4", "Y5T9", "_T"
```

**Label columns** contain human-readable text:
```
sex_name = "Male", "Female", "Total"
age_name = "0-4 years", "5-9 years", "Total"
```

**Rule**: Label columns are always paired with ID columns and use the `_name` suffix.

---

## 3. Schema Levels

### 3.1 Minimal Schema (5 columns)

**Purpose**: Absolute minimum for any data operation.

```
iso3, country, indicator, period, value
```

**Use cases**:
- Memory-constrained environments
- Simple country-level dashboards
- Quick data existence checks

**Limitations**:
- No disaggregation information
- No confidence intervals
- No source tracking

### 3.2 Standard Schema (15 columns)

**Purpose**: Complete analytical dataset with all disaggregation dimensions.

```
iso3, country, indicator, period, value,
geo_type, unit, sex, age, wealth_quintile,
residence, lower_bound, upper_bound, obs_status, data_source
```

**Use cases**:
- Database storage (normalized)
- Automated data pipelines
- Cross-platform validation
- Statistical analysis

**Characteristics**:
- All disaggregation IDs (no labels)
- Confidence intervals included
- Observation status for data quality
- Source tracking

### 3.3 Extended Schema (21 columns) — DEFAULT

**Purpose**: Self-documenting dataset for general analysis.

```
iso3, country, indicator, indicator_name, period, value,
geo_type, unit, unit_name, sex, age, wealth_quintile,
residence, maternal_edu_lvl, lower_bound, upper_bound,
obs_status, obs_status_name, data_source, ref_period, country_notes
```

**Use cases**:
- Interactive data exploration
- Report generation
- Sharing with collaborators
- Default output for most users

**Additions over Standard**:
- `indicator_name`: Human-readable indicator description
- `unit_name`: Unit of measurement text
- `obs_status_name`: Observation status description
- `maternal_edu_lvl`: Additional disaggregation dimension
- `ref_period`, `country_notes`: Contextual metadata

### 3.4 Full Schema (30 columns)

**Purpose**: Complete self-documenting dataset with all labels.

```
# Core (5)
iso3, country, indicator, period, value

# Indicator metadata (2)
indicator_name, indicator_category

# Geography (2)
geo_type, geo_type_name

# Measurement (6)
unit, unit_name, lower_bound, upper_bound, obs_status, obs_status_name

# Disaggregations - IDs (5)
sex, age, wealth_quintile, residence, maternal_edu_lvl

# Disaggregations - Labels (5)
sex_name, age_name, wealth_quintile_name, residence_name, maternal_edu_lvl_name

# Context (5)
data_source, ref_period, country_notes, time_detail, current_age
```

**Use cases**:
- Final publication datasets
- Non-technical users
- Archival/documentation
- Data dictionaries

**Characteristics**:
- Every ID column has its label counterpart
- Maximum self-documentation
- Largest file size

---

## 4. Column Specifications

### 4.1 Master Column Reference

| # | Column | Type | Schema | Description | Example |
|---|--------|------|--------|-------------|---------|
| 1 | `iso3` | str(3) | minimal+ | ISO 3166-1 alpha-3 country code | "ALB" |
| 2 | `country` | str | minimal+ | Country name (English) | "Albania" |
| 3 | `indicator` | str | minimal+ | UNICEF indicator code | "CME_MRY0T4" |
| 4 | `period` | num | minimal+ | Time period (decimal year) | 2020.0 |
| 5 | `value` | num | minimal+ | Observation value | 8.2 |
| 6 | `geo_type` | str | standard+ | Geographic level | "NATIONAL", "SUBNATIONAL" |
| 7 | `unit` | str | standard+ | Unit code | "RATE", "PERCENT" |
| 8 | `sex` | str | standard+ | Sex disaggregation code | "_T", "M", "F" |
| 9 | `age` | str | standard+ | Age group code | "Y0T4", "_T" |
| 10 | `wealth_quintile` | str | standard+ | Wealth quintile code | "Q1", "_T" |
| 11 | `residence` | str | standard+ | Residence type code | "URBAN", "RURAL", "_T" |
| 12 | `lower_bound` | num | standard+ | Lower confidence bound | 7.1 |
| 13 | `upper_bound` | num | standard+ | Upper confidence bound | 9.3 |
| 14 | `obs_status` | str | standard+ | Observation status code | "A", "E", "P" |
| 15 | `data_source` | str | standard+ | Data source name | "DHS 2019" |
| 16 | `indicator_name` | str | extended+ | Indicator description | "Under-5 mortality rate" |
| 17 | `unit_name` | str | extended+ | Unit description | "Deaths per 1,000 live births" |
| 18 | `maternal_edu_lvl` | str | extended+ | Maternal education code | "EDU_L1", "_T" |
| 19 | `obs_status_name` | str | extended+ | Status description | "Normal", "Estimated" |
| 20 | `ref_period` | str | extended+ | Reference period details | "2019-2020" |
| 21 | `country_notes` | str | extended+ | Country-specific notes | "Excludes region X" |
| 22 | `indicator_category` | str | full | Indicator category | "MORTALITY", "NUTRITION" |
| 23 | `geo_type_name` | str | full | Geography type label | "National", "Subnational" |
| 24 | `sex_name` | str | full | Sex label | "Male", "Female", "Total" |
| 25 | `age_name` | str | full | Age group label | "0-4 years" |
| 26 | `wealth_quintile_name` | str | full | Wealth label | "Poorest", "Richest" |
| 27 | `residence_name` | str | full | Residence label | "Urban", "Rural" |
| 28 | `maternal_edu_lvl_name` | str | full | Education label | "Primary", "Secondary" |
| 29 | `time_detail` | str | full | Time granularity | "Annual", "Monthly" |
| 30 | `current_age` | str | full | Current age indicator | "Y", "N" |

### 4.2 Column Membership by Schema

| Column | minimal | standard | extended | full |
|--------|:-------:|:--------:|:--------:|:----:|
| iso3 | ✓ | ✓ | ✓ | ✓ |
| country | ✓ | ✓ | ✓ | ✓ |
| indicator | ✓ | ✓ | ✓ | ✓ |
| period | ✓ | ✓ | ✓ | ✓ |
| value | ✓ | ✓ | ✓ | ✓ |
| geo_type | | ✓ | ✓ | ✓ |
| unit | | ✓ | ✓ | ✓ |
| sex | | ✓ | ✓ | ✓ |
| age | | ✓ | ✓ | ✓ |
| wealth_quintile | | ✓ | ✓ | ✓ |
| residence | | ✓ | ✓ | ✓ |
| lower_bound | | ✓ | ✓ | ✓ |
| upper_bound | | ✓ | ✓ | ✓ |
| obs_status | | ✓ | ✓ | ✓ |
| data_source | | ✓ | ✓ | ✓ |
| indicator_name | | | ✓ | ✓ |
| unit_name | | | ✓ | ✓ |
| maternal_edu_lvl | | | ✓ | ✓ |
| obs_status_name | | | ✓ | ✓ |
| ref_period | | | ✓ | ✓ |
| country_notes | | | ✓ | ✓ |
| indicator_category | | | | ✓ |
| geo_type_name | | | | ✓ |
| sex_name | | | | ✓ |
| age_name | | | | ✓ |
| wealth_quintile_name | | | | ✓ |
| residence_name | | | | ✓ |
| maternal_edu_lvl_name | | | | ✓ |
| time_detail | | | | ✓ |
| current_age | | | | ✓ |

### 4.3 Data Types

| Type | Description | Examples |
|------|-------------|----------|
| `str` | Character/string | "ALB", "Male" |
| `str(N)` | Fixed-length string | iso3 is always 3 characters |
| `num` | Numeric (float) | 8.2, 2020.0 |
| `int` | Integer | Row counts (internal only) |

### 4.4 Missing Value Conventions

| Platform | Numeric Missing | String Missing |
|----------|-----------------|----------------|
| Python | `np.nan` or `None` | `None` or `""` |
| R | `NA` | `NA` or `""` |
| Stata | `.` | `""` |

**Rule**: Empty columns contain platform-appropriate missing values, not dropped.

---

## 5. Format Behaviors

### 5.0 Format Naming Conventions (Cross-Platform Harmonization)

The following format options are **identical across all platforms**:

| Format | Description | Pivot Column | API Format | Python | R | Stata |
|--------|-------------|--------------|------------|--------|---|-------|
| `long` | One row per observation | *(none)* | CSV | ✓ | ✓ | ✓ |
| `wide` | Years become columns | period | **CSV-TS** | ✓ | ✓ | ✓ |
| `wide_indicators` | Indicators become columns | indicator | CSV + reshape | ✓ | ✓ | ✓ |
| `wide_attributes(var)` | Specified dimension becomes columns | user-specified | CSV + reshape | ✓ | ✓ | ✓ |

**Key alignment**: `wide` = `wide_years` = years as columns on **ALL platforms**.

#### API Format Details

**CSV API** (`format=csv`): Returns data in long format with one observation per row. All pivoting/reshaping is done **client-side** after data retrieval.

**CSV-TS API** (`format=csv-ts`): Returns data in time-series format with years as columns **directly from the API**. No client-side reshaping needed for year pivots.

| Format | API Used | Reshaping |
|--------|----------|-----------|
| `long` | CSV | None |
| `wide` | CSV-TS | None (years come as columns from API) |
| `wide_indicators` | CSV | Client-side reshape (indicator → columns) |
| `wide_attributes(var)` | CSV | Client-side reshape (dimension → columns) |

**Performance note**: `wide` is typically faster than other wide formats because the API returns pre-pivoted data. Other wide formats require downloading long data first, then reshaping locally.

#### The `wide_attributes()` Option

The `wide_attributes()` option provides flexible pivoting on any disaggregation dimension:

| Syntax | Pivot Dimension | Output Columns |
|--------|-----------------|----------------|
| `wide_attributes(sex)` | sex | value_T, value_M, value_F |
| `wide_attributes(age)` | age | value_Y0T4, value_Y5T9, ... |
| `wide_attributes(wealth_quintile)` | wealth | value_Q1, value_Q2, ..., value_Q5 |
| `wide_attributes(residence)` | residence | value_U, value_R, value_T |
| `wide_attributes(maternal_edu_lvl)` | maternal education | value_EDU_L1, value_EDU_L2, ... |
| `wide_attributes(sex wealth_quintile)` | compound | value_M_Q1, value_M_Q2, ..., value_F_Q5 |
| `wide_attributes(ALL)` | all dimensions | indicator_T, indicator_M_Q1, ... |

**Platform Syntax**:

```python
# Python
format="wide_attributes", pivot="sex"           # Pivot on sex
format="wide_attributes", pivot=["sex", "wealth_quintile"]  # Compound
```

```r
# R
format = "wide_attributes", pivot = "sex"
format = "wide_attributes", pivot = c("sex", "wealth_quintile")
```

```stata
* Stata
wide_attributes(sex)                            // Pivot on sex
wide_attributes(sex wealth_quintile)            // Compound pivot
wide_attributes                                 // All (backward compatible)
```

**Backward Compatibility (Python/R only)**:

In Python and R, the old `format="wide"` behavior (indicators as columns) is preserved as a **deprecated alias** during the transition period:

| Version | `format="wide"` behavior in Python/R |
|---------|--------------------------------------|
| 2.0 | Returns years as columns (new behavior), emits deprecation warning if old behavior was likely intended |
| 2.x | Same |
| 3.0 | Only new behavior, no warnings |

**Migration for Python/R users**:
- Old: `format="wide"` (indicators as columns) → New: `format="wide_indicators"`
- The new `format="wide"` now means years as columns (aligned with Stata)

### 5.1 LONG Format (Default)

Each row represents one observation: country × period × indicator × disaggregation combination.

**Syntax (all platforms)**:

```python
format="long"           # Python (default)
format = "long"         # R (default)
long                    # Stata (default)
```

#### Example: Extended Schema, Long Format

```
| iso3 | country | indicator  | indicator_name      | period | value | sex | age  | ... |
|------|---------|------------|---------------------|--------|-------|-----|------|-----|
| ALB  | Albania | CME_MRY0T4 | Under-5 mortality   | 2020   | 8.2   | _T  | Y0T4 | ... |
| ALB  | Albania | CME_MRY0T4 | Under-5 mortality   | 2020   | 9.1   | M   | Y0T4 | ... |
| ALB  | Albania | CME_MRY0T4 | Under-5 mortality   | 2020   | 7.3   | F   | Y0T4 | ... |
| ALB  | Albania | CME_MRM0   | Neonatal mortality  | 2020   | 5.1   | _T  | M0   | ... |
```

#### Column Behavior in Long Format

All columns are present according to schema level. No pivoting occurs.

### 5.2 WIDE Format (Time-Series) — Default Wide

Years become columns. Each row represents a country × indicator × disaggregation combination across time.

**Syntax (identical across all platforms)**:

```python
format="wide"           # Python
format = "wide"         # R
wide                    # Stata
```

#### Pivot Rules for wide

| Role | Columns |
|------|---------|
| **ID (row identifiers)** | iso3, country, indicator, sex, age, wealth_quintile, residence, maternal_edu_lvl |
| **Pivot (→ column names)** | period → yr2018, yr2019, yr2020, ... |
| **Value (→ cell values)** | value |
| **Metadata (first per group)** | unit_name, data_source, obs_status, geo_type |

#### Example: Extended Schema, Wide Format

**Input (Long)**:

```
| iso3 | country | indicator  | period | sex | value |
|------|---------|------------|--------|-----|-------|
| ALB  | Albania | CME_MRY0T4 | 2018   | _T  | 9.5   |
| ALB  | Albania | CME_MRY0T4 | 2019   | _T  | 8.8   |
| ALB  | Albania | CME_MRY0T4 | 2020   | _T  | 8.2   |
```

**Output (Wide)**:

```
| iso3 | country | indicator  | sex | yr2018 | yr2019 | yr2020 |
|------|---------|------------|-----|--------|--------|--------|
| ALB  | Albania | CME_MRY0T4 | _T  | 9.5    | 8.8    | 8.2    |
```

**Use case**: Time-series analysis, trend visualization, year-over-year comparisons.

**Note**: This format uses the SDMX CSV-TS API where years are returned as columns directly from the server (most performant wide format).

### 5.3 WIDE_INDICATORS Format (Cross-Indicator)

Indicators become columns. Disaggregations remain as row identifiers.

**Syntax (identical across all platforms)**:

```python
format="wide_indicators" # Python
format = "wide_indicators" # R
wide_indicators          // Stata
```

#### Pivot Rules for wide_indicators

| Role | Columns |
|------|---------|
| **ID (row identifiers)** | iso3, country, period, sex, age, wealth_quintile, residence, maternal_edu_lvl |
| **Pivot (→ column names)** | indicator |
| **Value (→ cell values)** | value |
| **Metadata (first per group)** | unit_name, data_source, obs_status, geo_type |
| **Bounds (pivoted with indicator)** | lower_bound → `{indicator}_lb`, upper_bound → `{indicator}_ub` |
| **Dropped** | indicator_name (redundant - now column header) |

#### Example: Extended Schema, Wide by Indicators

**Input (Long)**:

```
| iso3 | country | indicator  | indicator_name    | period | sex | value | lower_bound | upper_bound |
|------|---------|------------|-------------------|--------|-----|-------|-------------|-------------|
| ALB  | Albania | CME_MRY0T4 | Under-5 mortality | 2020   | _T  | 8.2   | 7.1         | 9.3         |
| ALB  | Albania | CME_MRM0   | Neonatal mort.    | 2020   | _T  | 5.1   | 4.2         | 6.0         |
```

**Output (Wide by Indicators)**:

```
| iso3 | country | period | sex | CME_MRY0T4 | CME_MRY0T4_lb | CME_MRY0T4_ub | CME_MRM0 | CME_MRM0_lb | CME_MRM0_ub |
|------|---------|--------|-----|------------|---------------|---------------|----------|-------------|-------------|
| ALB  | Albania | 2020   | _T  | 8.2        | 7.1           | 9.3           | 5.1      | 4.2         | 6.0         |
```

**Use case**: Cross-indicator analysis, correlation studies, comparing multiple outcomes.

#### Schema × Wide by Indicators

| Schema | ID Columns | Indicator Columns | Metadata Columns | Total Cols (2 indicators) |
|--------|------------|-------------------|------------------|---------------------------|
| minimal | 3 (iso3, country, period) | 2 | 0 | 5 |
| standard | 7 (+ sex, age, wealth, residence) | 2 + 4 bounds | 3 | 16 |
| extended | 8 (+ maternal_edu) | 2 + 4 bounds | 4 | 18 |
| full | 8 | 2 + 4 bounds | 4 | 18 (labels dropped) |

### 5.4 WIDE_ATTRIBUTES Format (Disaggregation Pivot)

The `wide_attributes(var)` option pivots one or more disaggregation dimensions into columns.

**Syntax**:

```python
# Python
format="wide_attributes", pivot="sex"                    # Single dimension
format="wide_attributes", pivot=["sex", "wealth_quintile"]  # Compound
```

```r
# R
format = "wide_attributes", pivot = "sex"
format = "wide_attributes", pivot = c("sex", "wealth_quintile")
```

```stata
* Stata
wide_attributes(sex)                    // Single dimension
wide_attributes(sex wealth_quintile)    // Compound pivot
wide_attributes                         // All dimensions (backward compatible)
```

#### Pivot Rules for wide_attributes(sex)

| Role | Columns |
|------|---------|
| **ID (row identifiers)** | iso3, country, indicator, indicator_name, period, age, wealth_quintile, residence, maternal_edu_lvl |
| **Pivot (→ column suffixes)** | sex → _T, _M, _F |
| **Value columns created** | value_T, value_M, value_F |
| **Bounds columns created** | lower_bound_T, lower_bound_M, lower_bound_F, upper_bound_T, ... |
| **Auto-dropped** | sex_name (if present in full schema - would create redundant columns) |

#### Example 1: Single Dimension — wide_attributes(sex)

**Input (Long)**:

```
| iso3 | country | indicator  | indicator_name    | period | sex | value | lower_bound |
|------|---------|------------|-------------------|--------|-----|-------|-------------|
| ALB  | Albania | CME_MRY0T4 | Under-5 mortality | 2020   | _T  | 8.2   | 7.1         |
| ALB  | Albania | CME_MRY0T4 | Under-5 mortality | 2020   | M   | 9.1   | 7.9         |
| ALB  | Albania | CME_MRY0T4 | Under-5 mortality | 2020   | F   | 7.3   | 6.1         |
```

**Output — wide_attributes(sex)**:

```
| iso3 | country | indicator  | indicator_name    | period | value_T | value_M | value_F |
|------|---------|------------|-------------------|--------|---------|---------|---------|
| ALB  | Albania | CME_MRY0T4 | Under-5 mortality | 2020   | 8.2     | 9.1     | 7.3     |
```

**Use case**: Gender parity analysis, sex-disaggregated comparisons.

#### Example 2: Compound Pivot — wide_attributes(sex wealth_quintile)

**Input (Long)**:

```
| iso3 | country | indicator  | period | sex | wealth_quintile | value |
|------|---------|------------|--------|-----|-----------------|-------|
| ALB  | Albania | CME_MRY0T4 | 2020   | M   | Q1              | 12.5  |
| ALB  | Albania | CME_MRY0T4 | 2020   | M   | Q5              | 6.2   |
| ALB  | Albania | CME_MRY0T4 | 2020   | F   | Q1              | 10.8  |
| ALB  | Albania | CME_MRY0T4 | 2020   | F   | Q5              | 5.1   |
```

**Output — wide_attributes(sex wealth_quintile)**:

```
| iso3 | country | indicator  | period | value_M_Q1 | value_M_Q5 | value_F_Q1 | value_F_Q5 |
|------|---------|------------|--------|------------|------------|------------|------------|
| ALB  | Albania | CME_MRY0T4 | 2020   | 12.5       | 6.2        | 10.8       | 5.1        |
```

**Use case**: Intersectional analysis, wealth × gender disparities.

#### Schema × Wide by Attributes

| Schema | ID Columns | Value Columns (3 sex levels) | Bounds Columns | Notes |
|--------|------------|------------------------------|----------------|-------|
| minimal | 4 | 3 | 0 | No sex column to pivot |
| standard | 6 | 3 | 6 | Works |
| extended | 8 | 3 | 6 | Works, keeps indicator_name |
| full | 8 | 3 | 6 | Auto-drops sex_name |

### 5.5 Label Column Handling in Wide Formats

**Problem**: Label columns (e.g., `sex_name`) create issues when pivoting by their paired ID column.

**Solution**: Auto-drop label columns when pivoting by their ID.

| Wide Format | Auto-Dropped Columns |
|-------------|---------------------|
| `wide_indicators` | indicator_name |
| `wide_attributes(sex)` | sex_name |
| `wide_attributes(age)` | age_name |
| `wide_attributes(wealth_quintile)` | wealth_quintile_name |
| `wide_attributes(residence)` | residence_name |
| `wide_attributes(maternal_edu_lvl)` | maternal_edu_lvl_name |

**Rule**: When using `schema="full"` with any wide format, the corresponding label column is automatically excluded from the output to prevent column explosion.

### 5.6 Format Compatibility Matrix

| Format | minimal | standard | extended | full |
|--------|:-------:|:--------:|:--------:|:----:|
| `long` | ✓ | ✓ | ✓ | ✓ |
| `wide` | ✓ | ✓ | ✓ | ✓ |
| `wide_indicators` | ✓ | ✓ | ✓ | ✓* |
| `wide_attributes(sex)` | ✗ | ✓ | ✓ | ✓* |
| `wide_attributes(age)` | ✗ | ✓ | ✓ | ✓* |
| `wide_attributes(wealth_quintile)` | ✗ | ✓ | ✓ | ✓* |
| `wide_attributes(residence)` | ✗ | ✓ | ✓ | ✓* |
| `wide_attributes(maternal_edu_lvl)` | ✗ | ✗ | ✓ | ✓* |

*With automatic label column dropping

---

## 6. Platform API Reference

### 6.1 Python

```python
from unicef_api import unicefData

# Schema parameter
df = unicefData(
    indicator="CME_MRY0T4",
    schema="extended",      # "minimal", "standard", "extended" (default), "full"
    format="long"           # "long" (default), "wide", "wide_indicators", "wide_attributes"
)

# Examples - Schema levels
df = unicefData("CME_MRY0T4")                           # Extended, long (21 cols)
df = unicefData("CME_MRY0T4", schema="minimal")         # Minimal, long (5 cols)
df = unicefData("CME_MRY0T4", schema="standard")        # Standard, long (15 cols)
df = unicefData("CME_MRY0T4", schema="full")            # Full, long (30 cols)

# Examples - Format options
df = unicefData("CME_MRY0T4", format="wide")            # Years as columns (CSV-TS API)
df = unicefData("CME_MRY0T4 CME_MRM0", format="wide_indicators")  # Indicators as columns
df = unicefData("CME_MRY0T4", format="wide_attributes", pivot="sex")  # Sex as columns
df = unicefData("CME_MRY0T4", format="wide_attributes", pivot=["sex", "wealth_quintile"])  # Compound
```

**Backward Compatibility**:

| Old Parameter | New Equivalent |
|---------------|----------------|
| `simplify=True` | `schema="minimal"` |
| `raw=True` | `schema="raw"` (no schema enforcement) |

**BREAKING CHANGE (v2.0)**: The `format="wide"` parameter now returns years as columns (time-series format), aligned with Stata behavior. Users who previously used `format="wide"` to get indicators as columns should migrate to `format="wide_indicators"`.

### 6.2 R

```r
library(unicefData)

# Schema parameter
df <- unicefData(
    indicator = "CME_MRY0T4",
    schema = "extended",    # "minimal", "standard", "extended" (default), "full"
    format = "long"         # "long" (default), "wide", "wide_indicators", "wide_attributes"
)

# Examples - Schema levels
df <- unicefData("CME_MRY0T4")                              # Extended, long (21 cols)
df <- unicefData("CME_MRY0T4", schema = "minimal")          # Minimal, long (5 cols)
df <- unicefData("CME_MRY0T4", schema = "standard")         # Standard, long (15 cols)
df <- unicefData("CME_MRY0T4", schema = "full")             # Full, long (30 cols)

# Examples - Format options
df <- unicefData("CME_MRY0T4", format = "wide")             # Years as columns (CSV-TS API)
df <- unicefData(c("CME_MRY0T4", "CME_MRM0"), format = "wide_indicators")  # Indicators as columns
df <- unicefData("CME_MRY0T4", format = "wide_attributes", pivot = "sex")  # Sex as columns
df <- unicefData("CME_MRY0T4", format = "wide_attributes", pivot = c("sex", "wealth_quintile"))  # Compound
```

**Backward Compatibility**:

| Old Parameter | New Equivalent |
|---------------|----------------|
| `metadata = "light"` | `schema = "extended"` |
| `metadata = "full"` | `schema = "full"` |
| `simplify = TRUE` | `schema = "minimal"` |
| `raw = TRUE` | `schema = "raw"` |

**BREAKING CHANGE (v2.0)**: The `format = "wide"` parameter now returns years as columns (time-series format), aligned with Stata behavior. Users who previously used `format = "wide"` to get indicators as columns should migrate to `format = "wide_indicators"`.

### 6.3 Stata

```stata
* Schema parameter
unicefdata, indicator(CME_MRY0T4) schema(extended) clear

* Schema options: minimal, standard, extended (default), full
unicefdata, indicator(CME_MRY0T4) schema(minimal) clear     // 5 cols
unicefdata, indicator(CME_MRY0T4) schema(standard) clear    // 15 cols
unicefdata, indicator(CME_MRY0T4) schema(extended) clear    // 21 cols
unicefdata, indicator(CME_MRY0T4) schema(full) clear        // 30 cols

* Format options
unicefdata, indicator(CME_MRY0T4) wide clear                          // Years as columns (CSV-TS API)
unicefdata, indicator(CME_MRY0T4) wide_years clear                    // Explicit: years as columns
unicefdata, indicator(CME_MRY0T4 CME_MRM0) wide_indicators clear      // Indicators as columns
unicefdata, indicator(CME_MRY0T4) wide_attributes(sex) clear          // Sex as columns
unicefdata, indicator(CME_MRY0T4) wide_attributes(sex wealth_quintile) clear  // Compound pivot

* Backward compatible: wide_attributes without argument = all disaggregations
unicefdata, indicator(CME_MRY0T4) wide_attributes clear               // All disaggregations as suffixes

* Combined schema + format
unicefdata, indicator(CME_MRY0T4) schema(full) wide_attributes(sex) clear
```

**Backward Compatibility**:

| Old Parameter | New Equivalent |
|---------------|----------------|
| `metadata(light)` | `schema(extended)` |
| `metadata(full)` | `schema(full)` |
| `simplify` | `schema(minimal)` |
| `nosparse` | Implicit in all schema levels (rectangular guarantee) |
| `raw` | `schema(raw)` |
| `wide_attributes` | `wide_attributes()` with no argument = all disaggregations |

**Note**: Stata's `wide` option has always meant years as columns (time-series format). This is now the standard behavior across all platforms.

---

## 7. Migration Guide

### 7.1 Breaking Changes

**Python/R `format="wide"` Semantics (v2.0)**:

In previous versions of Python and R packages, `format="wide"` pivoted indicators into columns. Starting with v2.0, `format="wide"` pivots **years** into columns (time-series format), aligning with Stata behavior.

| Platform | Old `format="wide"` | New `format="wide"` | Migration |
|----------|---------------------|---------------------|-----------|
| Python | Indicators as columns | Years as columns | Use `format="wide_indicators"` |
| R | Indicators as columns | Years as columns | Use `format="wide_indicators"` |
| Stata | Years as columns | Years as columns | No change |

**Note**: The `schema` parameter is purely additive and introduces no breaking changes.

### 7.2 Deprecation Timeline

| Version | Status |
|---------|--------|
| 2.0.0 | `schema` parameter introduced, old parameters still work |
| 2.1.0 | Deprecation warnings for old parameters |
| 3.0.0 | Old parameters removed |

### 7.3 Migration Examples

**Python**:
```python
# Before
df = unicefData("CME_MRY0T4", simplify=True)
df = unicefData("CME_MRY0T4", raw=True)

# After
df = unicefData("CME_MRY0T4", schema="minimal")
df = unicefData("CME_MRY0T4", schema="raw")
```

**R**:
```r
# Before
df <- unicefData("CME_MRY0T4", metadata = "light")
df <- unicefData("CME_MRY0T4", metadata = "full")

# After
df <- unicefData("CME_MRY0T4", schema = "extended")
df <- unicefData("CME_MRY0T4", schema = "full")
```

**Stata**:
```stata
* Before
unicefdata, indicator(CME_MRY0T4) metadata(light) nosparse clear
unicefdata, indicator(CME_MRY0T4) metadata(full) clear

* After
unicefdata, indicator(CME_MRY0T4) schema(extended) clear
unicefdata, indicator(CME_MRY0T4) schema(full) clear
```

---

## Appendix

### A.1 Complete Column Order (Full Schema)

This is the canonical column order. All platforms MUST use this exact order.

```
 1. iso3
 2. country
 3. indicator
 4. indicator_name
 5. indicator_category
 6. period
 7. value
 8. geo_type
 9. geo_type_name
10. unit
11. unit_name
12. sex
13. sex_name
14. age
15. age_name
16. wealth_quintile
17. wealth_quintile_name
18. residence
19. residence_name
20. maternal_edu_lvl
21. maternal_edu_lvl_name
22. lower_bound
23. upper_bound
24. obs_status
25. obs_status_name
26. data_source
27. ref_period
28. country_notes
29. time_detail
30. current_age
```

### A.2 Disaggregation Code Reference

#### Sex Codes
| Code | Label |
|------|-------|
| `_T` | Total |
| `M` | Male |
| `F` | Female |

#### Age Group Codes (Common)
| Code | Label |
|------|-------|
| `_T` | Total (all ages) |
| `Y0T4` | 0-4 years |
| `Y5T9` | 5-9 years |
| `Y10T14` | 10-14 years |
| `Y15T19` | 15-19 years |
| `M0` | Under 1 month |
| `M0T11` | 0-11 months |

#### Wealth Quintile Codes
| Code | Label |
|------|-------|
| `_T` | Total |
| `Q1` | Poorest (Bottom 20%) |
| `Q2` | Second quintile |
| `Q3` | Middle quintile |
| `Q4` | Fourth quintile |
| `Q5` | Richest (Top 20%) |

#### Residence Codes
| Code | Label |
|------|-------|
| `_T` | Total |
| `U` | Urban |
| `R` | Rural |

#### Observation Status Codes
| Code | Label | Description |
|------|-------|-------------|
| `A` | Normal | Regular observation |
| `E` | Estimated | Model-based estimate |
| `P` | Provisional | Preliminary data |
| `B` | Break | Time series break |

### A.3 Implementation Checklist

#### Python
- [ ] Add `schema` parameter to `unicefData()`
- [ ] Implement rectangular column enforcement
- [ ] Add deprecation warnings for `simplify`, `raw`
- [ ] Update wide format to handle label auto-dropping
- [ ] Add schema validation tests

#### R
- [ ] Add `schema` parameter to `unicefData()`
- [ ] Implement rectangular column enforcement
- [ ] Add deprecation warnings for `metadata`, `simplify`, `raw`
- [ ] Update wide format to handle label auto-dropping
- [ ] Add schema validation tests

#### Stata
- [ ] Add `schema()` option to `unicefdata`
- [ ] Implement rectangular column enforcement (replace `nosparse` logic)
- [ ] Add 6 columns to match extended schema default
- [ ] Add deprecation notes for `metadata()`, `simplify`, `nosparse`
- [ ] Update wide formats to handle label auto-dropping
- [ ] Add schema validation tests

### A.4 Cross-Platform Validation

The xval framework validates schema consistency:

```bash
# Run cross-platform validation
python validation/xval/run_xval.py --schema extended

# Validation checks:
# 1. Column count matches schema level
# 2. Column names match exactly
# 3. Column order matches specification
# 4. Row counts match across platforms (within tolerance)
```

### A.5 Version History

| Version | Date | Changes |
|---------|------|---------|
| 1.0.0 | 2026-01-31 | Initial specification |

---

## References

- UNICEF SDMX API Documentation
- SDMX 2.1 Information Model
- ISO 3166-1 Country Codes
- World Bank Income Classifications

---

*End of Document*
