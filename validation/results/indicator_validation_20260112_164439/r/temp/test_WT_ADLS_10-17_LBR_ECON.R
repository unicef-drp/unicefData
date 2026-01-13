
library(unicefData)
tryCatch({
    df <- unicefData(
        indicator = "WT_ADLS_10-17_LBR_ECON",
        
        
    )
    
    if (nrow(df) > 0) {
        write.csv(df, "C:/GitHub/myados/unicefData/validation/results/indicator_validation_20260112_164439/r/success/WT_ADLS_10-17_LBR_ECON.csv", row.names = FALSE)
        cat(nrow(df))
    } else {
        cat("0")
    }
}, error = function(e) {
    writeLines(as.character(e$message), "C:/GitHub/myados/unicefData/validation/results/indicator_validation_20260112_164439/r/failed/WT_ADLS_10-17_LBR_ECON.error")
    cat("ERROR")
})
