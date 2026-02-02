
# Set library path for Windows
userLib <- file.path(Sys.getenv('USERPROFILE'), 'AppData', 'Local', 'R', 'win-library', '4.5')
if (file.exists(userLib)) {
    .libPaths(c(userLib, .libPaths()))
}

# Load local R package using devtools::load_all (loads all files in correct order)
# This uses the development version instead of installed package
if (requireNamespace("devtools", quietly = TRUE)) {
    devtools::load_all("C:/GitHub/myados/unicefData-dev/R", quiet = TRUE)
} else {
    # Fallback: source files in dependency order
    setwd("C:/GitHub/myados/unicefData-dev/R")
    source("globals.R")
    source("utils.R")
    source("config_loader.R")
    source("data_utilities.R")
    source("unicef_core.R")
    source("get_sdmx.R")
    source("flows.R")
    source("metadata.R")
    source("unicefData.R")
}

tryCatch({
    df <- unicefData(indicator = "ED_ANAR_L02", metadata = "light")

    if (nrow(df) > 0) {
        write.csv(df, "C:/GitHub/myados/unicefData-dev/validation/cache/r/ED_ANAR_L02.csv", row.names = FALSE, fileEncoding = "UTF-8")
        cat(paste0("SUCCESS:", nrow(df), ":", ncol(df)))
    } else {
        cat("NOT_FOUND:0:0")
    }
}, error = function(e) {
    cat(paste0("ERROR:", e$message))
})
