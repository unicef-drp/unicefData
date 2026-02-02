#!/usr/bin/env Rscript
# Regenerate documentation for the package

library(devtools)
setwd("C:\\GitHub\\myados\\unicefData-dev")

# Try to document the package
tryCatch({
  cat("[1/3] Documenting package...\n")
  document()
  cat("[SUCCESS] Documentation regenerated\n")
}, error = function(e) {
  cat(sprintf("[ERROR] Documentation failed: %s\n", e$message))
})

# Now reload and test
cat("\n[2/3] Loading package with new code...\n")
tryCatch({
  # Clear any cached package
  if ("unicefData" %in% loadedNamespaces()) {
    detach("package:unicefData", unload = TRUE)
  }
  
  # Rebuild the package in memory
  load_all("C:\\GitHub\\myados\\unicefData-dev", export_all = FALSE)
  cat("[SUCCESS] Package loaded\n")
}, error = function(e) {
  cat(sprintf("[ERROR] Loading failed: %s\n", e$message))
})

# Test the lazy-loading function
cat("\n[3/3] Testing lazy-loading fallback sequences...\n")
tryCatch({
  fallback <- unicefData:::.get_fallback_sequences()
  
  if (is.null(fallback)) {
    cat("[ERROR] Fallback sequences is NULL!\n")
  } else {
    cat(sprintf("[SUCCESS] Loaded fallback sequences with %d prefixes\n", length(fallback)))
    cat(sprintf("[DEBUG] First 15 prefixes: %s\n", paste(head(names(fallback), 15), collapse=", ")))
    
    if ("IM" %in% names(fallback)) {
      cat("[SUCCESS] IM prefix found in fallback sequences\n")
    } else {
      cat("[ERROR] IM prefix NOT found!\n")
    }
  }
}, error = function(e) {
  cat(sprintf("[ERROR] Testing failed: %s\n", e$message))
})
