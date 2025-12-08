{smcl}
{* *! version 1.2.1  07Dec2025}{...}
{vieweralsosee "[R] import delimited" "help import delimited"}{...}
{vieweralsosee "" "--"}{...}
{vieweralsosee "wbopendata" "help wbopendata"}{...}
{vieweralsosee "yaml" "help yaml"}{...}
{viewerjumpto "Syntax" "unicefdata##syntax"}{...}
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


{marker syntax}{...}
{title:Syntax}

{p 8 16 2}
{cmd:unicefdata}
{cmd:,} {opt ind:icator(string)} [{it:options}]

{p 8 16 2}
{cmd:unicefdata}
{cmd:,} {opt data:flow(string)} [{it:options}]


{synoptset 25 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Main}
{synopt:{opt ind:icator(string)}}indicator code(s) to download (e.g., CME_MRY0T4){p_end}
{synopt:{opt data:flow(string)}}dataflow ID (e.g., CME, NUTRITION){p_end}
{synopt:{opt count:ries(string)}}ISO3 country codes, space or comma separated{p_end}
{synopt:{opt start_year(#)}}start year for data range{p_end}
{synopt:{opt end_year(#)}}end year for data range{p_end}

{syntab:Disaggregation Filters}
{synopt:{opt sex(string)}}sex filter: _T (total), F (female), M (male), or ALL{p_end}
{synopt:{opt age(string)}}age group filter{p_end}
{synopt:{opt wealth(string)}}wealth quintile filter{p_end}
{synopt:{opt residence(string)}}residence filter (URBAN, RURAL){p_end}
{synopt:{opt maternal_edu(string)}}maternal education filter{p_end}

{syntab:Output Options}
{synopt:{opt long}}keep data in long format (default){p_end}
{synopt:{opt wide}}reshape data to wide format (indicators as columns){p_end}
{synopt:{opt dropna}}drop observations with missing values{p_end}
{synopt:{opt simplify}}keep only essential columns (iso3, country, indicator, period, value, lb, ub){p_end}
{synopt:{opt latest}}keep only most recent value per country{p_end}
{synopt:{opt mrv(#)}}keep N most recent values per country{p_end}
{synopt:{opt raw}}return raw data without standardization{p_end}

{syntab:Technical}
{synopt:{opt version(string)}}SDMX version (default: 1.0){p_end}
{synopt:{opt page_size(#)}}rows per API request (default: 100000){p_end}
{synopt:{opt max_retries(#)}}number of retry attempts (default: 3){p_end}
{synopt:{opt validate}}validate inputs against YAML codelists{p_end}
{synopt:{opt clear}}replace data in memory{p_end}
{synopt:{opt verbose}}display progress messages{p_end}
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
{opt start_year(#)} and {opt end_year(#)} specify the year range for data retrieval.
(Aligned with R/Python syntax.)

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

{dlgtab:Output Options}

{phang}
{opt long} keeps data in long format (one observation per country-year-indicator).
This is the default format from the SDMX API.

{phang}
{opt wide} reshapes data to wide format with indicators as columns.

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
{opt max_retries(#)} specifies the number of retry attempts (default: 3). 
(Aligned with R/Python syntax.)

{phang}
{opt clear} allows the command to replace existing data in memory.

{phang}
{opt verbose} displays progress messages during data download.


{marker examples}{...}
{title:Examples}

{pstd}
Download under-5 mortality rate for all countries:{p_end}
{phang2}{cmd:. unicefdata, indicator(CME_MRY0T4) clear}{p_end}

{pstd}
Download for specific countries:{p_end}
{phang2}{cmd:. unicefdata, indicator(CME_MRY0T4) countries(ALB USA BRA) clear}{p_end}

{pstd}
Download with year range (aligned R/Python syntax):{p_end}
{phang2}{cmd:. unicefdata, indicator(CME_MRY0T4) start_year(2010) end_year(2023) clear}{p_end}

{pstd}
Get latest value per country:{p_end}
{phang2}{cmd:. unicefdata, indicator(CME_MRY0T4) latest clear}{p_end}

{pstd}
Get female-only data:{p_end}
{phang2}{cmd:. unicefdata, indicator(CME_MRY0T4) sex(F) clear}{p_end}

{pstd}
Download all indicators from a dataflow:{p_end}
{phang2}{cmd:. unicefdata, dataflow(NUTRITION) countries(ETH) clear verbose}{p_end}

{pstd}
Get 5 most recent values per country:{p_end}
{phang2}{cmd:. unicefdata, indicator(CME_MRY0T4) mrv(5) clear}{p_end}

{pstd}
Simplify output to essential columns (like R/Python):{p_end}
{phang2}{cmd:. unicefdata, indicator(CME_MRY0T4) simplify dropna clear}{p_end}

{pstd}
Wide format output:{p_end}
{phang2}{cmd:. unicefdata, dataflow(CME) countries(BRA ARG) wide clear}{p_end}


{marker results}{...}
{title:Stored results}

{pstd}
{cmd:unicefdata} stores the following in {cmd:r()}:

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Scalars}{p_end}
{synopt:{cmd:r(obs_count)}}number of observations downloaded{p_end}

{p2col 5 20 24 2: Macros}{p_end}
{synopt:{cmd:r(indicator)}}indicator code(s) requested{p_end}
{synopt:{cmd:r(dataflow)}}dataflow ID used{p_end}
{synopt:{cmd:r(countries)}}countries requested (if specified){p_end}
{synopt:{cmd:r(start_year)}}start year (if specified){p_end}
{synopt:{cmd:r(end_year)}}end year (if specified){p_end}
{synopt:{cmd:r(wide)}}wide format indicator{p_end}
{synopt:{cmd:r(url)}}API URL used for download{p_end}


{marker metadata}{...}
{title:YAML Metadata}

{pstd}
{cmd:unicefdata} uses YAML metadata files for dataflow auto-detection and input validation,
aligned with the R {cmd:get_unicef()} and Python {cmd:unicef_api} implementations.

{pstd}
Metadata files are located in {cmd:stata/metadata/current/}:

{phang2}{cmd:_unicefdata_dataflows.yaml} - 69 SDMX dataflow definitions{p_end}
{phang2}{cmd:_unicefdata_indicators.yaml} - 25 common SDG indicators{p_end}
{phang2}{cmd:_unicefdata_codelists.yaml} - Valid codes for sex, age, wealth, residence{p_end}
{phang2}{cmd:_unicefdata_countries.yaml} - 453 country ISO3 codes{p_end}
{phang2}{cmd:_unicefdata_regions.yaml} - 111 regional aggregate codes{p_end}
{phang2}{cmd:unicef_indicators_metadata.yaml} - Full indicator catalog (733 indicators){p_end}

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