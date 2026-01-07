{smcl}
{* *! version 1.5.2  06Jan2026}{...}
{vieweralsosee "unicefdata" "help unicefdata"}{...}
{vieweralsosee "unicefdata_sync" "help unicefdata_sync"}{...}
{vieweralsosee "unicefdata_examples" "help unicefdata_examples"}{...}
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
jazevedo@unicef.org

{pstd}
{it:Return to {help unicefdata:main help file}}
{p_end}
