{smcl}
{* *! version 1.0.0  03Dec2025}{...}
{vieweralsosee "[R] import delimited" "help import delimited"}{...}
{vieweralsosee "" "--"}{...}
{vieweralsosee "wbopendata" "help wbopendata"}{...}
{viewerjumpto "Syntax" "unicefdata##syntax"}{...}
{viewerjumpto "Description" "unicefdata##description"}{...}
{viewerjumpto "Options" "unicefdata##options"}{...}
{viewerjumpto "Examples" "unicefdata##examples"}{...}
{viewerjumpto "Stored results" "unicefdata##results"}{...}
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
{synopt:{opt start:year(#)}}start year for data range{p_end}
{synopt:{opt end:year(#)}}end year for data range{p_end}

{syntab:Disaggregation Filters}
{synopt:{opt sex(string)}}sex filter: _T (total), F (female), M (male), or ALL{p_end}
{synopt:{opt age(string)}}age group filter{p_end}
{synopt:{opt wealth(string)}}wealth quintile filter{p_end}
{synopt:{opt residence(string)}}residence filter (URBAN, RURAL){p_end}
{synopt:{opt maternal_edu(string)}}maternal education filter{p_end}

{syntab:Output Options}
{synopt:{opt long}}keep data in long format (default){p_end}
{synopt:{opt latest}}keep only most recent value per country{p_end}
{synopt:{opt mrv(#)}}keep N most recent values per country{p_end}
{synopt:{opt raw}}return raw data without standardization{p_end}
{synopt:{opt nomet:adata}}do not include metadata columns{p_end}

{syntab:Technical}
{synopt:{opt version(string)}}SDMX version (default: 1.0){p_end}
{synopt:{opt page_size(#)}}rows per API request (default: 100000){p_end}
{synopt:{opt retries(#)}}number of retry attempts (default: 3){p_end}
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
Data is returned in a standardized format with variables including:
{p_end}

{phang2}{cmd:Core variables (always present):}{p_end}
{phang2}{space 4}{cmd:iso3} - ISO 3166-1 alpha-3 country code{p_end}
{phang2}{space 4}{cmd:country} - Country name{p_end}
{phang2}{space 4}{cmd:indicator} - Indicator code{p_end}
{phang2}{space 4}{cmd:indicator_name} - Indicator description{p_end}
{phang2}{space 4}{cmd:period} - Time period (year or decimal year for monthly data){p_end}
{phang2}{space 4}{cmd:value} - Observation value{p_end}

{phang2}{cmd:Additional metadata (when available):}{p_end}
{phang2}{space 4}{cmd:unit} - Unit of measure code{p_end}
{phang2}{space 4}{cmd:unit_name} - Unit of measure description{p_end}
{phang2}{space 4}{cmd:sex} - Sex disaggregation code{p_end}
{phang2}{space 4}{cmd:sex_name} - Sex description{p_end}
{phang2}{space 4}{cmd:age} - Age group{p_end}
{phang2}{space 4}{cmd:wealth_quintile} - Wealth quintile code{p_end}
{phang2}{space 4}{cmd:wealth_quintile_name} - Wealth quintile description{p_end}
{phang2}{space 4}{cmd:residence} - Residence type (Urban/Rural){p_end}
{phang2}{space 4}{cmd:maternal_edu_lvl} - Maternal education level{p_end}
{phang2}{space 4}{cmd:lower_bound} - Lower confidence bound{p_end}
{phang2}{space 4}{cmd:upper_bound} - Upper confidence bound{p_end}
{phang2}{space 4}{cmd:obs_status} - Observation status code{p_end}
{phang2}{space 4}{cmd:obs_status_name} - Observation status description{p_end}
{phang2}{space 4}{cmd:data_source} - Data source{p_end}

{pstd}
{it:Note:} Variable names are aligned with the R {cmd:get_unicef()} and Python {cmd:unicef_api} packages
for cross-language consistency.
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
{opt startyear(#)} and {opt endyear(#)} specify the year range for data retrieval.

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
{opt latest} keeps only the most recent non-missing value for each country.
Useful for cross-sectional analysis.

{phang}
{opt mrv(#)} keeps the N most recent values for each country.

{phang}
{opt raw} returns raw SDMX data without variable renaming or standardization.

{dlgtab:Technical}

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
Download with year range:{p_end}
{phang2}{cmd:. unicefdata, indicator(CME_MRY0T4) startyear(2010) endyear(2023) clear}{p_end}

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
{synopt:{cmd:r(startyear)}}start year (if specified){p_end}
{synopt:{cmd:r(endyear)}}end year (if specified){p_end}
{synopt:{cmd:r(url)}}API URL used for download{p_end}


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
Help: {helpb wbopendata} (similar command for World Bank data)
{p_end}
