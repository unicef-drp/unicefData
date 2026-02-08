# UNICEF Open Data APIs — Comprehensive Developer Guide
*SDMX Data Warehouse · Reference Data Manager (RDM) · Open Data Portal*

**Last Updated:** January 2026  
**Package Version:** unicefdata v1.9.1+ (Stata), unicefData (R/Python)

---

## Table of Contents

1. [Purpose and Scope](#1-purpose-and-scope)
2. [UNICEF Open Data Ecosystem](#2-unicef-open-data-ecosystem)
3. [SDMX REST API — UNICEF Data Warehouse](#3-sdmx-rest-api--unicef-data-warehouse)
4. [Reference Data Manager (RDM) API](#4-reference-data-manager-rdm-api)
5. [unicefdata Package (Stata/R/Python)](#5-unicefdata-package-statarpython)
6. [SDMX Query Builder (Core Section)](#6-sdmx-query-builder-core-section)
7. [Validated Query Examples](#7-validated-query-examples)
8. [Best-Practice Workflow](#8-bestpractice-workflow)
9. [Licensing & Attribution](#9-licensing--attribution)
10. [SDMX Dimension Codes Reference](#10-sdmx-dimension-codes-reference)
11. [Suggested Extensions](#11-suggested-extensions)

---

## 1. Purpose and Scope

This document provides a **complete, production‑ready guide** to accessing UNICEF open data programmatically.  
It consolidates and cross‑references:

- **UNICEF Open Data Portal** (human‑readable datasets & metadata)
- **UNICEF SDMX REST API** (structured statistical time series)
- **UNICEF Reference Data Manager (RDM) API** (authoritative reference metadata)
- **unicefdata package** (Stata/R/Python wrappers for simplified access)

The guide is designed for **reproducible analytics, ETL pipelines, benchmarking systems, and official statistics workflows**.

---

## 2. UNICEF Open Data Ecosystem

### 2.1 Open Data Principles

UNICEF publishes data as a **global public good**, enabling reuse for research, policy, and accountability.

- Licensing: **Creative Commons Attribution 3.0 IGO**
- Coverage: children, women, health, education, nutrition, poverty, protection, WASH
- Intended users: governments, researchers, multilaterals, civil society

Source: https://data.unicef.org/open-data/

---

### 2.2 Human‑Readable Access (data.unicef.org)

Primary use cases: exploration, reporting, validation, citation.

Key resources:
- **Datasets archive** (CSV / Excel)
- **Indicator profiles** (definitions, methodology)
- **Country profiles**
- **How Many?** curated Q&A statistics

Portal: https://data.unicef.org/

---

## 3. SDMX REST API — UNICEF Data Warehouse

### 3.1 What SDMX Provides

The SDMX API exposes **fully structured statistical time series**, supporting:

- Multi‑dimensional disaggregation
- Consistent metadata via DSDs
- Machine‑readable, reproducible access

Base endpoint:
```
https://sdmx.data.unicef.org/ws/public/sdmxapi/rest/
```

Interactive explorer:
https://sdmx.data.unicef.org/webservice/data.html

---

### 3.2 Core SDMX Concepts

| Concept | Meaning |
|------|--------|
| Dataflow | Dataset definition |
| DSD | Dimension & attribute structure |
| Dimension | Variable defining observations |
| Attribute | Metadata attached to observations |
| DataQuery | Compact dimension filter string |

---

### 3.3 SDMX Endpoint Summary

| Purpose | Endpoint |
|------|---------|
| List dataflows | `/dataflow/all/all/latest` |
| Fetch structure | `/dataflow/{agency}/{flow}/latest` |
| Download data | `/data/{agency},{flow},{version}/{query}` |

---

## 4. Reference Data Manager (RDM) API

### 4.1 Purpose

The RDM API provides **authoritative reference metadata** used across UNICEF systems.

It complements SDMX by supplying:
- Valid country codes
- Indicator master lists
- Organizational reference entities

Swagger UI:
https://rdmapi.unicef.org/api/doc/index.html

---

### 4.2 Typical RDM Endpoints

```bash
# Countries
curl https://rdmapi.unicef.org/api/countries

# Indicators
curl https://rdmapi.unicef.org/api/indicators

# Indicator details
curl https://rdmapi.unicef.org/api/indicators/{INDICATOR_ID}
```

---

### 4.3 RDM + SDMX Integration Logic

**Recommended sequence:**

1. Fetch reference codes from RDM
2. Validate dimension values
3. Construct SDMX DataQuery
4. Retrieve SDMX data
5. Join metadata for interpretation

This avoids silent query failures and improves reproducibility.

---

## 5. unicefdata Package (Stata/R/Python)

### 5.1 Overview

The `unicefdata` package provides a **high-level wrapper** around the SDMX API, handling:
- Automatic dataflow detection from indicator codes
- Dimension ordering and query construction
- Pagination for large datasets
- Metadata caching for performance

### 5.2 Installation (Stata)

```stata
* Install from SSC
ssc install unicefdata, replace

* Or from GitHub (development version)
net install unicefdata, from("https://raw.githubusercontent.com/unicef-drp/unicefData/main/stata/ssc") replace
```

### 5.3 Basic Usage

```stata
* Fetch data for a single indicator
unicefdata, indicator(CME_MRY0T4) countries(AFG BGD IND) clear

* Multiple indicators from same dataflow
unicefdata, indicator(CME_MRY0T4 CME_TMY0T4) countries(AFG BGD) clear

* Specify time range
unicefdata, indicator(ED_ANAR_L2) countries(all) year(2015/2023) clear
```

### 5.4 The info() Option

Get detailed metadata about any indicator **without fetching data**:

```stata
unicefdata, info(ED_ANAR_L2)
```

**Output:**
```
----------------------------------------------------------------------
Indicator Information: ED_ANAR_L2
----------------------------------------------------------------------

 Code:        ED_ANAR_L2
 Name:        Adjusted net attendance rate for adolescents of lower secondary school age
 Category:    EDUCATION
 Dataflow:    EDUCATION, GLOBAL_DATAFLOW

 Description:
   Percentage of children of lower secondary school age attending secondary school or higher

 URN:         urn:sdmx:org.sdmx.infomodel.codelist.Code=UNICEF:CL_UNICEF_INDICATOR(1.0).ED_ANAR_L2

 API Query:
   https://sdmx.data.unicef.org/ws/public/sdmxapi/rest/data/UNICEF,EDUCATION,1.0/..ED_ANAR_L2._T

 Supported Disaggregations:
   SEX  (with totals)
     Values: Male, Female
     Codes:  M, F, _T (total)
   WEALTH_QUINTILE  (with totals)
     Values: Quintile 1-5
     Codes:  Q1, Q2, Q3, Q4, Q5, _T (total)
   RESIDENCE  (with totals)
     Values: Urban, Rural
     Codes:  U, R, _T (total)

----------------------------------------------------------------------
Usage: unicefdata, indicator(ED_ANAR_L2) countries(AFG BGD) clear
----------------------------------------------------------------------
```

### 5.5 Disaggregation Filters

Filter data by demographic dimensions:

```stata
* Get data by sex
unicefdata, indicator(CME_MRY0T4) countries(AFG BGD) sex(M F) clear

* Get data by wealth quintile
unicefdata, indicator(NT_ANT_WHZ_NE2) countries(IND) wealth(Q1 Q2 Q3 Q4 Q5) clear

* Combine multiple filters
unicefdata, indicator(ED_ANAR_L2) countries(BGD) sex(M F) residence(U R) clear
```

### 5.6 Listing Available Dataflows

```stata
* List all available dataflows with indicator counts
unicefdata, flows
```

### 5.7 Search for Indicators

```stata
* Search by keyword
unicefdata, search(mortality)

* Search with regex
unicefdata, search("^CME_") regex
```

---

## 6. SDMX Query Builder (Core Section)

### 6.1 Canonical SDMX Pattern

```
/data/{AGENCY},{DATAFLOW},{VERSION}/{DATAQUERY}?{PARAMETERS}
```

Example:
```
/data/UNICEF,CME,1.0/AFG.CME_PND._T._T?format=csv&labels=id
```

---

### 6.2 DATAQUERY Grammar

```
DIM1.DIM2.DIM3....DIMn
```

| Syntax | Meaning |
|------|--------|
| `.` | Dimension separator |
| empty | All values |
| `+` | Multiple values |
| `_T` | Total / aggregate |
| `all` | All dimensions |

---

### 6.3 Dimension Order (Critical)

Dimension order is **fixed per dataflow**.

Examples inferred from tested queries:

**CME**
```
REF_AREA . INDICATOR . SEX . WEALTH . TIME
```

**Nutrition**
```
REF_AREA . INDICATOR . SEX . AGE . WEALTH . RESIDENCE . TIME
```

SDMX does **not** support named parameters — order is mandatory.

---

### 6.4 Recommended Query Patterns

#### Single indicator, selected countries, totals only (best practice)

```
COUNTRY1+COUNTRY2.INDICATOR._T._T
```

---

#### Multiple indicators (same dataflow)

```
COUNTRY.IND1+IND2+IND3._T._T
```

---

#### Exploratory (use sparingly)

```
.INDICATOR..
```

---

#### Entire dataflow (archival only)

```
/all
```

---

### 6.5 Output Parameters

| Parameter | Value | Notes |
|---------|------|------|
| format | csv | Preferred |
| labels | id | Machine‑safe |
| labels=both | optional | Inspection |
| sdmx-compact-2.1 | optional | JSON |

Canonical suffix:
```
?format=csv&labels=id
```

---

### 6.6 Query Builder Decision Tree

```
Need aggregation?
 ├─ Yes → _T
 └─ No → specify codes

Multiple indicators?
 ├─ Yes → +
 └─ No → single code

Production pipeline?
 ├─ Yes → labels=id
 └─ No → labels=both
```

---

### 6.7 Anti‑Patterns

- Pulling full dataflows unnecessarily
- Ignoring dimension order
- Using labels in pipelines
- Looping indicators instead of `+`
- Assuming `_T` exists without checking DSD

---

## 7. Validated Query Examples

### CME — neonatal mortality

```
https://sdmx.data.unicef.org/ws/public/sdmxapi/rest/data/UNICEF,CME,1.0/AFG+CZE+TTO.CME_PND._T._T?format=csv&labels=id
```

---

### Child Poverty — multiple indicators

```
https://sdmx.data.unicef.org/ws/public/sdmxapi/rest/data/UNICEF,CHLD_PVTY,1.0/LCA+UGA.PV_CHLD_DPRV-AVG-S-HS+PV_CHLD_DPRV-E4-HS._T._T?format=csv&labels=id
```

---

### Nutrition — aggregate totals

```
https://sdmx.data.unicef.org/ws/public/sdmxapi/rest/data/UNICEF,NUTRITION,1.0/.NT_ANT_WHZ_PO2_MOD_NUMTH._T.._T._T..?format=csv&labels=id
```

---

## 8. Best‑Practice Workflow

1. Discover DSD
2. Fetch RDM codes
3. Build explicit query
4. Prefer totals
5. Cache results
6. Version outputs
7. Re‑validate periodically

---

## 9. Licensing & Attribution

All data is provided under **CC BY 3.0 IGO**.  
Attribution to UNICEF is required in all downstream products.

---

## 10. SDMX Dimension Codes Reference

### 10.1 Common Disaggregation Dimensions

| Dimension | Description | Valid Codes |
|-----------|-------------|-------------|
| `REF_AREA` | Country/region | ISO 3166-1 alpha-3 (AFG, BGD, IND, etc.) |
| `INDICATOR` | Indicator code | CME_MRY0T4, ED_ANAR_L2, etc. |
| `SEX` | Sex | `M` (Male), `F` (Female), `_T` (Total) |
| `RESIDENCE` | Urban/Rural | `U` (Urban), `R` (Rural), `_T` (Total) |
| `WEALTH_QUINTILE` | Wealth quintile | `Q1`, `Q2`, `Q3`, `Q4`, `Q5`, `_T` (Total) |
| `AGE` | Age group | `Y0T4`, `Y5T9`, `Y10T14`, `Y15T17`, `Y18T24`, etc. |
| `EDUCATION_LEVEL` | ISCED level | `L0_2` (Pre-primary), `L1` (Primary), `L2` (Lower sec), `L3` (Upper sec) |
| `TIME_PERIOD` | Year | 2000, 2010, 2020, etc. |

### 10.2 Special Values

| Code | Meaning | Usage |
|------|---------|-------|
| `_T` | Total/Aggregate | Use to get totals across a dimension |
| `.` | Any/All | Wildcard in query string (empty position) |
| `+` | OR operator | Combine multiple values: `M+F`, `Q1+Q2+Q3` |

### 10.3 Dataflow-Specific Dimensions

Different dataflows have different dimension structures. Use `unicefdata, info(INDICATOR)` to see available disaggregations.

**CME (Child Mortality Estimates):**
```
REF_AREA . INDICATOR . SEX . WEALTH_QUINTILE
```

**EDUCATION:**
```
REF_AREA . INDICATOR . SEX . EDUCATION_LEVEL . WEALTH_QUINTILE . RESIDENCE
```

**NUTRITION:**
```
REF_AREA . INDICATOR . SEX . AGE . WEALTH_QUINTILE . RESIDENCE
```

---

## 11. Suggested Extensions

- ~~Auto‑generate query templates from DSDs~~ ✅ Done via `unicefdata, info()`
- ~~Build a query‑builder utility (R / Python / Stata)~~ ✅ Done via `unicefdata` package
- Add contract tests for metadata drift
- Maintain a per‑dataflow query cookbook
- Integrate with validation frameworks for data quality checks

---

*This document is intended to serve as a stable technical reference for UNICEF SDMX‑based analytics and data engineering pipelines.*



https://sdmx.data.unicef.org/ws/public/sdmxapi/rest/data/UNICEF,CME,1.0/BRA+MEX...?format=csv&labels=id

https://sdmx.data.unicef.org/ws/public/sdmxapi/rest/data/UNICEF,CME,1.0/BRA+MEX.._T.?format=csv&labels=id

https://sdmx.data.unicef.org/ws/public/sdmxapi/rest/data/UNICEF,CME,1.0/BRA+MEX.._T+F+M.?format=csv&labels=id

https://sdmx.data.unicef.org/ws/public/sdmxapi/rest/data/UNICEF,CME,1.0/BRA+MEX...?format=csv&labels=id

https://sdmx.data.unicef.org/ws/public/sdmxapi/rest/data/UNICEF,CME,1.0/BRA+MEX.._T._T?format=csv&labels=id



https://sdmx.data.unicef.org/ws/public/sdmxapi/rest/data/UNICEF,CME,1.0/BRA+MEX...?format=csv-ts&labels=id

https://sdmx.data.unicef.org/ws/public/sdmxapi/rest/data/UNICEF,CME,1.0/BRA+MEX.._T.?format=csv-ts&labels=id

https://sdmx.data.unicef.org/ws/public/sdmxapi/rest/data/UNICEF,CME,1.0/BRA+MEX.._T+F+M.?format=csv-ts&labels=id

https://sdmx.data.unicef.org/ws/public/sdmxapi/rest/data/UNICEF,CME,1.0/BRA+MEX...?format=csv-ts&labels=id

https://sdmx.data.unicef.org/ws/public/sdmxapi/rest/data/UNICEF,CME,1.0/BRA+MEX.._T._T?format=csv-ts&labels=id


