
# Set library path for Windows
userLib <- file.path(Sys.getenv('USERPROFILE'), 'AppData', 'Local', 'R', 'win-library', '4.5')
if (file.exists(userLib)) {
    .libPaths(c(userLib, .libPaths()))
}

library(unicefData)
tryCatch({
    df <- unicefData(indicator = "NT_ANT_HAZ_NE2", metadata = "light")

    if (nrow(df) > 0) {
        write.csv(df, "C:/GitHub/myados/unicefData-dev/validation/cache/r/NT_ANT_HAZ_NE2.csv", row.names = FALSE, fileEncoding = "UTF-8")
        cat(paste0("SUCCESS:", nrow(df), ":", ncol(df)))
    } else {
        cat("NOT_FOUND:0:0")
    }
}, error = function(e) {
    cat(paste0("ERROR:", e$message))
})
