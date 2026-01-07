{smcl}
{* *! version 1.5.2  06Jan2026}{...}
{vieweralsosee "[R] import delimited" "help import delimited"}{...}
{vieweralsosee "" "--"}{...}
{vieweralsosee "unicefdata_sync" "help unicefdata_sync"}{...}
{vieweralsosee "wbopendata" "help wbopendata"}{...}
{vieweralsosee "yaml" "help yaml"}{...}
{viewerjumpto "Syntax" "unicefdata##syntax"}{...}
{viewerjumpto "Discovery" "unicefdata##discovery"}{...}
{viewerjumpto "Description" "unicefdata##description"}{...}
{viewerjumpto "Options" "unicefdata##options"}{...}
{viewerjumpto "Examples" "unicefdata##examples"}{...}
{viewerjumpto "Stored results" "unicefdata##results"}{...}
{viewerjumpto "Metadata" "unicefdata##metadata"}{...}
{viewerjumpto "Author" "unicefdata##author"}{...}
{title:Title}

{p2colset 5 20 22 2}{...}
{p2col :{cmd:unicefdata} {hline 2}}Download indicators from UNICEF Data Warehouse{p_end}
{p2colreset}{...}


{marker whatsnew}{...}
{title:What's New in v1.5.2}

{pstd}
{bf:wide_indicators Enhancements:} The {opt wide_indicators} reshape now ensures all requested 
indicators have columns in the output, even when some indicators have zero observations after 
filtering. This prevents "variable not found" errors and improves reliability for cross-indicator analysis.
{p_end}

{pstd}
{bf:Network Robustness:} All HTTP requests now use curl with proper User-Agent identification 
("unicefdata/1.5.2 (Stata)"), providing:
{phang2}• Better SSL/TLS support across platforms{p_end}
{phang2}• Improved proxy handling{p_end}
{phang2}• Automatic retry logic{p_end}
{phang2}• Reduced rate-limiting issues{p_end}
{phang2}• Automatic fallback to Stata's import delimited if curl unavailable{p_end}
{p_end}


{marker syntax}{...}
{title:Syntax}

{pstd}
{ul:Data Retrieval}

{p 8 16 2}
{cmd:unicefdata}
{cmd:,} {opt ind:icator(string)} [{it:options}]

{p 8 16 2}
{cmd:unicefdata}
{cmd:,} {opt data:flow(string)} [{it:options}]


{marker discovery}{...}
{pstd}
{ul:Discovery Commands} {it:(New in v1.3.0, enhanced v1.5.0)}

{p 8 16 2}
{cmd:unicefdata, flows} [{opt detail} {opt verbose}]

{p 8 16 2}
{cmd:unicefdata, dataflows} - alias for flows

{p 8 16 2}
{cmd:unicefdata, dataflow(}{it:dataflow}{cmd:)} - show dataflow schema {it:(v1.5.1)}

{p 8 16 2}
{cmd:unicefdata, search(}{it:keyword}{cmd:)} [{opt limit(#)}]

{p 8 16 2}
{cmd:unicefdata, indicators(}{it:dataflow}{cmd:)}

{p 8 16 2}
{cmd:unicefdata, info(}{it:indicator}{cmd:)}


{synoptset 28 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Main}
{synopt:{opt ind:icator(string)}}indicator code(s) to download (e.g., CME_MRY0T4){p_end}
{synopt:{opt data:flow(string)}}dataflow ID (e.g., CME, NUTRITION){p_end}
{synopt:{opt count:ries(string)}}ISO3 country codes, space or comma separated{p_end}
{synopt:{opt year(string)}}year(s): single (2020), range (2015:2023), or list (2015,2018,2020){p_end}
{synopt:{opt circa}}find closest available year for each country{p_end}

{syntab:Discovery (v1.3.0)}
{synopt:{opt flows}}list available UNICEF SDMX dataflows{p_end}
{synopt:{opt dataflows}}alias for flows{p_end}
{synopt:{opt dataflow(string)}}show dataflow schema (dimensions, attributes) {it:(v1.5.1)}{p_end}
{synopt:{opt search(string)}}search indicators by keyword{p_end}
{synopt:{opt indicators(string)}}list indicators in a specific dataflow{p_end}
{synopt:{opt info(string)}}display detailed info for an indicator{p_end}

{syntab:Disaggregation Filters}
{synopt:{opt sex(string)}}sex filter: _T (total), F (female), M (male), or ALL{p_end}
{synopt:{opt age(string)}}age group filter{p_end}
{synopt:{opt wealth(string)}}wealth quintile filter{p_end}
{synopt:{opt residence(string)}}residence filter (URBAN, RURAL){p_end}
{synopt:{opt maternal_edu(string)}}maternal education filter{p_end}

{syntab:Output Options}
{synopt:{opt long}}keep data in long format (default){p_end}
{synopt:{opt wide}}reshape data to wide format (years as columns with yr prefix){p_end}
{synopt:{opt wide_attributes}}reshape with disaggregation attributes as column suffixes {it:(v1.5.1)}{p_end}
{synopt:{opt wide_indicators}}reshape with indicators as columns {it:(v1.3.0)}{p_end}
{synopt:{opt attributes(string)}}attributes to keep for wide_indicators format; space-separated list of attribute codes (e.g., {cmd:_T _M _F _Q1 _Q2}) or {cmd:ALL} to keep all attributes {it:(v1.5.1)}{p_end}
{synopt:{opt addmeta(string)}}add metadata: region, income_group, continent {it:(v1.3.0)}{p_end}
{synopt:{opt dropna}}drop observations with missing values{p_end}
{synopt:{opt simplify}}keep only essential columns{p_end}
{synopt:{opt latest}}keep only most recent value per country{p_end}
{synopt:{opt mrv(#)}}keep N most recent values per country{p_end}
{synopt:{opt raw}}return raw data without standardization{p_end}

{syntab:Technical}
{synopt:{opt version(string)}}SDMX version (default: 1.0){p_end}
{synopt:{opt page_size(#)}}rows per API request (default: 100000){p_end}
{synopt:{opt max_retries(#)}}number of retry attempts (default: 3){p_end}
{synopt:{opt fallback}}try alternative dataflows on 404 {it:(v1.3.0)}{p_end}
{synopt:{opt nofallback}}disable automatic dataflow fallback{p_end}
{synopt:{opt validate}}validate inputs against YAML codelists{p_end}
{synopt:{opt nometadata}}show brief summary instead of full indicator metadata{p_end}
{synopt:{opt clear}}replace data in memory{p_end}
{synopt:{opt verbose}}display progress messages{p_end}
{synopt:{opt curl}}use curl for HTTP requests with User-Agent header {it:(v1.5.2, default)}{p_end}
{synopt:{opt nocurl}}disable curl; use Stata's import delimited instead{p_end}
{synoptline}


{marker description}{...}
{title:Description}

{pstd}
{cmd:unicefdata} downloads indicator data from the {browse "https://data.unicef.org/":UNICEF Data Warehouse} 
using the SDMX REST API. The command provides access to hundreds of indicators 
covering child health, nutrition, education, protection, HIV/AIDS, WASH, and more.

{pstd}
The UNICEF Data Warehouse contains data organized by {it:dataflows} (thematic areas) 
and {it:indicators} (specific measures). You can specify either:

{phang2}1. An {opt indicator()} code, which will auto-detect the appropriate dataflow{p_end}
{phang2}2. A {opt dataflow()} ID to download all indicators in that dataflow{p_end}

{pstd}
{it:Metadata display (v1.5.0):} When downloading data for a single indicator, {cmd:unicefdata}
automatically displays a brief metadata summary showing the indicator name, dataflow,
and supported disaggregations. This helps users understand which filter options
(sex, age, wealth, residence, maternal_edu) are valid for each indicator.
Use {cmd:unicefdata, info(}{it:indicator}{cmd:)} to view detailed indicator metadata.

{pstd}
Data is returned in a standardized format with short variable names and descriptive labels:
{p_end}

{phang2}{cmd:Core variables (always present):}{p_end}
{phang2}{space 4}{cmd:iso3} - ISO3 country code{p_end}
{phang2}{space 4}{cmd:country} - Country name{p_end}
{phang2}{space 4}{cmd:indicator} - Indicator code{p_end}
{phang2}{space 4}{cmd:indicator_name} - Indicator name{p_end}
{phang2}{space 4}{cmd:period} - Time period (year or decimal year for monthly data){p_end}
{phang2}{space 4}{cmd:value} - Observation value{p_end}

{phang2}{cmd:Disaggregation variables:}{p_end}
{phang2}{space 4}{cmd:sex} - Sex code (_T=Total, F=Female, M=Male){p_end}
{phang2}{space 4}{cmd:sex_name} - Sex{p_end}
{phang2}{space 4}{cmd:age} - Age group{p_end}
{phang2}{space 4}{cmd:wealth} - Wealth quintile code{p_end}
{phang2}{space 4}{cmd:wealth_name} - Wealth quintile{p_end}
{phang2}{space 4}{cmd:residence} - Residence type (Urban/Rural){p_end}
{phang2}{space 4}{cmd:matedu} - Maternal education level{p_end}

{phang2}{cmd:Quality and metadata:}{p_end}
{phang2}{space 4}{cmd:unit} - Unit of measure code{p_end}
{phang2}{space 4}{cmd:unit_name} - Unit of measure{p_end}
{phang2}{space 4}{cmd:lb} - Lower confidence bound{p_end}
{phang2}{space 4}{cmd:ub} - Upper confidence bound{p_end}
{phang2}{space 4}{cmd:status} - Observation status code{p_end}
{phang2}{space 4}{cmd:status_name} - Observation status{p_end}
{phang2}{space 4}{cmd:source} - Data source{p_end}
{phang2}{space 4}{cmd:refper} - Reference period{p_end}
{phang2}{space 4}{cmd:notes} - Country notes{p_end}

{pstd}
{it:Note:} All variables have descriptive labels accessible via {cmd:describe} or {cmd:codebook}.
Variable names are aligned with the R {cmd:get_unicef()} and Python {cmd:unicef_api} packages.
{p_end}


{marker options}{...}
{title:Options}

{dlgtab:Main}

{phang}
{opt indicator(string)} specifies the indicator code(s) to download. 
Multiple indicators can be separated by spaces. Example indicators include:
{p_end}
{phang2}{cmd:CME_MRY0T4} - Under-5 mortality rate{p_end}
{phang2}{cmd:CME_MRY0} - Infant mortality rate{p_end}
{phang2}{cmd:NT_ANT_HAZ_NE2} - Stunting prevalence{p_end}
{phang2}{cmd:IM_DTP3} - DTP3 immunization coverage{p_end}
{phang2}{cmd:WS_PPL_W-B} - Basic drinking water services{p_end}

{phang}
{opt dataflow(string)} specifies the dataflow ID. Common dataflows include:
{p_end}
{phang2}{cmd:CME} - Child mortality estimates{p_end}
{phang2}{cmd:NUTRITION} - Nutrition indicators{p_end}
{phang2}{cmd:IMMUNISATION} - Immunization coverage{p_end}
{phang2}{cmd:EDUCATION} - Education indicators{p_end}
{phang2}{cmd:WASH_HOUSEHOLDS} - Water, sanitation, and hygiene{p_end}
{phang2}{cmd:HIV_AIDS} - HIV/AIDS indicators{p_end}
{phang2}{cmd:MNCH} - Maternal, newborn, child health{p_end}
{phang2}{cmd:ECD} - Early childhood development{p_end}
{phang2}{cmd:PT} - Child protection{p_end}

{phang}
{opt countries(string)} filters data to specific countries using ISO3 codes.
Multiple codes can be space or comma separated (e.g., {cmd:countries(ALB USA BRA)}).

{phang}
{opt year(string)} specifies the year(s) to retrieve. Supports three formats:
{p_end}
{phang2}{bf:Single year:} {cmd:year(2020)} - fetch only 2020{p_end}
{phang2}{bf:Range:} {cmd:year(2015:2023)} - fetch years 2015 through 2023{p_end}
{phang2}{bf:List:} {cmd:year(2015,2018,2020)} - fetch non-contiguous years{p_end}
{pstd}
If omitted, all available years are retrieved.

{phang}
{opt circa} finds the closest available year for each country when the exact 
requested year is not available. This allows cross-country comparisons when 
data availability varies. Different countries may have different actual years 
in the result. Only applies when {opt year()} is specified.
{p_end}
{pstd}
Example: {cmd:year(2015), circa} might return 2014 data for Country A and 
2016 data for Country B if 2015 is not available for either.

{dlgtab:Disaggregation Filters}

{phang}
{opt sex(string)} filters by sex. Values include:
{p_end}
{phang2}{cmd:_T} - Total (both sexes, default){p_end}
{phang2}{cmd:F} - Female{p_end}
{phang2}{cmd:M} - Male{p_end}
{phang2}{cmd:ALL} - Keep all disaggregations{p_end}

{phang}
{opt age(string)}, {opt wealth(string)}, {opt residence(string)}, and 
{opt maternal_edu(string)} provide additional disaggregation filters.

{pstd}
{it:Default behavior:} If you omit a disaggregation option, {cmd:unicefdata} defaults
to totals ({cmd:_T}) for sex, age, wealth, residence, and maternal_edu. Specify
{cmd:ALL} to keep all available categories instead of the total-only default.

{pstd}
{it:Missing filter values:} If you request a disaggregation value that is not present
in the data, {cmd:unicefdata} leaves the dataset unchanged. With {opt verbose}, a note
is shown indicating the requested value was not found.

{dlgtab:Discovery Commands (v1.3.0)}

{phang}
{opt flows} lists all available UNICEF SDMX dataflows. Use {opt detail} for 
extended information and {opt verbose} for metadata path. {opt dataflows} is 
an alias for {opt flows}.
{p_end}

{phang}
{opt dataflow(string)} {it:(v1.5.1)} displays the schema for a specific dataflow,
including its dimensions (REF_AREA, INDICATOR, SEX, etc.) and attributes
(DATA_SOURCE, OBS_STATUS, etc.). This helps understand the structure of
the data and which filter options are available.
{p_end}

{phang}
{opt search(string)} searches for indicators by keyword. Searches both 
indicator codes and names (case-insensitive). Use {opt limit(#)} to control
maximum results.
{p_end}

{phang}
{opt indicators(string)} lists all indicators available in a specific dataflow.
For example, {cmd:unicefdata, indicators(CME)} shows all child mortality indicators.
{p_end}

{phang}
{opt info(string)} displays detailed metadata for a specific indicator, including
its name, category (dataflow), description, and supported disaggregations (sex, age,
wealth, residence, maternal education). This uses the dataflow schema files in
{cmd:_dataflows/} to determine which filter options are valid for each indicator.
{p_end}

{dlgtab:Output Options}

{pstd}
{bf:Understanding Output Formats:}

{pstd}
{cmd:unicefdata} offers four output formats for different analytical needs. The default 
is {cmd:long}, which is the most flexible. The three {cmd:wide_*} options reshape data 
for specific cross-tabulation or pivot scenarios.

{phang}
{opt long} keeps data in long format (one observation per country-year-indicator).
This is the default format from the SDMX API and the most flexible for data analysis.
All disaggregation variables (sex, age, wealth, residence, matedu) are present as 
separate columns. Use this format when you need maximum flexibility.
{p_end}

{phang}
{opt wide} reshapes data to wide format with years as columns, using {cmd:yr} prefix.
Result structure:
{p_end}
{phang2}Rows: iso3 x indicator x all disaggregation values (sex, wealth, age, residence, matedu){p_end}
{phang2}Columns: yr2018, yr2019, yr2020, yr2021, etc. (years with "yr" prefix){p_end}
{phang2}Use case: Time-series analysis, trend visualization{p_end}

{phang}
{opt wide_attributes} {it:(v1.5.1)} reshapes data to wide format with disaggregation 
attributes as column suffixes. Use this when you want all disaggregation variations 
as separate columns.
{p_end}
{phang2}Result structure:{p_end}
{phang2}Rows: iso3 x country x period (time years){p_end}
{phang2}Columns: indicator_T, indicator_M, indicator_F, indicator_Q1, etc.{p_end}
{phang2}Use case: Compare disaggregations side-by-side, wealth gap analysis, gender parity analysis{p_end}
{phang2}Example for sex: CME_MRY0T4_T (total), CME_MRY0T4_M (male), CME_MRY0T4_F (female){p_end}
{phang2}Example for wealth: NT_ANT_HAZ_NE2_Q1 (poorest), ..., NT_ANT_HAZ_NE2_Q5 (richest){p_end}
{phang2}Example for combined: CME_MRY0T4_M_Q1 (male in poorest quintile){p_end}
{phang2}Use {opt attributes()} to filter which suffixes appear in output{p_end}

{phang}
{opt wide_indicators} {it:(v1.3.0; enhanced v1.5.2)} reshapes data so that different indicators 
become separate columns. Use this for cross-indicator analysis.
{p_end}
{phang2}Result structure:{p_end}
{phang2}Rows: iso3 x country x period (and optionally disaggregations if attributes=ALL){p_end}
{phang2}Columns: CME_MRY0T4, IM_DTP3, NT_ANT_HAZ_NE2, etc. (indicators as columns){p_end}
{phang2}Default behavior: Keeps only _T (total) for all disaggregations (backward compatible){p_end}
{phang2}v1.5.2 improvement: Now creates empty numeric columns for all requested indicators, {p_end}
{phang2}even when some indicators have zero observations after filtering. This prevents reshape{p_end}
{phang2}failures and "variable not found" errors.{p_end}
{phang2}Use case: Compare multiple indicators side-by-side, correlation analysis, reliable batch processing{p_end}

{phang}
{opt attributes(string)} {it:(v1.5.1)} specifies which disaggregation attribute values 
to keep when using {cmd:wide_attributes} or {cmd:wide_indicators}. This allows flexible 
filtering of rows before reshaping.
{p_end}

{pstd}
{bf:Key Facts About attributes():}
{p_end}
{phang2}• Works with: {cmd:wide_attributes} and {cmd:wide_indicators} (not with {cmd:long} or {cmd:wide}){p_end}
{phang2}• Syntax: Accepts space-separated attribute codes, case-insensitive{p_end}
{phang2}• Default for {cmd:wide_indicators}: _T (total only) - backward compatible{p_end}
{phang2}• Default for {cmd:wide_attributes}: No default - if attributes() not specified, all values included{p_end}
{phang2}• Special keyword: {cmd:ALL} - keep all attribute combinations{p_end}
{phang2}• Filtering applied: BEFORE reshape operations, not after{p_end}

{pstd}
{bf:Important Constraint:} {cmd:wide_attributes} and {cmd:wide_indicators} {bf:cannot}} 
be used together. This is because they represent different reshape strategies. 
Attempting both simultaneously results in ERROR 198.
{p_end}

{pstd}
{bf:Common Patterns:}

{phang2}{bf:Pattern 1:} Time-series analysis
{p_end}
{phang3}{cmd:wide} option x years as columns for trend visualization{p_end}

{phang2}{bf:Pattern 2:} Equity gap analysis (wealth, gender, geography)
{p_end}
{phang3}{cmd:wide_attributes attributes(_T _Q1 _Q5)} - compare richest vs poorest{p_end}
{phang3}{cmd:wide_attributes attributes(_T _M _F)} - compare gender disparities{p_end}

{phang2}{bf:Pattern 3:} Cross-indicator comparison
{p_end}
{phang3}{cmd:wide_indicators} - multiple indicators as columns for one period{p_end}

{phang2}{bf:Pattern 4:} Full disaggregation matrix
{p_end}
{phang3}{cmd:wide_indicators attributes(ALL)} - all sex/age/wealth combinations{p_end}

{pstd}
{bf:Supported Attribute Codes:}

{phang2}{bf:Sex (_T, _M, _F):}
{p_end}
{phang3}{cmd:_T} = Total (both sexes){p_end}
{phang3}{cmd:_M} = Male{p_end}
{phang3}{cmd:_F} = Female{p_end}

{phang2}{bf:Wealth Quintiles (_T, _Q1, _Q2, _Q3, _Q4, _Q5):}
{p_end}
{phang3}{cmd:_T} = Total{p_end}
{phang3}{cmd:_Q1} = Poorest quintile{p_end}
{phang3}{cmd:_Q2} = Second quintile{p_end}
{phang3}{cmd:_Q3} = Middle quintile{p_end}
{phang3}{cmd:_Q4} = Fourth quintile{p_end}
{phang3}{cmd:_Q5} = Richest quintile{p_end}

{phang2}{bf:Residence (_T, _U, _R):}
{p_end}
{phang3}{cmd:_T} = Total{p_end}
{phang3}{cmd:_U} = Urban{p_end}
{phang3}{cmd:_R} = Rural{p_end}

{phang2}{bf:Age (varies by indicator):}
{p_end}
{phang3}{cmd:_T} = Total{p_end}
{phang3}{cmd:_0}} through {cmd:_18} = Age-specific codes (varies by indicator){p_end}

{phang2}{bf:Maternal Education (_T, _NoEd, _Prim, _Sec, _High):}
{p_end}
{phang3}{cmd:_T} = Total{p_end}
{phang3}{cmd:_NoEd} = No education{p_end}
{phang3}{cmd:_Prim} = Primary education{p_end}
{phang3}{cmd:_Sec} = Secondary education{p_end}
{phang3}{cmd:_High} = Higher education{p_end}

{phang2}{bf:Special Keyword:}
{p_end}
{phang3}{cmd:ALL} = Keep all attribute combinations (no filtering){p_end}

{pstd}
{bf:attributes() Examples:}

{phang2}{cmd:attributes(_T _M _F)} - Keep total, male, and female; drop other sex categories{p_end}
{phang2}{cmd:attributes(_Q1 _Q2 _Q3 _Q4 _Q5)} - Keep all quintiles; drop total{p_end}
{phang2}{cmd:attributes(_T _Q1 _Q2 _Q3 _Q4 _Q5)} - Keep total and all quintiles{p_end}
{phang2}{cmd:attributes(_U _R)} - Keep urban and rural only; drop total{p_end}
{phang2}{cmd:attributes(ALL)} - No filtering; keep all disaggregation combinations{p_end}

{pstd}
{bf:Important Notes:}

{phang2}1. {cmd:attributes()} filtering is applied {bf:before} reshape, not after.{p_end}
{phang2}2. If you specify invalid attribute codes, they are silently ignored.{p_end}
{phang2}3. If no rows match the filter, all rows are kept (with a warning in verbose mode).{p_end}
{phang2}4. Case-insensitive: {cmd:attributes(_T)}} = {cmd:attributes(_t)}}.{p_end}
{phang2}5. For {cmd:wide_indicators}}, default ({cmd:attributes()}}} empty) = {cmd:_T}} (totals only).{p_end}
{phang2}6. For {cmd:wide_attributes}}, default ({cmd:attributes()}}} empty) = All values included.{p_end}

{phang}
{opt addmeta(string)} {it:(v1.3.0)} adds metadata columns to the output. 
Available metadata includes:
{p_end}
{phang2}{cmd:region} - UNICEF regional classification{p_end}
{phang2}{cmd:income_group} - World Bank income classification{p_end}
{phang2}{cmd:continent} - Geographic continent{p_end}
{phang2}Example: {cmd:addmeta(region income_group)}{p_end}

{phang}
{opt dropna} drops observations with missing values. Aligned with R/Python {cmd:dropna} parameter.

{phang}
{opt simplify} keeps only essential columns: {cmd:iso3}, {cmd:country}, {cmd:indicator}, 
{cmd:period}, {cmd:value}, {cmd:lb}, {cmd:ub}. Aligned with R/Python {cmd:simplify} parameter.

{phang}
{opt latest} keeps only the most recent non-missing value for each country.
Useful for cross-sectional analysis.

{phang}
{opt mrv(#)} keeps the N most recent values for each country.

{phang}
{opt raw} returns raw SDMX data without variable renaming or standardization.

{dlgtab:Technical}

{phang}
{opt curl} {it:(v1.5.2, default)} uses curl for HTTP requests with proper User-Agent identification.
This provides robust network handling with:
{phang2}• Better SSL/TLS and HTTPS support across platforms{p_end}
{phang2}• Automatic proxy detection and handling{p_end}
{phang2}• Automatic retry logic for temporary network failures{p_end}
{phang2}• User-Agent header: "unicefdata/1.5.2 (Stata)"{p_end}
{phang2}• Automatic fallback to Stata's import delimited if curl is unavailable{p_end}
{pstd}
If your Stata installation lacks curl support or you prefer Stata's default import method,
use {opt nocurl} to disable curl and use Stata's import delimited instead.
{p_end}

{phang}
{opt max_retries(#)} specifies the number of retry attempts (default: 3). 
(Aligned with R/Python syntax.)

{phang}
{opt fallback} {it:(v1.3.0)} enables automatic fallback to alternative dataflows
when the primary dataflow returns no data or a 404 error. This is enabled by
default when specifying an indicator.
{p_end}

{phang}
{opt nofallback} {it:(v1.3.0)} disables the automatic dataflow fallback mechanism.
{p_end}

{phang}
{opt nometadata} suppresses the automatic display of indicator metadata when
retrieving data. By default, {cmd:unicefdata} displays a brief summary of the
indicator (name, dataflow, supported disaggregations) when downloading data.
Use this option to skip the metadata display.
{p_end}

{phang}
{opt clear} allows the command to replace existing data in memory.

{phang}
{opt verbose} displays progress messages during data download.


{marker examples}{...}
{title:Examples}

{pstd}
{ul:Discovery Commands (v1.3.0)}

{pstd}
List available dataflows:{p_end}
{p 8 12}{stata "unicefdata, flows" :. unicefdata, flows}{p_end}

{pstd}
List dataflows with names:{p_end}
{p 8 12}{stata "unicefdata, flows detail" :. unicefdata, flows detail}{p_end}

{pstd}
Show dataflow schema (dimensions and attributes):{p_end}
{p 8 12}{stata "unicefdata, dataflow(EDUCATION)" :. unicefdata, dataflow(EDUCATION)}{p_end}

{pstd}
Show CME dataflow schema:{p_end}
{p 8 12}{stata "unicefdata, dataflow(CME)" :. unicefdata, dataflow(CME)}{p_end}

{pstd}
List all indicator categories with counts:{p_end}
{p 8 12}{stata "unicefdata, categories" :. unicefdata, categories}{p_end}

{pstd}
Search for mortality-related indicators:{p_end}
{p 8 12}{stata "unicefdata, search(mortality)" :. unicefdata, search(mortality)}{p_end}

{pstd}
Search within a specific dataflow:{p_end}
{p 8 12}{stata "unicefdata, search(rate) dataflow(CME)" :. unicefdata, search(rate) dataflow(CME)}{p_end}

{pstd}
List indicators in the CME (Child Mortality Estimates) dataflow:{p_end}
{p 8 12}{stata "unicefdata, indicators(CME)" :. unicefdata, indicators(CME)}{p_end}

{pstd}
Get detailed info about an indicator:{p_end}
{p 8 12}{stata "unicefdata, info(CME_MRY0T4)" :. unicefdata, info(CME_MRY0T4)}{p_end}

{pstd}
{ul:Data Retrieval}

{pstd}
Download under-5 mortality rate for all countries:{p_end}
{p 8 12}{stata "unicefdata, indicator(CME_MRY0T4) clear" :. unicefdata, indicator(CME_MRY0T4) clear}{p_end}

{pstd}
Download for specific countries:{p_end}
{p 8 12}{stata "unicefdata, indicator(CME_MRY0T4) countries(ALB USA BRA) clear" :. unicefdata, indicator(CME_MRY0T4) countries(ALB USA BRA) clear}{p_end}

{pstd}
Download with year range:{p_end}
{p 8 12}{stata "unicefdata, indicator(CME_MRY0T4) year(2010:2023) clear" :. unicefdata, indicator(CME_MRY0T4) year(2010:2023) clear}{p_end}

{pstd}
Download specific years (non-contiguous):{p_end}
{p 8 12}{stata "unicefdata, indicator(CME_MRY0T4) year(2015,2018,2020) clear" :. unicefdata, indicator(CME_MRY0T4) year(2015,2018,2020) clear}{p_end}

{pstd}
Get latest value per country:{p_end}
{p 8 12}{stata "unicefdata, indicator(CME_MRY0T4) latest clear" :. unicefdata, indicator(CME_MRY0T4) latest clear}{p_end}

{pstd}
Get female-only data:{p_end}
{p 8 12}{stata "unicefdata, indicator(CME_MRY0T4) sex(F) clear" :. unicefdata, indicator(CME_MRY0T4) sex(F) clear}{p_end}

{pstd}
Download all indicators from a dataflow:{p_end}
{p 8 12}{stata "unicefdata, dataflow(CME) countries(ETH) clear verbose" :. unicefdata, dataflow(CME) countries(ETH) clear verbose}{p_end}

{pstd}
Get 5 most recent values per country:{p_end}
{p 8 12}{stata "unicefdata, indicator(CME_MRY0T4) mrv(5) clear" :. unicefdata, indicator(CME_MRY0T4) mrv(5) clear}{p_end}

{pstd}
Simplify output to essential columns:{p_end}
{p 8 12}{stata "unicefdata, indicator(CME_MRY0T4) simplify dropna clear" :. unicefdata, indicator(CME_MRY0T4) simplify dropna clear}{p_end}

{pstd}
{ul:Reshape Options (v1.5.1): wide, wide_attributes, wide_indicators with attributes()}

{pstd}
{bf:Understanding the Three Reshape Options:}

{phang}
{bf:1. wide} - Pivots years as columns (standard time-series format):
{p_end}
{phang2}Rows: iso3 × indicator × disaggregation attributes (sex, age, wealth, etc.)
{p_end}
{phang2}Columns: yr2018, yr2019, yr2020, yr2021 (years as columns with "yr" prefix)
{p_end}
{phang2}Use: When you want time-series analysis with years as columns
{p_end}

{phang}
{bf:2. wide_attributes} - Pivots disaggregation suffixes (e.g., sex, wealth):
{p_end}
{phang2}Rows: iso3 × country × period (time)
{p_end}
{phang2}Columns: indicator_T, indicator_M, indicator_F (for sex disaggregation)
{p_end}
{phang2}Use: When you want all attribute variations as separate columns
{p_end}
{phang2}Example: CME_MRY0T4_T (total), CME_MRY0T4_M (male), CME_MRY0T4_F (female)
{p_end}

{phang}
{bf:3. wide_indicators} - Pivots indicators as columns (cross-indicator analysis):
{p_end}
{phang2}Rows: iso3 × country × period × (optionally disaggregations if attributes=ALL)
{p_end}
{phang2}Columns: CME_MRY0T4, IM_DTP3, NT_ANT_HAZ_NE2 (indicators as columns)
{p_end}
{phang2}Use: When you want to compare multiple indicators side-by-side
{p_end}
{phang2}Default: Keeps only _T (total) for all disaggregations (backward compatible)
{p_end}

{pstd}
{bf:Important:} {cmd:wide_attributes} and {cmd:wide_indicators} {bf:cannot}} be used together.
Choose one reshape option. The {opt attributes()} option applies filtering before 
reshape and works with both options.

{pstd}
{ul:Supported Attribute Codes for attributes() Option:}

{phang}
{bf:Sex disaggregation:}
{p_end}
{phang2}{cmd:_T} - Total (both sexes){p_end}
{phang2}{cmd:_M} - Male{p_end}
{phang2}{cmd:_F} - Female{p_end}

{phang}
{bf:Wealth quintile:}
{p_end}
{phang2}{cmd:_T} - Total{p_end}
{phang2}{cmd:_Q1} - Poorest quintile{p_end}
{phang2}{cmd:_Q2} - Second quintile{p_end}
{phang2}{cmd:_Q3} - Middle quintile{p_end}
{phang2}{cmd:_Q4} - Fourth quintile{p_end}
{phang2}{cmd:_Q5} - Richest quintile{p_end}

{phang}
{bf:Residence:}
{p_end}
{phang2}{cmd:_T} - Total{p_end}
{phang2}{cmd:_U} - Urban{p_end}
{phang2}{cmd:_R} - Rural{p_end}

{phang}
{bf:Special keyword:}
{p_end}
{phang2}{cmd:ALL} - Keep all attribute combinations{p_end}

{pstd}
{ul:Interactive Examples - Reshape with attributes()}

{pstd}
{bf:Example 1:} Wide format with years as columns (standard time-series):{p_end}
{cmd}
        . unicefdata, indicator(CME_MRY0T4) countries(USA BRA) year(2018:2021) ///
            wide clear
        . list iso3 indicator yr2018 yr2019 yr2020 yr2021
{txt}      
Result: One row per iso3 × indicator; columns are yr2018, yr2019, yr2020, yr2021

{pstd}
{bf:Example 2:} wide_attributes - Get all sex disaggregations as suffixes:{p_end}
{cmd}
        . unicefdata, indicator(CME_MRY0T4) countries(USA BRA) year(2020) ///
            sex(ALL) wide_attributes clear
        . describe
        . list iso3 period CME_MRY0T4_T CME_MRY0T4_M CME_MRY0T4_F in 1/4
{txt}

Result: Columns include CME_MRY0T4_T (total), CME_MRY0T4_M (male), CME_MRY0T4_F (female)

{pstd}
{bf:Example 3:} wide_attributes with attributes() - Keep only males and females (no total):{p_end}
{cmd}
        . unicefdata, indicator(CME_MRY0T4) countries(USA BRA) year(2020) ///
            sex(ALL) wide_attributes attributes(_M _F) clear
        . describe
{txt}

Result: Only columns for _M and _F; no _T column (filtered out by attributes())

{pstd}
{bf:Example 4:} wide_indicators - Multiple indicators as columns (default _T only):{p_end}
{cmd}
        . unicefdata, indicator(CME_MRY0T4 IM_DTP3) countries(USA BRA CHN) ///
            year(2020) wide_indicators clear
        . list iso3 period CME_MRY0T4 IM_DTP3 in 1/6
{txt}

Result: Rows are iso3 × country × period; columns are CME_MRY0T4 and IM_DTP3 (indicators)
Automatically filters to _T (total) for backward compatibility

{pstd}
{bf:Example 5:} wide_indicators with sex disaggregation matrix (attributes=ALL):{p_end}
{cmd}
        . unicefdata, indicator(CME_MRY0T4 IM_DTP3) countries(USA BRA) ///
            year(2020) sex(ALL) wide_indicators attributes(ALL) clear
        . describe
{txt}

Result: Rows include all sex combinations; multiple rows per iso3×period (one per sex value)
Columns: iso3, country, period, sex, CME_MRY0T4, IM_DTP3

{pstd}
{bf:Example 6:} wide_indicators with custom attributes (wealth quintiles only):{p_end}
{cmd}
        . unicefdata, indicator(NT_ANT_HAZ_NE2) countries(ETH KEN UGA) ///
            year(2020) wealth(ALL) wide_indicators attributes(_Q1 _Q2 _Q3 _Q4 _Q5) clear
        . list iso3 period NT_ANT_HAZ_NE2 in 1/10
{txt}

Result: Only rows for wealth quintiles Q1-Q5; no total (_T) because it's filtered out

{pstd}
{bf:Example 7:} Combining wide with multiple indicators and visualization:{p_end}
{cmd}
        . unicefdata, indicator(CME_MRY0T4 CME_MRY0) countries(USA BRA IND) ///
            year(2010:2023) wide clear
        . reshape long CME_MRY0T4 CME_MRY0, i(iso3 country indicator) j(year) string
        . gen year_num = real(subinstr(year, "yr", "", 1))
        . graph twoway ///
            (line CME_MRY0T4 year_num if iso3=="USA", lcolor(blue)) ///
            (line CME_MRY0T4 year_num if iso3=="BRA", lcolor(red)) ///
            (line CME_MRY0T4 year_num if iso3=="IND", lcolor(green)), ///
                title("Under-5 Mortality Trends") ///
                xtitle("Year") ytitle("Deaths per 1,000 live births")
{txt}

{pstd}
{bf:Example 8:} wide_attributes for wealth gap analysis:{p_end}
{cmd}
        . unicefdata, indicator(NT_ANT_HAZ_NE2) countries(ETH KEN UGA) ///
            year(2020) wealth(ALL) wide_attributes attributes(_Q1 _Q5) clear
        . gen wealth_gap = NT_ANT_HAZ_NE2_Q5 - NT_ANT_HAZ_NE2_Q1
        . gsort -wealth_gap
        . list iso3 country NT_ANT_HAZ_NE2_Q1 NT_ANT_HAZ_NE2_Q5 wealth_gap
{txt}

Result: Q1=poorest, Q5=richest; gap shows wealth inequality in stunting

{pstd}
{bf:Example 9:} Comparing attribute codes - see what filtering does:{p_end}
{cmd}
        . * Approach 1: Download with attributes(_T _M _F) for wide_indicators
        . unicefdata, indicator(CME_MRY0T4) countries(USA) year(2020) ///
            sex(ALL) wide_indicators attributes(_T _M _F) clear
        . di "Default narrow attributes(_T _M _F): " _N " observations"
        . 
        . * Approach 2: Download with attributes(ALL) for full matrix
        . unicefdata, indicator(CME_MRY0T4) countries(USA) year(2020) ///
            sex(ALL) wide_indicators attributes(ALL) clear
        . di "With attributes(ALL): " _N " observations"
{txt}

Result: The attributes() filter controls how many rows are kept (affects analysis structure)

{pstd}
{bf:Example 10:} ERROR - Using both reshape options together (not allowed):{p_end}
{cmd}
        . unicefdata, indicator(CME_MRY0T4) countries(USA) year(2020) ///
            wide_attributes wide_indicators clear
{txt}

Error: "Error: wide_attributes and wide_indicators cannot be used together."

{pstd}
{ul:Advanced Reshape Scenarios}

{pstd}
{bf:Cross-indicator comparison with wealth disaggregation:}
{p_end}
{cmd}
        . unicefdata, indicator(CME_MRY0T4 NT_ANT_HAZ_NE2 IM_DTP3) ///
            countries(ETH KEN UGA) year(2020) wealth(ALL) ///
            wide_indicators attributes(_T _Q1 _Q5) clear
        . keep if wealth == "_T"
        . describe
        . list iso3 CME_MRY0T4 NT_ANT_HAZ_NE2 IM_DTP3 in 1/6
{txt}

{pstd}
{bf:Export reshaped data to Excel by format:}
{p_end}
{cmd}
        . * Wide format export
        . unicefdata, indicator(CME_MRY0T4) countries(ALB BRA) year(2015:2023) ///
            wide clear
        . export excel using "u5mr_wide_format.xlsx", firstrow(variables) replace
        .
        . * wide_attributes export
        . unicefdata, indicator(CME_MRY0T4) countries(ALB BRA) year(2020) ///
            sex(ALL) wide_attributes clear
        . export excel using "u5mr_by_sex.xlsx", firstrow(variables) replace
        .
        . * wide_indicators export
        . unicefdata, indicator(CME_MRY0T4 IM_DTP3) countries(ALB BRA) ///
            year(2020) wide_indicators clear
        . export excel using "mortality_immunization_comparison.xlsx", firstrow(variables) replace
{txt}

{pstd}
{ul:v1.3.0-v1.5.0 Features}

{pstd}
Add regional and income group metadata:{p_end}
{p 8 12}{stata "unicefdata, indicator(CME_MRY0T4) addmeta(region income_group) clear" :. unicefdata, indicator(CME_MRY0T4) addmeta(region income_group) clear}{p_end}

{pstd}
Circa matching (find closest year):{p_end}
{p 8 12}{stata "unicefdata, indicator(CME_MRY0T4) year(2020) circa clear" :. unicefdata, indicator(CME_MRY0T4) year(2020) circa clear}{p_end}

{pstd}
{ul:Nutrition Indicators}

{pstd}
Stunting prevalence:{p_end}
{p 8 12}{stata "unicefdata, indicator(NT_ANT_HAZ_NE2) clear" :. unicefdata, indicator(NT_ANT_HAZ_NE2) clear}{p_end}

{pstd}
Stunting by wealth quintile (Q1=poorest):{p_end}
{p 8 12}{stata "unicefdata, indicator(NT_ANT_HAZ_NE2) wealth(Q1) clear" :. unicefdata, indicator(NT_ANT_HAZ_NE2) wealth(Q1) clear}{p_end}

{pstd}
Stunting by residence (rural only):{p_end}
{p 8 12}{stata "unicefdata, indicator(NT_ANT_HAZ_NE2) residence(RURAL) clear" :. unicefdata, indicator(NT_ANT_HAZ_NE2) residence(RURAL) clear}{p_end}

{pstd}
{ul:Immunization Indicators}

{pstd}
DTP3 immunization coverage:{p_end}
{p 8 12}{stata "unicefdata, indicator(IM_DTP3) clear" :. unicefdata, indicator(IM_DTP3) clear}{p_end}

{pstd}
Measles immunization coverage:{p_end}
{p 8 12}{stata "unicefdata, indicator(IM_MCV1) clear" :. unicefdata, indicator(IM_MCV1) clear}{p_end}

{pstd}
{ul:WASH Indicators}

{pstd}
Basic drinking water services:{p_end}
{p 8 12}{stata "unicefdata, indicator(WS_PPL_W-B) clear" :. unicefdata, indicator(WS_PPL_W-B) clear}{p_end}

{pstd}
Basic sanitation services:{p_end}
{p 8 12}{stata "unicefdata, indicator(WS_PPL_S-B) clear" :. unicefdata, indicator(WS_PPL_S-B) clear}{p_end}

{pstd}
{ul:Education Indicators}

{pstd}
Out-of-school rate, primary:{p_end}
{p 8 12}{stata "unicefdata, indicator(EDUNF_OFST_L1) clear" :. unicefdata, indicator(EDUNF_OFST_L1) clear}{p_end}

{pstd}
Net attendance rate, primary:{p_end}
{p 8 12}{stata "unicefdata, indicator(ED_ANAR_L1) clear" :. unicefdata, indicator(ED_ANAR_L1) clear}{p_end}

{pstd}
{ul:Export Examples}

{pstd}
Download and export to Excel:{p_end}
{p 8 12}{stata "unicefdata, indicator(CME_MRY0T4) countries(ALB USA BRA) clear" :. unicefdata, indicator(CME_MRY0T4) countries(ALB USA BRA) clear}{p_end}
{p 8 12}{stata `"export excel using "mortality_data.xlsx", firstrow(variables) replace"' :. export excel using "mortality_data.xlsx", firstrow(variables) replace}{p_end}

{pstd}
Download and export to CSV:{p_end}
{p 8 12}{stata "unicefdata, indicator(CME_MRY0T4) countries(ALB USA BRA) clear" :. unicefdata, indicator(CME_MRY0T4) countries(ALB USA BRA) clear}{p_end}
{p 8 12}{stata `"export delimited using "mortality_data.csv", replace"' :. export delimited using "mortality_data.csv", replace}{p_end}

{pstd}
{ul:Advanced Examples}

{pstd}
Under-5 mortality trend analysis for South Asian countries:{p_end}
{cmd}
        . unicefdata, indicator(CME_MRY0T4) countries(AFG BGD BTN IND MDV NPL PAK LKA) clear
        . keep if sex == "_T"
        . graph twoway ///
            (connected value period if iso3 == "AFG", lcolor(red)) ///
            (connected value period if iso3 == "BGD", lcolor(blue)) ///
            (connected value period if iso3 == "IND", lcolor(green)) ///
            (connected value period if iso3 == "PAK", lcolor(orange)), ///
                legend(order(1 "Afghanistan" 2 "Bangladesh" 3 "India" 4 "Pakistan")) ///
                ytitle("Under-5 mortality rate") title("U5MR Trends in South Asia")
{txt}      ({stata "unicefdata_examples example01":click to run})

{pstd}
Stunting prevalence by wealth quintile:{p_end}
{cmd}
        . unicefdata, indicator(NT_ANT_HAZ_NE2) sex(ALL) latest clear
        . keep if inlist(wealth, "Q1", "Q2", "Q3", "Q4", "Q5")
        . gen wealth_num = real(substr(wealth, 2, 1))
        . collapse (mean) mean_stunting = value, by(wealth wealth_num)
        . graph bar mean_stunting, over(wealth) ///
            ytitle("Stunting prevalence (%)") ///
            title("Child Stunting by Wealth Quintile")
{txt}      ({stata "unicefdata_examples example02":click to run})

{pstd}
Multiple mortality indicators comparison for Latin America:{p_end}
{cmd}
        . unicefdata, indicator(CME_MRY0T4 CME_MRY0 CME_MRM0) ///
            countries(BRA MEX ARG COL PER CHL) year(2020:2023) clear
        . keep if sex == "_T"
        . bysort iso3 indicator (period): keep if _n == _N
        . keep iso3 country indicator value
        . reshape wide value, i(iso3 country) j(indicator) string
        . graph bar valueCME_MRY0T4 valueCME_MRY0 valueCME_MRM0, ///
            over(country, label(angle(45))) ///
            legend(order(1 "Under-5" 2 "Infant" 3 "Neonatal"))
{txt}      ({stata "unicefdata_examples example03":click to run})

{pstd}
Global immunization coverage trends:{p_end}
{cmd}
        . unicefdata, indicator(IM_DTP3 IM_MCV1) year(2000:2023) clear
        . keep if sex == "_T"
        . collapse (mean) coverage = value, by(period indicator)
        . reshape wide coverage, i(period) j(indicator) string
        . graph twoway ///
            (line coverageIM_DTP3 period, lcolor(blue)) ///
            (line coverageIM_MCV1 period, lcolor(red)), ///
                legend(order(1 "DTP3" 2 "MCV1")) ///
                title("Global Immunization Coverage Trends")
{txt}      ({stata "unicefdata_examples example04":click to run})

{pstd}
Regional comparison with metadata:{p_end}
{cmd}
        . unicefdata, indicator(CME_MRY0T4) addmeta(region income_group) latest clear
        . keep if geo_type == "country" & sex == "_T"
        . collapse (mean) avg_u5mr = value, by(region)
        . gsort -avg_u5mr
        . graph hbar avg_u5mr, over(region, sort(1) descending) ///
            ytitle("Under-5 mortality rate") ///
            title("U5MR by UNICEF Region")
{txt}      ({stata "unicefdata_examples example05":click to run})

{pstd}
Export comprehensive data to Excel:{p_end}
{cmd}
        . unicefdata, indicator(CME_MRY0T4) countries(ALB USA BRA IND CHN NGA) ///
            year(2015:2023) addmeta(region income_group) clear
        . keep iso3 country region income_group period value lb ub
        . export excel using "unicef_mortality_data.xlsx", firstrow(variables) replace
{txt}      ({stata "unicefdata_examples example06":click to run})

{pstd}
WASH urban-rural gap analysis:{p_end}
{cmd}
        . unicefdata, indicator(WS_PPL_W-B) sex(ALL) latest clear
        . keep if inlist(residence, "U", "R", "URBAN", "RURAL")
        . replace residence = "Urban" if inlist(residence, "U", "URBAN")
        . replace residence = "Rural" if inlist(residence, "R", "RURAL")
        . bysort iso3 : egen n_res = nvals(residence)
        . keep if n_res == 2
        . reshape wide value, i(iso3 country) j(residence) string
        . gen gap = valueUrban - valueRural
        . gsort -gap
        . list iso3 country valueUrban valueRural gap in 1/10
{txt}      ({stata "unicefdata_examples example07":click to run})

{pstd}
Using {opt wide} option - Time series format:{p_end}
{cmd}
        . unicefdata, indicator(CME_MRY0T4) countries(USA BRA IND CHN) ///
            year(2015:2023) wide clear
        . keep if sex == "_T"
        . list iso3 country yr2015 yr2020 yr2023, sep(0) noobs
        . gen change_2015_2023 = yr2023 - yr2015
        . gen pct_change = (change_2015_2023 / yr2015) * 100
{txt}      ({stata "unicefdata_examples example08":click to run})

{pstd}
Using {opt wide_indicators} - Multiple indicators as columns (v1.5.2):{p_end}
{cmd}
        . unicefdata, indicator(CME_MRY0T4 CME_MRY0 IM_DTP3 IM_MCV1) ///
            countries(AFG ETH PAK NGA) latest wide_indicators clear
        . keep if sex == "_T"
        . describe CME_MRY0T4 CME_MRY0 IM_DTP3 IM_MCV1
        . list iso3 country CME_MRY0T4 CME_MRY0 IM_DTP3 IM_MCV1, sep(0) noobs
        . correlate CME_MRY0T4 IM_DTP3
{txt}      ({stata "unicefdata_examples example09":click to run})

{pstd}
Using {opt wide_attributes} - Disaggregations as columns (v1.5.1):{p_end}
{cmd}
        . unicefdata, indicator(CME_MRY0T4) countries(IND PAK BGD) ///
            year(2020) sex(ALL) wide_attributes clear
        . list iso3 country CME_MRY0T4_T CME_MRY0T4_M CME_MRY0T4_F, sep(0) noobs
        . gen mf_gap = CME_MRY0T4_M - CME_MRY0T4_F
{txt}      ({stata "unicefdata_examples example10":click to run})

{pstd}
Using {opt attributes()} filter - Targeted disaggregation:{p_end}
{cmd}
        . unicefdata, indicator(NT_ANT_HAZ_NE2) countries(IND PAK BGD ETH) ///
            latest attributes(_T _Q1 _Q5) wide_attributes clear
        . list iso3 country NT_ANT_HAZ_NE2_T NT_ANT_HAZ_NE2_Q1 NT_ANT_HAZ_NE2_Q5, ///
            sep(0) noobs
        . gen wealth_gap = NT_ANT_HAZ_NE2_Q1 - NT_ANT_HAZ_NE2_Q5
{txt}      ({stata "unicefdata_examples example11":click to run})

{pstd}
{ul:Metadata Sync}

{pstd}
Sync all metadata from UNICEF API:{p_end}
{p 8 12}{stata "unicefdata_sync, all" :. unicefdata_sync, all}{p_end}

{pstd}
Sync indicators only:{p_end}
{p 8 12}{stata "unicefdata_sync, indicators" :. unicefdata_sync, indicators}{p_end}


{marker results}{...}
{title:Stored results}

{pstd}
{cmd:unicefdata} stores the following in {cmd:r()}:

{synoptset 25 tabbed}{...}
{p2col 5 25 29 2: Scalars}{p_end}
{synopt:{cmd:r(obs_count)}}number of observations downloaded{p_end}

{p2col 5 25 29 2: Macros}{p_end}
{synopt:{cmd:r(indicator)}}indicator code(s) requested{p_end}
{synopt:{cmd:r(dataflow)}}dataflow ID used{p_end}
{synopt:{cmd:r(countries)}}countries requested (if specified){p_end}
{synopt:{cmd:r(start_year)}}start year (if specified){p_end}
{synopt:{cmd:r(end_year)}}end year (if specified){p_end}
{synopt:{cmd:r(wide)}}wide format indicator{p_end}
{synopt:{cmd:r(wide_indicators)}}wide_indicators format indicator {it:(v1.3.0)}{p_end}
{synopt:{cmd:r(addmeta)}}metadata columns added {it:(v1.3.0)}{p_end}
{synopt:{cmd:r(url)}}API URL used for download{p_end}

{p2col 5 25 29 2: Indicator Metadata (single indicator only)}{p_end}
{synopt:{cmd:r(indicator_name)}}full indicator name{p_end}
{synopt:{cmd:r(indicator_category)}}indicator category{p_end}
{synopt:{cmd:r(indicator_dataflow)}}dataflow containing this indicator{p_end}
{synopt:{cmd:r(indicator_description)}}indicator description{p_end}
{synopt:{cmd:r(indicator_urn)}}SDMX URN identifier{p_end}
{synopt:{cmd:r(has_sex)}}1 if sex disaggregation supported{p_end}
{synopt:{cmd:r(has_age)}}1 if age disaggregation supported{p_end}
{synopt:{cmd:r(has_wealth)}}1 if wealth quintile supported{p_end}
{synopt:{cmd:r(has_residence)}}1 if urban/rural supported{p_end}
{synopt:{cmd:r(has_maternal_edu)}}1 if maternal education supported{p_end}
{synopt:{cmd:r(supported_dims)}}list of supported dimensions (e.g., "sex wealth"){p_end}

{pstd}
Discovery commands store additional results:

{p2col 5 25 29 2: flows}{p_end}
{synopt:{cmd:r(n_dataflows)}}number of dataflows found{p_end}
{synopt:{cmd:r(dataflow_ids)}}list of dataflow IDs{p_end}

{p2col 5 25 29 2: search}{p_end}
{synopt:{cmd:r(n_matches)}}number of matching indicators{p_end}
{synopt:{cmd:r(indicators)}}list of matching indicator codes{p_end}
{synopt:{cmd:r(keyword)}}search keyword used{p_end}

{p2col 5 25 29 2: indicators}{p_end}
{synopt:{cmd:r(n_indicators)}}number of indicators in dataflow{p_end}
{synopt:{cmd:r(indicators)}}list of indicator codes{p_end}
{synopt:{cmd:r(dataflow)}}dataflow queried{p_end}

{p2col 5 25 29 2: info}{p_end}
{synopt:{cmd:r(indicator)}}indicator code{p_end}
{synopt:{cmd:r(name)}}indicator name{p_end}
{synopt:{cmd:r(category)}}category (usually same as dataflow){p_end}
{synopt:{cmd:r(dataflow)}}dataflow ID for this indicator{p_end}
{synopt:{cmd:r(description)}}indicator description{p_end}
{synopt:{cmd:r(has_sex)}}1 if sex disaggregation supported{p_end}
{synopt:{cmd:r(has_age)}}1 if age disaggregation supported{p_end}
{synopt:{cmd:r(has_wealth)}}1 if wealth quintile supported{p_end}
{synopt:{cmd:r(has_residence)}}1 if urban/rural supported{p_end}
{synopt:{cmd:r(has_maternal_edu)}}1 if maternal education supported{p_end}
{synopt:{cmd:r(supported_dims)}}list of supported dimensions{p_end}


{marker metadata}{...}
{title:YAML Metadata}

{pstd}
{cmd:unicefdata} uses two types of YAML metadata for discovery and validation,
aligned with the R {cmd:get_unicef()} and Python {cmd:unicef_api} implementations.

{dlgtab:Indicator Metadata}

{pstd}
Indicator-level metadata provides information about each of the 733 indicators:
{p_end}

{phang2}{cmd:_unicefdata_indicators_metadata.yaml} - Full indicator catalog{p_end}
{phang3}Contains: code, name, description, URN, category, dataflow{p_end}
{phang3}Use case: {cmd:info(indicator)}, {cmd:search(keyword)}, dataflow auto-detection{p_end}

{dlgtab:Dataflow Metadata}

{pstd}
Dataflow-level metadata provides information about each of the 69 dataflows:
{p_end}

{phang2}{cmd:_unicefdata_dataflows.yaml} - Dataflow summary (name, agency, version){p_end}
{phang3}Use case: {cmd:categories} listing, dataflow descriptions{p_end}

{phang2}{cmd:_dataflows/*.yaml} - Per-dataflow schema files (69 files){p_end}
{phang3}Contains: dimensions (SEX, AGE, WEALTH_QUINTILE, RESIDENCE, etc.){p_end}
{phang3}Use case: {cmd:info(indicator)} disaggregation support, filter validation{p_end}

{dlgtab:Reference Metadata}

{pstd}
Reference metadata for valid codes and country/region lists:
{p_end}

{phang2}{cmd:_unicefdata_codelists.yaml} - Valid codes for sex, age, wealth, residence{p_end}
{phang2}{cmd:_unicefdata_countries.yaml} - 453 country ISO3 codes{p_end}
{phang2}{cmd:_unicefdata_regions.yaml} - 111 regional aggregate codes{p_end}

{pstd}
The {helpb yaml} command is used to parse these files. If {cmd:yaml} is not installed,
the command falls back to prefix-based dataflow detection.

{pstd}
To synchronize metadata from the UNICEF SDMX API:{p_end}
{phang2}{cmd:. unicefdata_sync, verbose}{p_end}

{pstd}
To install the {cmd:yaml} package:{p_end}
{phang2}{cmd:. ssc install yaml}{p_end}


{marker consistency}{...}
{title:Cross-Platform Consistency}

{pstd}
All three platforms (Python, R, Stata) generate identical metadata files with:

{phang2}- Same record counts (69 dataflows, 453 countries, etc.){p_end}
{phang2}- Same field names and structures{p_end}
{phang2}- Standardized {cmd:_metadata} headers with platform, version, timestamp{p_end}
{phang2}- Shared indicator definitions from {cmd:config/common_indicators.yaml}{p_end}

{pstd}
Use the Python status script to verify consistency:{p_end}
{phang2}{cmd:python tests/generate_metadata_status.py --detailed}{p_end}


{marker author}{...}
{title:Author}

{pstd}
Joao Pedro Azevedo{break}
UNICEF{break}
jazevedo@unicef.org

{pstd}
This command is part of the {cmd:unicefData} package, which provides 
R, Python, and Stata interfaces to the UNICEF Data Warehouse.

{pstd}
For more information, see {browse "https://github.com/unicef-drp/unicefData"}


{title:Also see}

{psee}
Online: {browse "https://data.unicef.org/":UNICEF Data Warehouse}, 
{browse "https://sdmx.data.unicef.org/":UNICEF SDMX API}

{psee}
Help: {helpb unicefdata_sync}, {helpb wbopendata} (similar command for World Bank data)
{p_end}