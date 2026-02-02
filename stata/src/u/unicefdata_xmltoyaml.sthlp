{smcl}
{* *! version 1.6.0  16Jan2026}{...}
{vieweralsosee "[D] unicefdata_sync" "help unicefdata_sync"}{...}
{vieweralsosee "[D] schema_cache" "help schema_cache"}{...}
{viewerjumpto "Syntax" "unicefdata_xmltoyaml##syntax"}{...}
{viewerjumpto "Description" "unicefdata_xmltoyaml##description"}{...}
{viewerjumpto "Options" "unicefdata_xmltoyaml##options"}{...}
{viewerjumpto "Examples" "unicefdata_xmltoyaml##examples"}{...}
{title:unicefdata_xmltoyaml — Convert SDMX XML structure to YAML}

{marker syntax}{...}
{title:Syntax}

{p 8 16 2}
{cmdab:unicefdata_xmltoyaml}{cmd:,}
{cmd:input(}{it:string}{cmd:)}
{cmd:output(}{it:string}{cmd:)}
[{opt use_python}
{opt noisily}
]

{marker description}{...}
{title:Description}

{p}
{cmd:unicefdata_xmltoyaml} converts SDMX dataflow structure definitions from XML format
(obtained from SDMX REST API) to YAML format for easier parsing and caching.
{p_end}

{p}
This utility is primarily used internally by {cmd:schema_cache} and {cmd:unicefdata_sync}.
Most users will not need to call this directly.

{marker options}{...}
{title:Options}

{p 4 4 2}{cmd:input(}{it:string}{cmd:)} is required. Path to input XML file from SDMX API.

{p 4 4 2}{cmd:output(}{it:string}{cmd:)} is required. Path to output YAML file.

{p 4 4 2}{opt use_python} uses Python implementation if available (faster for large structures).
Default: Stata implementation.

{p 4 4 2}{opt noisily} displays conversion progress and statistics.

{marker examples}{...}
{title:Examples}

{p 4 4 2}
Convert downloaded SDMX structure to YAML:
{p_end}

{p 8 12 2}
{cmd:. unicefdata_xmltoyaml, input(structure.xml) output(structure.yml)}
{p_end}

{p 4 4 2}
Use Python implementation for faster conversion:
{p_end}

{p 8 12 2}
{cmd:. unicefdata_xmltoyaml, input(large_structure.xml) output(large.yml) use_python}
{p_end}

{title:Technical Details}

{p}
This command converts the hierarchical XML structure from:
{p_end}

{p 8 12 2}
https://sdmx.data.unicef.org/ws/public/sdmxapi/rest/structure/dataflow/UNICEF.DF_CME
{p_end}

{p}
into compressed YAML format for efficient local storage and parsing.

{title:Author}

{p}
João Pedro Azevedo, UNICEF{break}
https://jpazvd.github.io{break}
}

{title:See also}

{p}
{help unicefdata_sync}{break}
{help schema_cache}{break}
{help unicefdata}
{p_end}
