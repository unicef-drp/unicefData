{smcl}
{* *! version 1.6.0  16Jan2026}{...}
{vieweralsosee "[D] unicefdata_xmltoyaml" "help unicefdata_xmltoyaml"}{...}
{vieweralsosee "[D] unicefdata_sync" "help unicefdata_sync"}{...}
{viewerjumpto "Syntax" "unicefdata_xmltoyaml_py##syntax"}{...}
{viewerjumpto "Description" "unicefdata_xmltoyaml_py##description"}{...}
{viewerjumpto "Options" "unicefdata_xmltoyaml_py##options"}{...}
{title:unicefdata_xmltoyaml_py — Python implementation of XML-to-YAML conversion}

{marker syntax}{...}
{title:Syntax}

{p 8 16 2}
{cmdab:unicefdata_xmltoyaml_py}{cmd:,}
{cmd:input(}{it:string}{cmd:)}
{cmd:output(}{it:string}{cmd:)}
[{opt noisily}
]

{marker description}{...}
{title:Description}

{p}
{cmd:unicefdata_xmltoyaml_py} is the Python implementation of XML-to-YAML conversion
for SDMX structure definitions.
{p_end}

{p}
This command is a high-performance alternative to {cmd:unicefdata_xmltoyaml} when
Python is available. It provides faster conversion for large dataflow structures.

{marker options}{...}
{title:Options}

{p 4 4 2}{cmd:input(}{it:string}{cmd:)} is required. Path to input XML file.

{p 4 4 2}{cmd:output(}{it:string}{cmd:)} is required. Path to output YAML file.

{p 4 4 2}{opt noisily} displays conversion progress messages.

{marker examples}{...}
{title:Examples}

{p 4 4 2}
Run Python-based conversion:
{p_end}

{p 8 12 2}
{cmd:. unicefdata_xmltoyaml_py, input(structure.xml) output(structure.yml)}
{p_end}

{title:Technical Details}

{p}
Requires Python 3.6+ with {cmd:yaml} and {cmd:xml.etree.ElementTree} modules.
Falls back to Stata implementation if Python is unavailable.

{title:Author}

{p}
João Pedro Azevedo, UNICEF{break}
https://jpazvd.github.io{break}
}

{title:See also}

{p}
{help unicefdata_xmltoyaml}{break}
{help unicefdata_sync}
{p_end}
