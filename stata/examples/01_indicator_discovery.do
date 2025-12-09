/*******************************************************************************
* 01_indicator_discovery.do - Discover Available Indicators
* ==========================================================
*
* Demonstrates how to search and discover UNICEF indicators.
* Matches: R/examples/01_indicator_discovery.R
*          python/examples/01_indicator_discovery.py
*
* Examples:
*   1. List all dataflows (categories)
*   2. Search by keyword (via metadata)
*   3. Browse indicator registry
*   4. Auto-detect dataflow for indicator
*   5. List available indicators in a dataflow
*
* Note: Stata uses YAML metadata files for indicator discovery.
*       Use unicefdata_sync to update local metadata.
*******************************************************************************/

clear all
set more off

display _n "======================================================================"
display "01_indicator_discovery.do - Discover UNICEF Indicators"
display "======================================================================"

* =============================================================================
* Example 1: List Available Dataflows
* =============================================================================
display _n "--- Example 1: List Available Dataflows ---" _n

* The dataflows are stored in metadata/current/dataflows/
* Common dataflows include:
display "Available dataflows (thematic areas):"
display "  CME        - Child Mortality Estimates"
display "  NUTRITION  - Nutrition indicators"
display "  IMMUNISATION - Immunization coverage"
display "  EDUCATION  - Education indicators"
display "  WASH       - Water, Sanitation, Hygiene"
display "  HIV_AIDS   - HIV/AIDS indicators"
display "  PT         - Child Protection"
display "  ECD        - Early Childhood Development"
display "  GLOBAL_DATAFLOW - Cross-cutting indicators"

* =============================================================================
* Example 2: Browse Local Indicator Registry
* =============================================================================
display _n "--- Example 2: Browse Indicator Registry ---" _n

* View indicator registry (requires metadata sync)
display "To view available indicators, check metadata/current/indicators/"
display "Or use: yaml get indicator_registry.yaml"

* =============================================================================
* Example 3: Get Data with Auto-detect Dataflow
* =============================================================================
display _n "--- Example 3: Auto-detect Dataflow ---" _n
display "unicefdata automatically detects the correct dataflow from indicator code"

* The indicator code is enough - dataflow is auto-detected
display _n "Example: CME_MRY0T4 -> dataflow CME (Child Mortality)"
unicefdata, indicator(CME_MRY0T4) countries(ALB) clear verbose

display _n "Example: NT_ANT_WHZ_NE2 -> dataflow NUTRITION"
unicefdata, indicator(NT_ANT_WHZ_NE2) countries(ETH) clear verbose

* =============================================================================
* Example 4: Get All Indicators from a Dataflow
* =============================================================================
display _n "--- Example 4: Get All Indicators from Dataflow ---" _n
display "Download all indicators from a dataflow for specific country"

unicefdata, dataflow(CME) countries(BRA) start_year(2020) clear

display "Indicators in CME dataflow:"
tab indicator

* =============================================================================
* Example 5: Validate Against Codelists
* =============================================================================
display _n "--- Example 5: Validate Inputs ---" _n
display "Use 'validate' option to check inputs against local metadata"

* This validates country codes and indicator codes
unicefdata, indicator(CME_MRY0T4) countries(ALB USA) validate clear

display _n "======================================================================"
display "Indicator Discovery Complete!"
display "======================================================================"
