# lightweight aliases used by legacy R test scripts

# Provide list_dataflows() expected by tests
list_dataflows <- function(...) {
  if (exists("list_unicef_flows", mode = "function")) {
    return(list_unicef_flows(...))
  }
  if (exists("list_sdmx_flows", mode = "function")) {
    return(list_sdmx_flows(agency = "UNICEF", ...))
  }
  stop("No flow-listing function available")
}
