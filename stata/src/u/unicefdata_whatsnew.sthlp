{smcl}
{* *! version 2.0.0  24Jan2026}{...}
{vieweralsosee "unicefdata" "help unicefdata"}{...}
{vieweralsosee "unicefdata_sync" "help unicefdata_sync"}{...}
{vieweralsosee "unicefdata_examples" "help unicefdata_examples"}{...}
{viewerjumpto "v2.0.0" "unicefdata_whatsnew##v200"}{...}
{viewerjumpto "v1.10.0" "unicefdata_whatsnew##v1100"}{...}
{viewerjumpto "v1.6.0" "unicefdata_whatsnew##v160"}{...}
{viewerjumpto "v1.5.2" "unicefdata_whatsnew##v152"}{...}
{viewerjumpto "v1.5.1" "unicefdata_whatsnew##v151"}{...}
{viewerjumpto "v1.5.0" "unicefdata_whatsnew##v150"}{...}
{viewerjumpto "v1.4.0" "unicefdata_whatsnew##v140"}{...}
{viewerjumpto "v1.3.0" "unicefdata_whatsnew##v130"}{...}
{title:Title}

{p2colset 5 30 32 2}{...}
{p2col :{cmd:unicefdata} What's New {hline 2}}Version history and release notes{p_end}
{p2colreset}{...}

{pstd}
{it:Return to {help unicefdata:main help file}}
{p_end}


{marker v200}{...}
{title:What's New in v2.0.0 (24Jan2026)}

{pstd}
{bf:Major Quality Milestone:} All QA tests passing (38/38, 100% success rate)
{p_end}

{pstd}
{bf:SYNC-02 Enrichment Fix:}
{p_end}
{phang2}• Fixed critical path extraction bug in metadata enrichment pipeline{p_end}
{phang2}• Phase 2-3 enrichment now working: tier classification + disaggregations{p_end}
{phang2}• Previously: 37/38 tests passing (SYNC-02 failed with "enrichment incomplete"){p_end}
{phang2}• Now: 38/38 tests passing in 10m 17s{p_end}

{pstd}
{bf:Technical Details:}
{p_end}
{phang2}• Root cause: Incorrect directory path extraction from YAML file paths{p_end}
{phang2}• Solution: Implemented forvalues loop to find rightmost slash properly{p_end}
{phang2}• Impact: Metadata synchronization pipeline fully operational{p_end}

{pstd}
{bf:Enhanced Reliability:}
{p_end}
{phang2}• All enrichment phases complete successfully{p_end}
{phang2}• Improved YAML file path resolution{p_end}
{phang2}• Better error handling and diagnostics{p_end}


{marker v1100}{...}
{title:What's New in v1.10.0 (18Jan2026)}

{pstd}
{bf:Enhanced info() display:} The {opt info()} option now shows SDMX dimension codes
alongside human-readable values, enabling direct use in API queries.
{p_end}

{pstd}
{bf:New info() features:}
{p_end}
{phang2}• Shows both values and SDMX codes (e.g., "M, F, _T (total)" for SEX){p_end}
{phang2}• Displays clickable API Query URL for testing in browser{p_end}
{phang2}• Shows full URN for SDMX identification{p_end}
{phang2}• Excludes technical dimensions (UNIT_MEASURE) from disaggregations{p_end}

{pstd}
{bf:Streamlined post-fetch display:} After data retrieval, the indicator summary
is now concise with a clickable tip directing users to {cmd:info()} for full metadata.
{p_end}

{pstd}
{bf:SDMX dimension code reference:}
{p_end}
{phang2}{cmd:SEX}: M (Male), F (Female), _T (Total){p_end}
{phang2}{cmd:RESIDENCE}: U (Urban), R (Rural), _T (Total){p_end}
{phang2}{cmd:WEALTH_QUINTILE}: Q1, Q2, Q3, Q4, Q5, _T (Total){p_end}
{phang2}{cmd:AGE}: Y0T4, Y5T9, Y10T14, Y15T17, etc.{p_end}
{phang2}{cmd:EDUCATION_LEVEL}: L0_2, L1, L2, L3 (ISCED levels){p_end}

{pstd}
{bf:Example:} View full metadata with SDMX codes:
{p_end}
{phang2}{cmd:. unicefdata, info(ED_ANAR_L2)}{p_end}


{marker v160}{...}
{title:What's New in v1.6.0 (12Jan2026)}

{pstd}
{bf:Stata dataflow enhancements:} Extended support for COD, TRGT, SPP, and WT indicator prefixes
with automatic dataflow detection. Expanded PT subdataflows to include child marriage (PT_CM)
and female genital mutilation (PT_FGM) indicators.
{p_end}

{pstd}
{bf:New prefix-to-dataflow mappings:}
{p_end}
{phang2}{cmd:COD} - Maps to {cmd:CAUSE_OF_DEATH} dataflow (18+ health indicators){p_end}
{phang2}{cmd:TRGT} - Maps to {cmd:CHILD_RELATED_SDG} dataflow{p_end}
{phang2}{cmd:SPP} - Maps to {cmd:SOC_PROTECTION} dataflow{p_end}
{phang2}{cmd:WT} - Maps to {cmd:PT} dataflow (child labor indicators){p_end}

{pstd}
{bf:PT subdataflow support:}
{p_end}
{phang2}Extended PT fallback sequence: {cmd:PT} → {cmd:PT_CM} → {cmd:PT_FGM} → {cmd:CHILD_PROTECTION} → {cmd:GLOBAL_DATAFLOW}{p_end}
{phang2}Enables indicators like {cmd:PT_CM_EMPLOY_12M} (168 observations){p_end}

{pstd}
{bf:Bug fixes:}
{p_end}
{phang2}Fixed fallback import bug that prevented re-import skip logic{p_end}
{phang2}Properly initializes {cmd:fallback_used} flag throughout indicator fetch{p_end}

{pstd}
{bf:Testing:} Cross-platform validation confirms Stata parity with Python performance
on all tested indicators (seed-42: 19 new successes, 0 regressions).
{p_end}

{pstd}
{bf:Example:} Fetch child marriage employment indicator:
{p_end}
{phang2}{cmd:. unicefdata PT_CM_EMPLOY_12M, clear}{p_end}
{phang2}{cmd:. list if countryname == "Ghana" & year == 2020}{p_end}


{marker v152}{...}
{title:What's New in v1.5.2 (06Jan2026)}

{pstd}
{bf:wide_indicators enhancements:} The {opt wide_indicators} reshape now creates
empty numeric columns for every requested indicator even when filtered data have zero
observations. This prevents "variable not found" reshape failures and keeps downstream code
reliable. Output columns always include:
{p_end}
{phang2}{cmd:lb} - Lower confidence bound{p_end}
{phang2}{cmd:ub} - Upper confidence bound{p_end}
{phang2}{cmd:status} - Observation status code{p_end}
{phang2}{cmd:status_name} - Observation status{p_end}
{phang2}{cmd:source} - Data source{p_end}
{phang2}{cmd:refper} - Reference period{p_end}
{phang2}{cmd:notes} - Country notes{p_end}

{pstd}
{it:Note:} All variables have descriptive labels accessible via {cmd:describe} or {cmd:codebook}.
Variable names are aligned with the R {cmd:get_unicef()} and Python {cmd:unicef_api} packages.
{p_end}


{marker v151}{...}
{title:What's New in v1.5.1 (Dec2025)}

{pstd}
{bf:wide_attributes option:} New reshape option that creates columns with disaggregation 
suffixes (e.g., {cmd:CME_MRY0T4_T}, {cmd:CME_MRY0T4_M}, {cmd:CME_MRY0T4_F}).
{p_end}

{pstd}
{bf:attributes() filter:} New option to select specific attribute codes when using 
{opt wide_attributes}. Example: {cmd:attributes(_T _Q1 _Q5)} keeps only total, poorest, 
and richest quintiles.
{p_end}


{marker v150}{...}
{title:What's New in v1.5.0 (Nov2025)}

{pstd}
{bf:circa option:} Find the closest available year for each country when the exact 
requested year is not available. Enables cross-country comparisons when data 
availability varies.
{p_end}

{pstd}
{bf:latest option:} Automatically retrieve only the most recent observation for each 
country-indicator combination.
{p_end}


{marker v140}{...}
{title:What's New in v1.4.0 (Oct2025)}

{pstd}
{bf:YAML metadata:} Full integration with {helpb yaml} package for indicator discovery 
and validation. Metadata files synchronized with R and Python implementations.
{p_end}

{pstd}
{bf:Discovery commands enhanced:}
{p_end}
{phang2}{cmd:unicefdata, search(keyword)} - Search indicators by keyword{p_end}
{phang2}{cmd:unicefdata, info(indicator)} - Get indicator details and supported disaggregations{p_end}
{phang2}{cmd:unicefdata, flows} - List all available dataflows{p_end}


{marker v130}{...}
{title:What's New in v1.3.0 (Sep2025)}

{pstd}
{bf:wide_indicators option:} Reshape multiple indicators into separate columns for 
cross-indicator analysis.
{p_end}

{pstd}
{bf:addmeta() option:} Add country metadata columns (region, income_group, etc.) 
to downloaded data.
{p_end}

{pstd}
{bf:wide option:} Reshape years into columns (yr2015, yr2016, etc.) for time-series 
analysis.
{p_end}


{marker history}{...}
{title:Earlier Versions}

{pstd}
{bf:v1.0.0:} Initial internal  release with basic download functionality, country and year filtering, disaggregation options. (2024)}
{p_end}

{title:Author}

{pstd}
Joao Pedro Azevedo, UNICEF{break}
jpazevedo@unicef.org{break}
{browse "https://jpazvd.github.io/"}

{pstd}
{it:Return to {help unicefdata:main help file}}
{p_end}
