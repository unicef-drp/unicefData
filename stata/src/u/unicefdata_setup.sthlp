{smcl}
{* *! version 2.0.0  01Feb2026}{...}
{vieweralsosee "unicefdata" "help unicefdata"}{...}
{vieweralsosee "unicefdata_sync" "help unicefdata_sync"}{...}
{viewerjumpto "Syntax" "unicefdata_setup##syntax"}{...}
{viewerjumpto "Description" "unicefdata_setup##description"}{...}
{viewerjumpto "Options" "unicefdata_setup##options"}{...}
{viewerjumpto "Examples" "unicefdata_setup##examples"}{...}
{title:Title}

{phang}
{bf:unicefdata_setup} {hline 2} Install YAML metadata files for unicefdata


{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmdab:unicefdata_setup}
[{cmd:,} {it:options}]

{synoptset 20 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Main}
{synopt:{opt from(url)}}specify source URL for metadata files{p_end}
{synopt:{opt replace}}overwrite existing files{p_end}
{synopt:{opt verbose}}show detailed progress{p_end}
{synoptline}


{marker description}{...}
{title:Description}

{pstd}
{cmd:unicefdata_setup} downloads and installs the YAML metadata files required
by the {cmd:unicefdata} command. These files contain indicator definitions,
dataflow mappings, country codes, and other metadata needed for the UNICEF
Data Warehouse API.

{pstd}
This command should be run once after installing the unicefdata package using
{cmd:net install} or {cmd:ssc install}. The metadata files are installed to
the {cmd:ado/plus/_/} directory.

{pstd}
The following files are installed:

{p2colset 8 40 42 2}{...}
{p2col:File}Description{p_end}
{p2line}
{p2col:{cmd:_unicefdata_dataflows.yaml}}Dataflow definitions{p_end}
{p2col:{cmd:_unicefdata_indicators.yaml}}Indicator list{p_end}
{p2col:{cmd:_unicefdata_codelists.yaml}}Code lists{p_end}
{p2col:{cmd:_unicefdata_countries.yaml}}Country codes{p_end}
{p2col:{cmd:_unicefdata_regions.yaml}}Region codes{p_end}
{p2col:{cmd:_unicefdata_sync_history.yaml}}Sync history{p_end}
{p2col:{cmd:_dataflow_index.yaml}}Dataflow index{p_end}
{p2col:{cmd:_dataflow_fallback_sequences.yaml}}Fallback sequences{p_end}
{p2col:{cmd:_unicefdata_indicators_metadata.yaml}}Full indicators metadata{p_end}
{p2col:{cmd:_indicator_dataflow_map.yaml}}Indicator to dataflow mapping{p_end}
{p2col:{cmd:_unicefdata_dataflow_metadata.yaml}}Dataflow dimensions{p_end}
{p2line}


{marker options}{...}
{title:Options}

{dlgtab:Main}

{phang}
{opt from(url)} specifies an alternative source URL for the metadata files.
The default is the GitHub repository:
{cmd:https://raw.githubusercontent.com/unicef-drp/unicefData/main/stata/src}

{pmore}
For local installation from a development directory, use:
{cmd:from("C:/GitHub/myados/unicefData-dev/stata/src")}

{phang}
{opt replace} overwrites existing metadata files. Without this option,
existing files are skipped.

{phang}
{opt verbose} displays detailed progress information including the source
and destination paths.


{marker examples}{...}
{title:Examples}

{pstd}Setup with default source (GitHub){p_end}
{phang2}{cmd:. unicefdata_setup}{p_end}

{pstd}Setup with replace to update existing files{p_end}
{phang2}{cmd:. unicefdata_setup, replace}{p_end}

{pstd}Setup from local development directory{p_end}
{phang2}{cmd:. unicefdata_setup, from("C:/GitHub/myados/unicefData-dev/stata/src") replace}{p_end}

{pstd}Verbose mode showing all details{p_end}
{phang2}{cmd:. unicefdata_setup, replace verbose}{p_end}


{marker stored_results}{...}
{title:Stored results}

{pstd}
{cmd:unicefdata_setup} stores the following in {cmd:r()}:

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Scalars}{p_end}
{synopt:{cmd:r(installed)}}number of files successfully installed{p_end}
{synopt:{cmd:r(failed)}}number of files that failed to install{p_end}

{p2col 5 20 24 2: Macros}{p_end}
{synopt:{cmd:r(targetdir)}}directory where files were installed{p_end}


{marker author}{...}
{title:Author}

{pstd}
Joao Pedro Azevedo{break}
UNICEF{break}
jpazevedo@unicef.org{break}
{browse "https://jpazvd.github.io/"}


{marker alsosee}{...}
{title:Also see}

{psee}
{space 2}Help:  {helpb unicefdata}, {helpb unicefdata_sync}
{p_end}
