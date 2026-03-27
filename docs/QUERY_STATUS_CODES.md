# Query Status Codes

**Version:** 1.0
**Scope:** Cross-language specification for `unicefData()` (currently implemented in Python; R and Stata pending)

---

## Activation

Query status codes are opt-in via the `diagnose` parameter:

```python
# Python
df = unicefData("MNCH_CSEC", countries=["BRA"], year=2020, diagnose=True)
```

```r
# R (planned)
df <- unicefData("MNCH_CSEC", countries = "BRA", year = 2020, diagnose = TRUE)
```

```stata
* Stata (planned)
unicefdata MNCH_CSEC, countries(BRA) year(2020) diagnose
```

When `diagnose=False` (default), year filters are sent to the API server-side (faster, no metadata). When `diagnose=True`, data is fetched without year filters and filtered client-side, enabling the status codes and metadata below.

---

## Purpose

When `unicefData()` returns an empty result, the caller needs to know **why** — especially MCP tools and automated pipelines that must distinguish "data doesn't exist" from "data exists but not for this query."

The query status code classifies the outcome of every `unicefData()` call into one of six states. The classification is based on API responses (not bundled metadata), making it robust to metadata staleness.

---

## Status Codes

| Code | Meaning | When it occurs |
|------|---------|---------------|
| `ok` | Data returned successfully | Rows found matching all filters |
| `indicator_not_found` | Indicator code does not exist in any UNICEF SDMX dataflow | All dataflows returned 404 or 0 rows (fetched without country/year filters) |
| `country_not_found` | Indicator exists but this country has never reported data | API returned data for other countries, but 0 rows after filtering for the requested country |
| `year_not_found` | Indicator + country exist but no data for the requested year | Country has data for other years (before and after), but not for the requested year — a gap in the time series. `available_years` lists what exists |
| `year_beyond_range` | Requested year is outside the available data range | Year is before the earliest or after the latest data point for this country+indicator. Distinct from `year_not_found` (gap) — here the year is simply too early or too late |
| `partial` | Some requested countries/indicators returned data, others didn't | Multi-country or multi-indicator query where at least one combination had data |
| `error` | API error (timeout, 403, 500, etc.) | Network or server failure — not a data availability issue |

---

## Additional Metadata

When the status is not `ok`, the following metadata is provided alongside the empty result:

| Field | Type | Present when | Description |
|-------|------|-------------|-------------|
| `query_status` | string | Always | One of the six codes above |
| `query_indicator` | string | Always | The indicator code that was queried |
| `query_countries` | list | Always | The country codes that were queried |
| `query_year` | int or null | When year was specified | The year that was queried |
| `available_countries` | list | `country_not_found` | Countries that have data for this indicator (sample, not exhaustive) |
| `available_years` | list | `year_not_found` | Years with data for this indicator + country combination |
| `nearest_year` | int or null | `year_not_found` | Closest available year to the requested year |
| `message` | string | Always | Human-readable explanation |

---

## Classification Logic

Only active when `diagnose=True`. When `diagnose=False` (default), empty results have no status metadata.

```
unicefData(indicator, countries, year, diagnose=True) called:

1. Fetch from SDMX API WITHOUT year filter:
   GET /data/UNICEF,{dataflow},1.0/.{indicator}.?format=csv

   → All dataflows return 404 or 0 rows
     STATUS = indicator_not_found
     MESSAGE = "Indicator '{indicator}' not found in any UNICEF dataflow."

   → Rows returned → continue to step 2

2. Filter for requested country(ies):

   → 0 rows for requested country(ies)
     STATUS = country_not_found
     available_countries = unique REF_AREA values from step 1 (up to 20)
     MESSAGE = "No data for {country}. Data exists for: {available_countries}..."

   → Rows found for country → continue to step 3

3. If year was specified, filter for year (client-side):

   → 0 rows AND year is outside data range (before min or after max)
     STATUS = year_beyond_range
     MESSAGE = "Year {year} is outside the available data range for {country}.
                Data covers {min_year}-{max_year}. Nearest available: {nearest}."

   → 0 rows AND year is within data range (gap between survey rounds)
     STATUS = year_not_found
     MESSAGE = "No data for {country} in {year}. Data exists for other years:
                {available_years}. Nearest available: {nearest}."

   → Rows found
     STATUS = ok
     Return data
```

**Key design decision:** Step 1 always fetches without the year filter. This costs slightly more bandwidth for large dataflows (CME: ~65K rows) but:
- Avoids the SDMX API quirk where country+year 404s on survey dataflows
- Provides the data needed for steps 2-3 without additional API calls
- Enables the `available_years` and `available_countries` metadata

---

## Language-Specific Implementation

### Python

```python
df = unicefData(indicator="MNCH_CSEC", countries=["BRA"], year=2020)
# len(df) == 0  (unchanged — non-breaking)

# New metadata via DataFrame.attrs:
df.attrs["query_status"]        # "year_not_found"
df.attrs["available_years"]     # [2015, 2016, 2017, 2018, 2019]
df.attrs["nearest_year"]        # 2019
df.attrs["message"]             # "No data for BRA in 2020. Available: 2015-2019. Nearest: 2019."
```

### R

```r
df <- unicefData("MNCH_CSEC", countries = "BRA", year = 2020)
# nrow(df) == 0  (unchanged — non-breaking)

# New metadata via attributes:
attr(df, "query_status")        # "year_not_found"
attr(df, "available_years")     # c(2015, 2016, 2017, 2018, 2019)
attr(df, "nearest_year")        # 2019
attr(df, "message")             # "No data for BRA in 2020. ..."

# Also emitted as message():
# Note: No data for BRA in 2020. Available years: 2015-2019. Nearest: 2019.
```

### Stata

```stata
unicefdata MNCH_CSEC, countries(BRA) year(2020)
* r(N) == 0  (unchanged — non-breaking)

* New return scalars:
display r(query_status)         // "year_not_found"
display r(available_years)      // "2015 2016 2017 2018 2019"
display r(nearest_year)         // 2019
display r(message)              // "No data for BRA in 2020. ..."
```

---

## MCP Integration

The MCP `get_data` tool should map these status codes to structured responses:

```json
{
  "status": "year_not_found",
  "indicator": "MNCH_CSEC",
  "country": "BRA",
  "year": 2020,
  "available_years": [2015, 2016, 2017, 2018, 2019],
  "nearest_year": 2019,
  "message": "No data for BRA in 2020. Available years: 2015-2019. Nearest: 2019."
}
```

This gives the LLM enough information to respond accurately:
> "UNICEF does not have C-section data for Brazil in 2020. The most recent available data is from 2019."

Instead of the current behavior (empty result → LLM interpolates or fabricates).

---

## Backward Compatibility

- `unicefData()` return type is unchanged (DataFrame / tibble / dataset)
- Existing code that checks `len(df) == 0` or `nrow(df) == 0` still works
- Status codes are opt-in metadata — callers that don't read `.attrs` / `attr()` / `r()` are unaffected
- No new exception types
- No new required parameters
