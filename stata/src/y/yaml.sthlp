{smcl}
{* *! version 1.0.0  03Dec2025}{...}
{viewerjumpto "Syntax" "yaml##syntax"}{...}
{viewerjumpto "Description" "yaml##description"}{...}
{viewerjumpto "Subcommands" "yaml##subcommands"}{...}
{viewerjumpto "Options" "yaml##options"}{...}
{viewerjumpto "Examples" "yaml##examples"}{...}
{viewerjumpto "Stored results" "yaml##results"}{...}
{viewerjumpto "Author" "yaml##author"}{...}

{title:Title}

{phang}
{bf:yaml} {hline 2} Read and write YAML files in Stata


{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmd:yaml} {it:subcommand} [{cmd:using} {it:filename}] [{cmd:,} {it:options}]


{marker subcommands}{...}
{title:Subcommands}

{synoptset 16 tabbed}{...}
{synopthdr:subcommand}
{synoptline}
{synopt:{opt read}}read YAML file into Stata{p_end}
{synopt:{opt write}}write Stata data to YAML file{p_end}
{synopt:{opt describe}}display structure of loaded YAML data{p_end}
{synopt:{opt list}}list keys and values{p_end}
{synopt:{opt clear}}clear YAML data from memory{p_end}
{synoptline}
{p2colreset}{...}


{marker description}{...}
{title:Description}

{pstd}
{cmd:yaml} provides a unified interface for working with YAML files in Stata.
YAML (YAML Ain't Markup Language) is a human-readable data serialization format 
commonly used for configuration files and data exchange.

{pstd}
The command supports reading YAML files into local macros, scalars, or datasets,
and writing Stata data back to YAML format.


{marker read}{...}
{title:yaml read}

{p 8 17 2}
{cmd:yaml read}
{cmd:using} {it:filename}
[{cmd:,} {opt l:ocals} {opt s:calars} {opt d:ataset} {opt p:refix(string)} {opt replace} {opt v:erbose}]

{pstd}
Reads a YAML file and parses its contents into Stata.

{synoptset 20 tabbed}{...}
{synopthdr:options}
{synoptline}
{synopt:{opt l:ocals}}store values as local macros in r(){p_end}
{synopt:{opt s:calars}}store numeric values as Stata scalars{p_end}
{synopt:{opt d:ataset}}load YAML as a dataset{p_end}
{synopt:{opt p:refix(string)}}prefix for names; default is "yaml_"{p_end}
{synopt:{opt replace}}replace data in memory{p_end}
{synopt:{opt v:erbose}}display parsing progress{p_end}
{synoptline}

{pstd}
When using {opt dataset}, the following variables are created:
{p_end}
{phang2}{cmd:key} - Full key name (nested keys use underscore separator){p_end}
{phang2}{cmd:value} - Value as string{p_end}
{phang2}{cmd:level} - Nesting level (1 = root){p_end}
{phang2}{cmd:parent} - Parent key name{p_end}
{phang2}{cmd:type} - Value type (string, numeric, boolean, null, parent){p_end}


{marker write}{...}
{title:yaml write}

{p 8 17 2}
{cmd:yaml write}
{cmd:using} {it:filename}
[{cmd:,} {opt locals(namelist)} {opt scalars(namelist)} {opt d:ataset} {opt replace} {opt v:erbose}
{opt indent(#)} {opt header(string)}]

{pstd}
Writes Stata data to a YAML file.

{synoptset 20 tabbed}{...}
{synopthdr:options}
{synoptline}
{synopt:{opt locals(namelist)}}write specified local macros{p_end}
{synopt:{opt scalars(namelist)}}write specified scalars{p_end}
{synopt:{opt d:ataset}}write from current dataset (requires key/value vars){p_end}
{synopt:{opt replace}}replace existing file{p_end}
{synopt:{opt v:erbose}}display progress{p_end}
{synopt:{opt indent(#)}}spaces per indent level; default is 2{p_end}
{synopt:{opt header(string)}}custom header comment{p_end}
{synoptline}


{marker describe}{...}
{title:yaml describe}

{p 8 17 2}
{cmd:yaml describe}
[{cmd:,} {opt level(#)}]

{pstd}
Displays the structure of YAML data currently loaded as a dataset.

{synoptset 20 tabbed}{...}
{synopthdr:options}
{synoptline}
{synopt:{opt level(#)}}maximum nesting level to display; default is all{p_end}
{synoptline}


{marker list}{...}
{title:yaml list}

{p 8 17 2}
{cmd:yaml list}
[{it:parent}]
[{cmd:,} {opt keys} {opt values} {opt sep:arator(string)} {opt child:ren} {opt stata} {opt noh:eader}]

{pstd}
Lists keys and values from YAML data loaded as a dataset.
Optional {it:parent} filters to keys under that parent.

{synoptset 20 tabbed}{...}
{synopthdr:options}
{synoptline}
{synopt:{opt keys}}return matching keys as delimited list in r(keys){p_end}
{synopt:{opt values}}return matching values as delimited list in r(values){p_end}
{synopt:{opt sep:arator(string)}}delimiter for lists; default is space{p_end}
{synopt:{opt child:ren}}return only immediate children of parent{p_end}
{synopt:{opt stata}}format output as Stata compound quotes: {cmd:`"item1"' `"item2"'}{p_end}
{synopt:{opt noh:eader}}suppress column headers in listing{p_end}
{synoptline}


{marker clear}{...}
{title:yaml clear}

{p 8 17 2}
{cmd:yaml clear}

{pstd}
Clears YAML data from memory.


{marker examples}{...}
{title:Examples}

{pstd}
{bf:Example YAML file (config.yaml):}{p_end}

{phang2}{cmd:name: My Project}{p_end}
{phang2}{cmd:version: 1.0}{p_end}
{phang2}{cmd:settings:}{p_end}
{phang2}{cmd:  debug: true}{p_end}
{phang2}{cmd:  max_obs: 1000}{p_end}

{pstd}
{bf:Example 1: Read YAML into local macros}{p_end}

{phang2}{cmd:. yaml read using "config.yaml", locals}{p_end}
{phang2}{cmd:. display "`r(yaml_name)'"}{p_end}
{phang2}{res:My Project}{p_end}

{pstd}
{bf:Example 2: Read YAML into dataset}{p_end}

{phang2}{cmd:. yaml read using "config.yaml", dataset replace}{p_end}
{phang2}{cmd:. yaml describe}{p_end}

{pstd}
{bf:Example 3: Write locals to YAML}{p_end}

{phang2}{cmd:. local project "Analysis"}{p_end}
{phang2}{cmd:. local year 2025}{p_end}
{phang2}{cmd:. yaml write using "output.yaml", locals(project year) replace}{p_end}

{pstd}
{bf:Example 4: Write dataset to YAML}{p_end}

{phang2}{cmd:. yaml read using "config.yaml", dataset replace}{p_end}
{phang2}{cmd:. replace value = "2.0" if key == "version"}{p_end}
{phang2}{cmd:. yaml write using "config_new.yaml", dataset replace}{p_end}

{pstd}
{bf:Example 5: List specific keys}{p_end}

{phang2}{cmd:. yaml read using "config.yaml", dataset replace}{p_end}
{phang2}{cmd:. yaml list settings}{p_end}

{pstd}
{bf:Example 6: Get all indicator codes as a list}{p_end}

{phang2}{cmd:. yaml read using "indicators.yaml", dataset replace}{p_end}
{phang2}{cmd:. yaml list indicators, keys children}{p_end}
{phang2}{res:Keys under indicators: CME_MRY0T4 CME_MRY0 NT_ANT_HAZ_NE2}{p_end}
{phang2}{cmd:. return list}{p_end}
{phang2}{res:r(keys) : "CME_MRY0T4 CME_MRY0 NT_ANT_HAZ_NE2"}{p_end}

{pstd}
{bf:Example 7: Loop over indicator codes}{p_end}

{phang2}{cmd:. yaml list indicators, keys children}{p_end}
{phang2}{cmd:. foreach ind in `r(keys)' {c -(}}{p_end}
{phang2}{cmd:.     display "Processing indicator: `ind'"}{p_end}
{phang2}{cmd:. {c )-}}{p_end}


{marker results}{...}
{title:Stored results}

{pstd}
{cmd:yaml read} stores the following in {cmd:r()}:

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Scalars}{p_end}
{synopt:{cmd:r(n_keys)}}number of keys parsed{p_end}
{synopt:{cmd:r(max_level)}}maximum nesting depth{p_end}

{p2col 5 20 24 2: Macros}{p_end}
{synopt:{cmd:r(filename)}}name of file read{p_end}
{synopt:{cmd:r(yaml_*)}}values from YAML file (when {opt locals} specified){p_end}

{pstd}
{cmd:yaml list} stores the following in {cmd:r()} when {opt keys} or {opt values} specified:

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Macros}{p_end}
{synopt:{cmd:r(keys)}}delimited list of matching keys{p_end}
{synopt:{cmd:r(values)}}delimited list of matching values{p_end}
{synopt:{cmd:r(parent)}}parent key used for filtering{p_end}
{p2colreset}{...}


{marker limitations}{...}
{title:Limitations}

{pstd}
{cmd:yaml} handles common YAML structures but does not support:

{phang2}- Multi-line strings (block scalars){p_end}
{phang2}- Anchors and aliases (&anchor, *alias){p_end}
{phang2}- Complex keys{p_end}
{phang2}- Flow style ({c -(}key: value{c )-}){p_end}
{phang2}- Document markers (---){p_end}


{marker author}{...}
{title:Author}

{pstd}
Joao Pedro Azevedo{break}
UNICEF{break}
jpazevedo@unicef.org


{marker seealso}{...}
{title:Also see}

{psee}
{space 2}Help: {help infile}, {help import delimited}, {help file}
{p_end}
