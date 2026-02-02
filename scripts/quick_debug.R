#!/usr/bin/env Rscript
# Quick debug test for fallback sequences

cat("=== Debugging fallback_sequences issue ===\n\n")

# 1. Check working directory
cat("Working directory:", getwd(), "\n\n")

# 2. Check YAML file exists
yaml_file <- "metadata/current/_dataflow_fallback_sequences.yaml"
cat("YAML file exists:", file.exists(yaml_file), "\n")
if (file.exists(yaml_file)) {
  cat("YAML path:", normalizePath(yaml_file), "\n\n")
}

# 3. Try loading package
cat("Loading package with devtools...\n")
if (!requireNamespace("devtools", quietly = TRUE)) {
  stop("devtools not installed")
}

devtools::load_all(".", export_all = FALSE, quiet = FALSE)

# 4. List all internal functions with "fallback" in the name
cat("\nInternal functions containing 'fallback':\n")
ns <- getNamespace("unicefData")
all_objs <- ls(ns, all.names = TRUE)
fallback_objs <- grep("fallback", all_objs, value = TRUE, ignore.case = TRUE)
print(fallback_objs)

# 5. Try both function names
cat("\n--- Testing .get_fallback_sequences() ---\n")
tryCatch({
  result <- unicefData:::.get_fallback_sequences()
  cat("SUCCESS: Function found and returned:\n")
  print(str(result))
}, error = function(e) {
  cat("ERROR:", e$message, "\n")
})

cat("\n--- Testing .load_fallback_sequences() ---\n")
tryCatch({
  result <- unicefData:::.load_fallback_sequences()
  cat("SUCCESS: Function found and returned:\n")
  print(str(result))
}, error = function(e) {
  cat("ERROR:", e$message, "\n")
})

cat("\n=== Debug complete ===\n")
