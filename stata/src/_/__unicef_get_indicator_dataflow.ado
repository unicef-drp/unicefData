*! version 0.2.0  01Feb2026
*! __unicef_get_indicator_dataflow -- Look up dataflow(s) for an indicator
program define __unicef_get_indicator_dataflow, rclass

  version 11
  syntax, indicator(string) [verbose]
  
  // Locate indicator-dataflow mapping
  // Primary: installed ado/plus directory
  local plus_dir "`c(sysdir_plus)'"
  local mapping_file "`plus_dir'_/_indicator_dataflow_map.yaml"

  // Fallback: try alternative locations
  capture confirm file "`mapping_file'"
  if _rc != 0 {
    * Try development/project paths as fallback
    local candidate_paths ///
        "`plus_dir'_\_indicator_dataflow_map.yaml" ///
        "_indicator_dataflow_map.yaml" ///
        "stata/src/_/_indicator_dataflow_map.yaml" ///
        "src/_/_indicator_dataflow_map.yaml"

    foreach path of local candidate_paths {
      capture confirm file "`path'"
      if !_rc {
        local mapping_file "`path'"
        continue, break
      }
    }
  }

  // Validate file exists
  capture confirm file "`mapping_file'"
  if _rc != 0 {
    display as error "Error: Indicator mapping file not found"
    display as error "Searched in: `plus_dir'_/"
    error 601
  }
  
  // Parse mapping YAML to find indicator
  local found_indicator = 0
  local dataflow = ""
  local dataflows = ""
  
  tempname fh
  file open `fh' using "`mapping_file'", read
  
  local in_mapping = 0
  file read `fh' line
  while `"`macval(line)'"' != "" {
    // Enter the indicator_to_dataflow section
    if regexm(`"`macval(line)'"', "^indicator_to_dataflow:") {
      local in_mapping = 1
      file read `fh' line
      continue
    }
    
    // Exit mapping section when we hit next top-level key (like "dataflow_to_indicators:")
    if local in_mapping && regexm(`"`macval(line)'"', "^[a-z_]+:") {
      break
    }
    
    // Look for indicator inside mapping
    if local in_mapping && regexm(`"`macval(line)'"', "^  `indicator':") {
      local found_indicator = 1
      
      // Check what follows the colon
      if regexm(`"`macval(line)'"', "^  `indicator': (.+)") {
        // Single value on same line: "  INDICATOR: DATAFLOW"
        local dataflows = regexs(1)
        local dataflows = strtrim("`dataflows'")
      }
      else {
        // Multi-value list format:
        // "  INDICATOR:"
        // "    - DATAFLOW1"
        // "    - DATAFLOW2"
        file read `fh' line
        while regexm(`"`macval(line)'"', "^    - (.+)") {
          local df = regexs(1)
          local df = strtrim("`df'")
          local dataflows = "`dataflows' `df'"
          file read `fh' line
        }
      }
      
      break
    }
    
    file read `fh' line
  }
  
  file close `fh'
  
  if !`found_indicator' {
    display as error "Error: Indicator '`indicator'' not found in mapping"
    error 111
  }
  
  // Clean up dataflows list
  local dataflows = strtrim("`dataflows'")
  local primary_dataflow = word("`dataflows'", 1)
  
  // Return results
  return local indicator "`indicator'"
  return local dataflow "`primary_dataflow'"
  return local all_dataflows "`dataflows'"
  return local dataflow_count = wordcount("`dataflows'")
  
  if "`verbose'" != "" {
    display "  Indicator: `indicator'"
    display "  Primary dataflow: `primary_dataflow'"
    if `r(dataflow_count)' > 1 {
      display "  All dataflows: `dataflows'"
    }
  }

end
