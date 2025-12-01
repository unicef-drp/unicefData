#-------------------------------------------------------------------
# File: data_utilities.R
# Purpose: User-written functions for safer loading, saving, and logging
# Author: Joao Pedro Azevedo
# Updated: 12 June 2025
#-------------------------------------------------------------------
#
# This script provides reusable utility functions for robust data handling:
#
# • safe_read_csv():     Read CSV files with error handling and logging
# • safe_write_csv():    Save data frames to CSVs safely with row check
# • process_block():     Run code blocks with labeled logging and catch errors
# • %||%:                Null coalescing operator for default fallbacks
#
# These utilities help make scripts cleaner, safer, and easier to debug.
#-------------------------------------------------------------------


#--------------------------#
# Safe CSV Reader
#--------------------------#
safe_read_csv <- function(path, label = NULL, show_col_types = FALSE) {
  tryCatch({
    df <- readr::read_csv(path, show_col_types = show_col_types)
    cat("✅ Loaded:", label %||% basename(path), "-", nrow(df), "rows\n")
    return(df)
  }, error = function(e) {
    cat("❌ ERROR loading:", label %||% basename(path),
        "\n↪ Path:", path,
        "\n↪ Message:", conditionMessage(e), "\n")
    return(NULL)
  })
}

#--------------------------#
# Safe CSV Writer
#--------------------------#
safe_write_csv <- function(df, path, label = NULL) {
  tryCatch({
    if (!is.null(df) && nrow(df) > 0) {
      readr::write_csv(df, path, na = "")
      cat("💾 Saved:", label %||% basename(path), "-", nrow(df), "rows\n")
    } else {
      warning("⚠ Skipped saving:", label %||% basename(path), "- Data is empty or NULL")
    }
  }, error = function(e) {
    cat("❌ ERROR writing:", label %||% basename(path),
        "\n↪ Path:", path,
        "\n↪ Message:", conditionMessage(e), "\n")
  })
}

#--------------------------#
# Process Block Wrapper
#--------------------------#
process_block <- function(label, expr) {
  cat(paste0("\n--- ", label, " ---\n"))
  tryCatch({
    eval(expr)
  }, error = function(e) {
    cat("❌ ERROR in block:", label,
        "\n↪ Message:", conditionMessage(e), "\n")
  })
}



#-------------------------------------------------------------------------------
# 1) Safe helpers (base R + httr/vroom)
#-------------------------------------------------------------------------------
safe_read_csv_url <- function(url, name) {
  tryCatch({
    df <- readr::read_csv(url, show_col_types = FALSE)
    cat(sprintf("✅ SDMX: %-20s downloaded [%d rows]\n", name, nrow(df)))
    df
  }, error = function(e) {
    cat(sprintf("❌ ERROR downloading %s\n   ↪ URL: %s\n   ↪ %s\n", name, url, e$message))
    NULL
  })
}

safe_save_csv <- function(df, path, label) {
  if (is.null(df)) {
    cat(sprintf("⚠ Skipped saving %s: Data is NULL\n", label))
    return(invisible())
  }
  tryCatch({
    utils::write.csv(df, path, row.names = FALSE, na = "")
    cat(sprintf("✅ Saved: %-20s [%d rows, %d cols]\n",
                basename(path), nrow(df), ncol(df)))
  }, error = function(e) {
    cat(sprintf("❌ ERROR saving %s to %s:\n   ↪ %s\n",
                label, path, e$message))
  })
}


#--------------------------#
# Null coalescing operator
#--------------------------#
`%||%` <- function(a, b) if (!is.null(a)) a else b
