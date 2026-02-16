
library(unicefData)
tryCatch({
    df <- unicefData(
        indicator = "MG_RFGS_CNTRY_ASYLM_PER_USD_GNI",
        
        
    )
    
    if (nrow(df) > 0) {
        write.csv(df, "C:/GitHub/myados/unicefData/validation/results/indicator_validation_20260112_150126/r/success/MG_RFGS_CNTRY_ASYLM_PER_USD_GNI.csv", row.names = FALSE)
        cat(nrow(df))
    } else {
        cat("0")
    }
}, error = function(e) {
    writeLines(as.character(e$message), "C:/GitHub/myados/unicefData/validation/results/indicator_validation_20260112_150126/r/failed/MG_RFGS_CNTRY_ASYLM_PER_USD_GNI.error")
    cat("ERROR")
})
