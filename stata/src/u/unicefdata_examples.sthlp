{smcl}
{* *! version 1.8.0  18Feb2026}{...}
{vieweralsosee "[D] unicefdata" "help unicefdata"}{...}
{vieweralsosee "[D] get_sdmx" "help get_sdmx"}{...}
{viewerjumpto "Syntax" "unicefdata_examples##syntax"}{...}
{viewerjumpto "Interactive Examples" "unicefdata_examples##interactive"}{...}
{viewerjumpto "Quick Examples" "unicefdata_examples##examples"}{...}
{viewerjumpto "Cookbook" "unicefdata_examples##cookbook"}{...}
{title:unicefdata_examples — Gallery of unicefdata usage examples}

{marker syntax}{...}
{title:Syntax}

{p 8 16 2}
{cmd:unicefdata_examples} {it:example_name} [{cmd:,} {opt v:erbose}]

{synoptset 20 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{it:example_name}}Name of example to run: {cmd:example01} through {cmd:example12}{p_end}
{synopt:{opt v:erbose}}Enable step-by-step debugging output{p_end}
{synoptline}

{marker interactive}{...}
{title:Interactive Multi-Step Examples}

{p 4 4 2}
These examples demonstrate complete analytical workflows. Run them with {cmd:verbose}
to see each step executed:
{p_end}

{p 8 12 2}
{cmd:. unicefdata_examples example02, verbose}
{p_end}

{dlgtab:Available Examples}

{p 4 8 2}
{cmd:example01} — Under-5 mortality trend analysis for South Asia{p_end}
{p 8 8 2}Downloads CME_MRY0T4, filters to totals, creates trend graph for 4 countries.{p_end}

{p 4 8 2}
{cmd:example02} — Stunting by wealth quintile{p_end}
{p 8 8 2}Uses {cmd:nofilter} to get all data, filters to Q1-Q5, creates bar chart.{p_end}

{p 4 8 2}
{cmd:example03} — Multiple mortality indicators comparison{p_end}
{p 8 8 2}Downloads 3 CME indicators for Latin America, reshapes wide, creates grouped bar chart.{p_end}

{p 4 8 2}
{cmd:example04} — Immunization coverage trends{p_end}
{p 8 8 2}Downloads DTP3 and MCV1, calculates global averages, creates trend graph.{p_end}

{p 4 8 2}
{cmd:example05} — Regional comparison with metadata{p_end}
{p 8 8 2}Uses {cmd:addmeta(region)} option, aggregates by UNICEF region, creates horizontal bar chart.{p_end}

{p 4 8 2}
{cmd:example06} — Export to Excel{p_end}
{p 8 8 2}Downloads data with metadata, selects columns, exports to Excel file.{p_end}

{p 4 8 2}
{cmd:example07} — WASH urban-rural gap analysis{p_end}
{p 8 8 2}Uses {cmd:residence(ALL)}, calculates urban-rural gap, lists top 10 countries.{p_end}

{p 4 8 2}
{cmd:example08} — Wide format time series{p_end}
{p 8 8 2}Uses {cmd:wide} option to create yr#### columns, calculates percent change.{p_end}

{p 4 8 2}
{cmd:example09} — Multiple indicators as columns{p_end}
{p 8 8 2}Uses {cmd:wide_indicators} option to create indicator columns, calculates correlations.{p_end}

{p 4 8 2}
{cmd:example10} — Sex disaggregation analysis{p_end}
{p 8 8 2}Uses {cmd:sex(ALL)}, reshapes to wide, calculates male-female mortality gap.{p_end}

{p 4 8 2}
{cmd:example11} — Wealth equity gap analysis{p_end}
{p 8 8 2}Uses {cmd:wealth(ALL)}, reshapes to wide, calculates Q1-Q5 stunting gap.{p_end}

{p 4 8 2}
{cmd:example12} — Discovery caching performance (Stata 16+){p_end}
{p 8 8 2}Runs {cmd:search()} twice to demonstrate frame-based caching speedup. Uses {cmd:nocache} to force re-parse.{p_end}

{dlgtab:Verbose Option}

{p 4 4 2}
The {cmd:verbose} option shows detailed debugging information:{p_end}

{p 8 12 2}• Each command before execution{p_end}
{p 8 12 2}• Data state after each step (observations, variables){p_end}
{p 8 12 2}• Key variable values (wealth_quintile, sex, residence){p_end}

{p 4 4 2}
Use verbose mode to understand workflows or debug issues:
{p_end}

{p 8 12 2}
{cmd:. unicefdata_examples example02, verbose}
{p_end}

{marker examples}{...}
{title:Quick Examples}

{p 4 4 2}
{bf:Example 1: Simple single-indicator download}
{p_end}

{p 8 12 2}
{cmd:. unicefdata, indicator(CME_MRY0T4) clear}
{p_end}

{p 12 12 2}
Downloads under-5 mortality rate for all countries and years available.

{p 4 4 2}
{bf:Example 2: Multiple indicators}
{p_end}

{p 8 12 2}
{cmd:. unicefdata, indicator(CME_MRY0T4 CME_MRY0 CME_MRM0) countries(IND PAK BGD) clear}
{p_end}

{p 12 12 2}
Fetches three mortality indicators (under-5, infant, neonatal) for three countries.

{p 4 4 2}
{bf:Example 3: No default filters (get ALL data)}
{p_end}

{p 8 12 2}
{cmd:. unicefdata, indicator(NT_ANT_HAZ_NE2) nofilter clear}
{p_end}

{p 12 12 2}
Downloads all disaggregations without any default filters. Filter in Stata afterward.

{p 4 4 2}
{bf:Example 4: Wide format for easy analysis}
{p_end}

{p 8 12 2}
{cmd:. unicefdata, indicator(CME_MRY0T4 CME_MRY0) wide_indicators clear}
{p_end}

{p 12 12 2}
Reshapes to wide format with separate columns for each indicator.

{p 4 4 2}
{bf:Example 5: Disaggregated data with filters}
{p_end}

{p 8 12 2}
{cmd:. unicefdata, indicator(NT_ANT_HAZ_NE2) wealth(Q1) clear}
{p_end}

{p 12 12 2}
Downloads stunting data filtered to poorest quintile (Q1).

{p 4 4 2}
{bf:Example 6: Latest available data only}
{p_end}

{p 8 12 2}
{cmd:. unicefdata, indicator(IM_DTP3) latest clear}
{p_end}

{p 12 12 2}
Fetches only the most recent DTP3 immunization data for each country.

{p 4 4 2}
{bf:Example 7: Detailed progress output}
{p_end}

{p 8 12 2}
{cmd:. unicefdata, indicator(CME_MRY0T4) verbose clear}
{p_end}

{p 12 12 2}
Shows all API calls and detailed metadata.

{marker cookbook}{...}
{title:Cookbook}

{p 4 4 2}
{bf:Task: Compare mortality across countries}
{p_end}

{p 8 12 2}
{cmd:. unicefdata, indicator(CME_MRY0T4) countries(SWE USA ZAF) clear}
{p_end}

{p 8 12 2}
{cmd:. keep if sex == "_T"}
{p_end}

{p 8 12 2}
{cmd:. twoway line value period, by(country)}
{p_end}

{p 4 4 2}
{bf:Task: Wealth equity analysis}
{p_end}

{p 8 12 2}
{cmd:. unicefdata, indicator(NT_ANT_HAZ_NE2) nofilter clear}
{p_end}

{p 8 12 2}
{cmd:. keep if period > 2020}
{p_end}

{p 8 12 2}
{cmd:. keep if inlist(wealth_quintile, "Q1", "Q5")}
{p_end}

{p 8 12 2}
{cmd:. collapse (mean) stunting = value, by(wealth_quintile)}
{p_end}

{p 4 4 2}
{bf:Task: Search for available indicators}
{p_end}

{p 8 12 2}
{cmd:. unicefdata, search(stunting)}
{p_end}

{p 4 4 2}
{bf:Task: Create a merge-ready dataset}
{p_end}

{p 8 12 2}
{cmd:. unicefdata, indicator(CME_MRY0T4) latest clear}
{p_end}

{p 8 12 2}
{cmd:. keep iso3 period value}
{p_end}

{p 8 12 2}
{cmd:. save mortality_data.dta, replace}
{p_end}

{p 8 12 2}
{cmd:. merge 1:1 iso3 using mydata.dta}
{p_end}

{p 4 4 2}
{bf:Task: Specify dataflow explicitly}
{p_end}

{p 8 12 2}
{cmd:. unicefdata, indicator(NT_ANT_HAZ_NE2) dataflow(NUTRITION) clear}
{p_end}

{p 12 12 2}
Bypass auto-detection for known dataflow (faster for batch operations).

{title:Tips and Tricks}

{p 4 4 2}
{hline}
{it:Filtering}
{hline}
{p_end}

{p 4 4 2}
• Use {cmd:nofilter} to download all disaggregations, then filter in Stata{p_end}

{p 4 4 2}
• Use {cmd:wealth(ALL)}, {cmd:sex(ALL)}, {cmd:residence(ALL)} for specific dimensions{p_end}

{p 4 4 2}
• Use {cmd:latest} option to get only the most recent data point per country{p_end}

{p 4 4 2}
{hline}
{it:Discovery}
{hline}
{p_end}

{p 4 4 2}
• Use {cmd:unicefdata, flows} to list available dataflows{p_end}

{p 4 4 2}
• Use {cmd:unicefdata, search(keyword)} to find indicators{p_end}

{p 4 4 2}
• Use {cmd:unicefdata, info(indicator_code)} to see metadata{p_end}

{p 4 4 2}
• Stata 16+: search results are cached in memory; repeat searches are near-instant{p_end}

{p 4 4 2}
• Use {cmd:nocache} to force re-parsing (e.g., after manual YAML edits){p_end}

{p 4 4 2}
• Use {cmd:unicefdata, clearcache} to drop all cached frames{p_end}

{p 4 4 2}
{hline}
{it:Debugging}
{hline}
{p_end}

{p 4 4 2}
• Use {cmd:verbose} during development to see API calls{p_end}

{p 4 4 2}
• Use {cmd:unicefdata_examples example##, verbose} to trace multi-step workflows{p_end}

{title:Common Issues}

{p 4 4 2}
{bf:Q: "No observations returned"}
{p_end}

{p 8 12 2}
A: Check indicator code and country codes (use ISO3). Use {cmd:verbose} to see API URL.{p_end}

{p 4 4 2}
{bf:Q: "Disaggregation not supported" warning}
{p_end}

{p 8 12 2}
A: Not all indicators support all disaggregations. Use {cmd:unicefdata, info(indicator)} to see available filters.{p_end}

{p 4 4 2}
{bf:Q: "Variable not found" error}
{p_end}

{p 8 12 2}
A: Variable names depend on the dataflow. Use {cmd:describe} after download to see actual column names.{p_end}

{p 4 4 2}
{bf:Q: Default filters removing data I need}
{p_end}

{p 8 12 2}
A: Use {cmd:nofilter} option to download all data, then filter manually in Stata.{p_end}

{title:Author}

{p}
Joao Pedro Azevedo, UNICEF{break}
https://jpazvd.github.io{break}
}

{title:See also}

{p}
{help unicefdata} (main command){break}
{help get_sdmx} (low-level fetching){break}
{help unicefdata_sync} (metadata synchronization)
{p_end}
