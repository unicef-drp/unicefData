unicefData: Stata module for accessing UNICEF SDMX indicators

Version: 2.0.4 (01Feb2026)

This package provides access to 733+ indicators from the UNICEF Data Warehouse
using the SDMX REST API, covering child health, nutrition, education, protection,
HIV/AIDS, WASH, and more.

MAIN FEATURES:
- Download data by indicator, geography, and time period
- Discovery tools: search, indicators, dataflows, info
- Multiple output formats: long, wide, wide_indicators
- Automatic dataflow detection from indicator codes
- Geographic type classification (country vs aggregate)
- YAML-based metadata with sync capabilities
- Stata 16+ frames support for better isolation

REQUIREMENTS:
- Stata 14.0+ (Stata 16+ recommended for frames support)
- yaml.ado package (included)

INSTALLATION:

From SSC Archive:
  ssc install unicefdata, replace

From GitHub:
  net install unicefdata, from(https://raw.githubusercontent.com/unicef-drp/unicefData/main/stata/ssc) replace

Quick setup (creates metadata cache):
  unicefdata_setup

EXAMPLE USAGE:

  * Download child mortality data for all countries
  unicefdata, indicator(CME_MRY0T4) clear
  
  * Search for nutrition indicators
  unicefdata, search(nutrition)
  
  * Get latest values by sex disaggregation
  unicefdata, indicator(NT_ANT_HAZ_NE2) sex(F M) latest clear
  
  * See all available dataflows
  unicefdata, flows

DOCUMENTATION:
  help unicefdata
  help unicefdata_sync
  help unicefdata_setup
  help unicefdata_examples
  help unicefdata_xmltoyaml
  help unicefdata_xmltoyaml_py
  unicefdata, whatsnew

AUTHOR:
  João Pedro Azevedo (UNICEF)
  Contact: https://jpazvd.github.io

LICENSE:
  MIT License

For complete documentation and examples, visit:
https://github.com/unicef-drp/unicefData