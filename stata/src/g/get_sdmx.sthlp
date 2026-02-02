{smcl}
{* *! version 2.0.0  24Jan2026}{...}
{vieweralsosee "[D] unicefdata" "help unicefdata"}{...}
{vieweralsosee "[D] unicefdata_sync" "help unicefdata_sync"}{...}
{viewerjumpto "Syntax" "get_sdmx##syntax"}{...}
{viewerjumpto "Description" "get_sdmx##description"}{...}
{viewerjumpto "Defaults" "get_sdmx##defaults"}{...}
{viewerjumpto "Options" "get_sdmx##options"}{...}
{viewerjumpto "Stored results" "get_sdmx##results"}{...}
{viewerjumpto "Examples" "get_sdmx##examples"}{...}
{title:get_sdmx — Low-level SDMX data fetching}

{marker syntax}{...}
{title:Syntax}

{p 8 16 2}
{cmdab:get_sdmx}{cmd:,}
{cmdab:ind:icator(}{it:string}{cmd:)}
[{opt ag:ency(string)}
{opt dataflow(string)}
{opt cou:ntries(string)}
{opt fi:lter(string)}
{opt det:ail(string)}
{opt for:mat(string)}
{opt lab:els(string)}
{opt year(string)}
{opt start_period(string)}
{opt end_period(string)}
{opt file:name(string)}
{opt wide}
{opt cle:ar}
{opt nofilter}
{opt ret:ry(int)}
{opt cac:he}
{opt coun:try_names}
{opt ver:bose}
{opt debug}
{opt trace}
]

{marker description}{...}
{title:Description}

{p}
{cmd:get_sdmx} is a low-level function for downloading data from any SDMX-compliant
API (World Bank Open Data, UNICEF Data Warehouse, etc.).
It handles:
{p_end}

{p 8 12 2}
• Automatic or manual dataflow detection{p_end}
{p 8 12 2}
• Intelligent query filter engine (dimension extraction from schemas){p_end}
{p 8 12 2}
• Paging and retry logic with exponential backoff{p_end}
{p 8 12 2}
• Dynamic User-Agent header for API identification{p_end}
{p 8 12 2}
• Fallback from curl to {cmd:copy} if primary fetch fails{p_end}
{p 8 12 2}
• Schema caching for improved performance{p_end}

{p}
Most users should use {cmd:unicefdata} instead, which wraps this function.
{cmd:get_sdmx} is for advanced users requiring direct SDMX API access.
{p_end}

{marker defaults}{...}
{title:Default Behavior}

{pstd}
{bf:Summary of defaults when options are omitted:}
{p_end}

{p2colset 5 25 27 2}{...}
{p2col:{bf:Option}}{bf:Default Value}{p_end}
{p2line}
{p2col:{opt agency()}}UNICEF{p_end}
{p2col:{opt countries()}}All countries (empty){p_end}
{p2col:{opt year()}}All available years{p_end}
{p2col:{opt format()}}csv{p_end}
{p2col:{opt labels()}}id (codes only){p_end}
{p2col:{opt detail()}}data (fetch observations){p_end}
{p2col:{opt retry()}}3 attempts{p_end}
{p2col:{opt wide}}Long format (rows per observation){p_end}
{p2col:{opt clear}}No clear (preserve existing data){p_end}
{p2line}
{p2colreset}{...}

{pstd}
{bf:Wide format output:}
{p_end}
{phang2}• Year columns are prefixed with {cmd:yr} (e.g., {cmd:yr2018}, {cmd:yr2019}){p_end}
{phang2}• Context/dimension variables appear before year columns{p_end}
{phang2}• All variable names are lowercase with descriptive labels{p_end}

{marker options}{...}
{title:Options}

{dlgtab:Required}

{p 4 4 2}{cmdab:ind:icator(}{it:string}{cmd:)} is required. Specifies the indicator code(s)
to fetch. Examples: {cmd:SP.POP.TOTL}, {cmd:CME_MRY0T4}, {cmd:NT_ANT_WHZ_PO2}.

{dlgtab:Data Source}

{p 4 4 2}{opt ag:ency(string)} specifies the data provider agency. Default is {cmd:UNICEF}.
Other options: {cmd:WB} (World Bank), {cmd:WHO}, {cmd:IMF}, etc.
Ignored if {opt dataflow()} is specified.

{p 4 4 2}{opt dataflow(string)} manually specifies the dataflow to bypass auto-detection.
Format: {cmd:AGENCY.DATAFLOW_CODE} (e.g., {cmd:UNICEF.CME}, {cmd:WB.DF_WBOPENDATA}).
Use this when the dataflow is known to skip YAML lookup overhead.

{dlgtab:Filtering}

{p 4 4 2}{opt cou:ntries(string)} specifies ISO3 country code(s) to filter. Optional.
Format: Single code ({cmd:"BRA"}) or plus-separated list ({cmd:"BRA+MEX+ARG"}).
Special: {cmd:"all"} or empty = fetch all countries. Default is empty (all countries).

{p 4 4 2}{opt fi:lter(string)} specifies a dimension filter vector (space-separated values).
Format: {cmd:"sex_val age_val wealth_val residence_val maternal_edu_val"}
Example: {cmd:"_T Y0T4 Q1 _T _T"}
Used by {cmd:unicefdata} wrapper to build efficient URLs. Tokens may include {cmd:+} 
to request multiple members within a dimension.

{p 4 4 2}{opt nofilter} fetches all disaggregations (slower). By default, efficient 
filtering is used (totals only).

{p 4 4 2}{opt year(string)} specifies year(s) to retrieve. Supports three formats:
{p_end}
{phang2}{bf:Single year:} {cmd:year(2020)} - fetch only 2020{p_end}
{phang2}{bf:Range:} {cmd:year(2015:2023)} - fetch years 2015 through 2023{p_end}
{phang2}{bf:List:} {cmd:year(2015,2018,2020)} - fetch specific non-contiguous years{p_end}
{pstd}
If omitted, all available years are retrieved. Overrides {opt start_period()} 
and {opt end_period()} if specified.

{p 4 4 2}{opt start_period(string)} and {opt end_period(string)} restrict time range.
Format: {cmd:YYYY} (e.g., {cmd:2015}). Ignored if {opt year()} is specified.

{dlgtab:Output}

{p 4 4 2}{opt det:ail(string)} specifies the query type. Default is {cmd:data}.
Options: {cmd:data} (fetch observations), {cmd:structure} (fetch schema/DSD).

{p 4 4 2}{opt for:mat(string)} specifies API response format. Default is {cmd:csv}.
Options: {cmd:csv}, {cmd:sdmx-xml}, {cmd:sdmx-json}, {cmd:sdmx-compact-2.1}.

{p 4 4 2}{opt lab:els(string)} specifies column labels format. Default is {cmd:id}.
Options: {cmd:both} (codes and names), {cmd:id} (codes only), {cmd:none}.

{p 4 4 2}{opt file:name(string)} specifies file path for saving downloaded CSV.
When specified: saves API response to this file, returns path in {cmd:r(datafile)}.
When omitted: creates tempfile, loads data directly into memory.
Example: {cmd:filename("C:/temp/data.csv")}

{p 4 4 2}{opt wide} returns data in wide format using csv-ts API output.
By default, data is returned in long format (observations in rows).
When {opt wide} is specified: uses {cmd:format=csv-ts} for transposed format,
with years as columns (prefixed {cmd:yr}), series metadata as rows.
Significantly faster than Stata reshape (~1-2 seconds vs 5-10 seconds).
Useful when you want to work with year columns directly or reshape within your domain logic.

{p 4 4 2}{opt cle:ar} clears existing data in memory before loading new data from API.
Default is {cmd:noclear} (preserves existing data). Use {opt clear} to replace data
completely. This option follows Stata convention ({cmd:insheet} {opt clear}).
Example: {cmd:get_sdmx, indicator(CME_MRY0T4) clear}

{p 4 4 2}{opt coun:try_names} adds a country name column to the output. Default is on.

{dlgtab:Performance}

{p 4 4 2}{opt ret:ry(int)} specifies number of retry attempts on failure. Default is {cmd:3}.

{p 4 4 2}{opt cac:he} enables schema caching for improved performance on subsequent calls.
First call: ~2.2 seconds (API + schema fetch). Cached call: ~0.13 seconds.

{dlgtab:Debugging}

{p 4 4 2}{opt ver:bose} displays progress messages during fetch.

{p 4 4 2}{opt debug} displays maximum debugging information including:
system network configuration, full URL details, detailed error codes,
API response preview, and network diagnostics.

{p 4 4 2}{opt trace} enables Stata trace on network calls.
Use with {cmd:set tracedepth 1} for deeper inspection.
Usually combined with {opt debug} for maximum detail.

{marker results}{...}
{title:Stored results}

{p}
{cmd:get_sdmx} stores the following in {cmd:r()}:
{p_end}

{synoptset 20 tabbed}{...}
{synopt:{cmd:r(csv_file)}}path to fetched CSV file{p_end}
{synopt:{cmd:r(datafile)}}path to data file (when {opt filename()} used){p_end}
{synopt:{cmd:r(n_obs)}}number of observations returned{p_end}
{synopt:{cmd:r(n_vars)}}number of variables returned{p_end}
{synopt:{cmd:r(time_series)}}comma-separated list of time periods{p_end}
{synopt:{cmd:r(api_url)}}final API URL used for fetch{p_end}
{synopt:{cmd:r(dataflow)}}resolved dataflow ID{p_end}

{marker examples}{...}
{title:Examples}

{pstd}
Fetch UNICEF child mortality indicator (auto-detect dataflow):

{phang2}{cmd:. get_sdmx, indicator(CME_MRY0T4)}{p_end}

{pstd}
Fetch with manual dataflow to skip YAML lookup:

{phang2}{cmd:. get_sdmx, indicator(CME_MRY0T4) dataflow(UNICEF.CME)}{p_end}

{pstd}
Fetch with country filter:

{phang2}{cmd:. get_sdmx, indicator(CME_MRY0T4) countries(BRA+MEX+ARG)}{p_end}

{pstd}
Fetch with time period and verbose output:

{phang2}{cmd:. get_sdmx, indicator(CME_MRY0T4) year(2015:2023) verbose}{p_end}

{pstd}
Save to file instead of loading into memory:

{phang2}{cmd:. get_sdmx, indicator(CME_MRY0T4) filename("C:/temp/cme_data.csv")}{p_end}

{pstd}
Fetch data in wide format (years as columns):

{phang2}{cmd:. get_sdmx, indicator(CME_MRY0T4) countries(USA+CAN+MEX) wide}{p_end}

{pstd}
Fetch with wide format and clear existing data:

{phang2}{cmd:. get_sdmx, indicator(CME_MRY0T4) wide clear}{p_end}

{pstd}
Fetch with caching for repeated calls:

{phang2}{cmd:. get_sdmx, indicator(CME_MRY0T4) cache}{p_end}

{pstd}
Debug connection issues:

{phang2}{cmd:. get_sdmx, indicator(CME_MRY0T4) debug verbose}{p_end}

{title:Version history}

{p 4 4 2}
{bf:v1.3.3 (20Jan2026)} - Wide format improvements: all variable names lowercase,
all variables have descriptive labels, context/dimension variables ordered before year columns.

{p 4 4 2}
{bf:v1.3.2 (20Jan2026)} - Added {opt wide} and {opt clear} options.
{opt wide} uses csv-ts API format for transposed output (1-2s vs 5-10s reshape).
{opt clear} controls whether to clear existing data before loading (follows Stata convention).

{p 4 4 2}
{bf:v1.2.0 (18Jan2026)} - Added {opt filename()} parameter for flexible data handling.
When specified, saves CSV to file and lets caller handle import.
When omitted, creates tempfile and loads data directly into memory.

{p 4 4 2}
{bf:v1.1.0 (17Jan2026)} - Integrated intelligent query filter engine.
Auto-detects query mode, extracts dimensions from dataflow schemas,
enhanced verbose output showing query mode and filter dimensions.

{p 4 4 2}
{bf:v1.0.0} - Initial release with paging, retry logic, caching, and multi-agency support.

{title:Author}

{p 4 4 2}
João Pedro Azevedo, UNICEF{break}
{browse "https://jpazvd.github.io"}
{p_end}

{title:See also}

{p 4 4 2}
{help unicefdata} (main user-facing command){break}
{help unicefdata_sync} (metadata synchronization){break}
{help unicefdata_examples} (gallery of examples)
{p_end}
