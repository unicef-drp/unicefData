{smcl}
{* *! version 1.0.0  05Dec2025}{...}
{vieweralsosee "[R] unicefdata" "help unicefdata"}{...}
{vieweralsosee "[R] yaml" "help yaml"}{...}
{viewerjumpto "Syntax" "unicefdata_sync##syntax"}{...}
{viewerjumpto "Description" "unicefdata_sync##description"}{...}
{viewerjumpto "Options" "unicefdata_sync##options"}{...}
{viewerjumpto "Examples" "unicefdata_sync##examples"}{...}
{viewerjumpto "Stored results" "unicefdata_sync##results"}{...}
{viewerjumpto "Author" "unicefdata_sync##author"}{...}
{title:Title}

{p2colset 5 26 28 2}{...}
{p2col :{cmd:unicefdata_sync} {hline 2}}Sync UNICEF metadata from SDMX API{p_end}
{p2colreset}{...}


{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmdab:unicefdata_sync}
[{cmd:,} {it:options}]

{synoptset 20 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Main}
{synopt:{opt path(string)}}directory for metadata files{p_end}
{synopt:{opt verbose}}display detailed progress{p_end}
{synopt:{opt force}}force sync even if cache is fresh{p_end}
{synoptline}


{marker description}{...}
{title:Description}

{pstd}
{cmd:unicefdata_sync} synchronizes metadata from the UNICEF SDMX Data Warehouse 
API to local YAML files. This includes dataflow definitions, codelists, 
country codes, regional aggregates, and indicator mappings.

{pstd}
All generated YAML files follow the standardized {cmd:_unicefdata_<name>.yaml} 
naming convention and include watermark headers matching the R and Python 
implementations.


{marker files}{...}
{title:Generated Files}

{pstd}
The following files are created in the metadata directory:

{p2colset 8 40 42 2}{...}
{p2col:{cmd:_unicefdata_dataflows.yaml}}SDMX dataflow definitions{p_end}
{p2col:{cmd:_unicefdata_codelists.yaml}}Valid dimension codes (sex, age, wealth, etc.){p_end}
{p2col:{cmd:_unicefdata_countries.yaml}}Country ISO3 codes from CL_COUNTRY{p_end}
{p2col:{cmd:_unicefdata_regions.yaml}}Regional aggregates from CL_WORLD_REGIONS{p_end}
{p2col:{cmd:_unicefdata_indicators.yaml}}Indicator → dataflow mappings{p_end}
{p2col:{cmd:_unicefdata_sync_history.yaml}}Sync timestamps and version history{p_end}
{p2colreset}{...}


{marker watermark}{...}
{title:Watermark Format}

{pstd}
Each YAML file includes a {cmd:_metadata} block with:

        {cmd:_metadata:}
          {cmd:platform: stata}
          {cmd:version: '2.0.0'}
          {cmd:synced_at: '2025-12-05T10:00:00Z'}
          {cmd:source: <API URL>}
          {cmd:agency: UNICEF}
          {cmd:content_type: <type>}
          {cmd:<counts>}


{marker options}{...}
{title:Options}

{dlgtab:Main}

{phang}
{opt path(string)} specifies the directory where metadata files should be saved.
If not specified, the command auto-detects the package installation directory.

{phang}
{opt verbose} displays detailed progress messages including file names and counts.

{phang}
{opt force} forces a sync operation even if the cached metadata is still fresh
(less than 30 days old).


{marker examples}{...}
{title:Examples}

{pstd}Basic sync with minimal output{p_end}
{phang2}{cmd:. unicefdata_sync}{p_end}

{pstd}Sync with detailed progress{p_end}
{phang2}{cmd:. unicefdata_sync, verbose}{p_end}

{pstd}Sync to specific directory{p_end}
{phang2}{cmd:. unicefdata_sync, path("./metadata") verbose}{p_end}

{pstd}Force sync even if cache is fresh{p_end}
{phang2}{cmd:. unicefdata_sync, force verbose}{p_end}


{marker results}{...}
{title:Stored results}

{pstd}
{cmd:unicefdata_sync} stores the following in {cmd:r()}:

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Scalars}{p_end}
{synopt:{cmd:r(dataflows)}}number of dataflows synced{p_end}
{synopt:{cmd:r(indicators)}}number of indicators synced{p_end}
{synopt:{cmd:r(codelists)}}number of codelists synced{p_end}
{synopt:{cmd:r(countries)}}number of country codes synced{p_end}
{synopt:{cmd:r(regions)}}number of regional codes synced{p_end}

{p2col 5 20 24 2: Macros}{p_end}
{synopt:{cmd:r(vintage_date)}}date of this sync (YYYY-MM-DD){p_end}
{synopt:{cmd:r(synced_at)}}ISO 8601 timestamp of sync{p_end}
{synopt:{cmd:r(path)}}path to metadata directory{p_end}


{marker author}{...}
{title:Author}

{pstd}
Joao Pedro Azevedo, UNICEF{break}
jazevedo@unicef.org

{pstd}
Part of the {cmd:unicefData} package for accessing UNICEF Data Warehouse.


{marker seealso}{...}
{title:Also see}

{psee}
{space 2}Help: {helpb unicefdata}, {helpb yaml}
{p_end}
