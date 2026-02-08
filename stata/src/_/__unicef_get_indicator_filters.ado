*! version 0.5.0  18Jan2026
program define __unicef_get_indicator_filters, rclass
* Description: Read dataflow schema to extract dimension information
* Calculates filter-eligible dimensions (excludes REF_AREA, INDICATOR, TIME_PERIOD, UNIT_MEASURE)
* v0.5.0: Also exclude UNIT_MEASURE (technical field, not user disaggregation)
* v0.4.0: Fixed to only read dimensions section, not attributes section
* Author: João Pedro Azevedo (https://jpazvd.github.io)
* License: MIT

  version 11
  
  syntax, DATAflow(string) [VERbose]
  
  // Locate dataflow schema using multi-tier resolution
  // FIRST: Try user ado directory (PLUS)
  local meta_base "`c(sysdir_plus)'_"
  local dataflow_schema "`meta_base'dataflows/`dataflow'.yaml"

  // SECOND: Try findfile for adopath resolution (dev mode)
  capture confirm file "`dataflow_schema'"
  if _rc != 0 {
    capture findfile "_dataflows/`dataflow'.yaml"
    if _rc == 0 {
      local dataflow_schema "`r(fn)'"
    }
  }

  // THIRD: Try current working directory
  capture confirm file "`dataflow_schema'"
  if _rc != 0 {
    local dataflow_schema "`c(pwd)'/_dataflows/`dataflow'.yaml"
  }
  
  // Validate dataflow schema exists
  capture confirm file "`dataflow_schema'"
  if _rc != 0 {
    display as error "Error: Dataflow schema not found: `dataflow_schema'"
    error 601
  }
  
  if "`verbose'" != "" {
    display "  Dataflow: `dataflow'"
    display "  Schema: `dataflow_schema'"
  }
  
  // Extract dimensions from dataflow schema, using embedded positions if available
  local num_dimensions = 0
  local num_filter_dimensions = 0
  local all_dimensions ""
  local filter_eligible_dimensions ""
  local ref_area_pos = 0
  local indicator_pos = 0
  local time_period_pos = 0
  local in_dimensions_section = 0
  
  tempname fh
  file open `fh' using "`dataflow_schema'", read
  
  file read `fh' line
  while `"`macval(line)'"' != "" {
    // Check for section headers (dimensions: vs attributes:)
    if regexm(`"`macval(line)'"', "^dimensions:") {
      local in_dimensions_section = 1
      file read `fh' line
      continue
    }
    
    // Exit if we hit attributes: or other top-level keys (not indented)
    if regexm(`"`macval(line)'"', "^[a-z_]+:") & !regexm(`"`macval(line)'"', "^  ") {
      local in_dimensions_section = 0
    }
    
    // Only process lines when in dimensions section
    if `in_dimensions_section' == 0 {
      file read `fh' line
      continue
    }
    
    // Look for dimension lines with id and position
    // Format: "- id: REF_AREA" or "- id: REF_AREA" with "  position: 1"
    if regexm(`"`macval(line)'"', "- id: ([A-Z_]+)") {
      local dim_id = regexs(1)
      local pos_found = 0
      local next_is_dimension = 0
      
      // Try to find position on same or next lines
      file read `fh' line
      while `"`macval(line)'"' != "" & `pos_found' == 0 & `next_is_dimension' == 0 {
        if regexm(`"`macval(line)'"', "position: ([0-9]+)") {
          local pos_num = real(regexs(1))
          local pos_found = 1
          file read `fh' line
        }
        else if regexm(`"`macval(line)'"', "^- id:") {
          // Hit next dimension; set flag to process it in next iteration
          local next_is_dimension = 1
        }
        else {
          file read `fh' line
        }
      }
      
      // If no position found, use sequential
      if `pos_found' == 0 {
        local ++num_dimensions
        local pos_num = `num_dimensions'
      }
      else {
        local num_dimensions = max(`num_dimensions', `pos_num')
      }
      
      local dimension_`pos_num' = "`dim_id'"
      local all_dimensions = "`all_dimensions' `dim_id'"
      
      // Track positions of fixed dimensions
      if "`dim_id'" == "REF_AREA" local ref_area_pos = `pos_num'
      if "`dim_id'" == "INDICATOR" local indicator_pos = `pos_num'
      if "`dim_id'" == "TIME_PERIOD" local time_period_pos = `pos_num'
      
      // Check if this dimension is filter-eligible
      // Exclude: REF_AREA (country), INDICATOR (fixed), TIME_PERIOD (year), UNIT_MEASURE (technical)
      if !inlist("`dim_id'", "REF_AREA", "INDICATOR", "TIME_PERIOD", "UNIT_MEASURE") {
        local ++num_filter_dimensions
        local filter_eligible_dimensions = "`filter_eligible_dimensions' `dim_id'"
      }
      
      if "`verbose'" != "" {
        if inlist("`dim_id'", "REF_AREA", "INDICATOR", "TIME_PERIOD", "UNIT_MEASURE") {
          display "  Dimension `pos_num': `dim_id' (fixed)"
        }
        else {
          display "  Dimension `pos_num': `dim_id' (filterable)"
        }
      }
      
      // If we hit another dimension line in the inner loop, outer loop uses it
      if `next_is_dimension' == 0 & `"`macval(line)'"' == "" {
        // Reached EOF, normal exit
      }
    }
    else {
      file read `fh' line
    }
  }
  file close `fh'
  
  // Return results including dimension positions
  return local dataflow "`dataflow'"
  return local dimensions "`all_dimensions'"
  return scalar num_dimensions = `num_dimensions'
  return scalar filter_dimensions = `num_filter_dimensions'
  return scalar ref_area_position = `ref_area_pos'
  return scalar indicator_position = `indicator_pos'
  return local filter_eligible_dimensions "`filter_eligible_dimensions'"
  
  forvalues i = 1/`num_dimensions' {
    return local dimension_`i' "`dimension_`i''"
  }
  
  // Default filter for UNICEF data (most common case)
  // Only generate defaults for filter-eligible dimensions
  local default_filter_tokens ""
  forvalues i = 1/`num_filter_dimensions' {
    local default_filter_tokens "`default_filter_tokens' _T"
  }
  return local default_filter "`default_filter_tokens'"
  return local full_filter "nofilter"
  
  if "`verbose'" != "" {
    display ""
    display "Results:"
    display "  Dataflow: `dataflow'"
    display "  Total dimensions: `num_dimensions'"
    display "  REF_AREA position: `ref_area_pos'"
    display "  INDICATOR position: `indicator_pos'"
    display "  Filter-eligible dimensions: `num_filter_dimensions'"
    display "  Filter-eligible: `filter_eligible_dimensions'"
  }

end
