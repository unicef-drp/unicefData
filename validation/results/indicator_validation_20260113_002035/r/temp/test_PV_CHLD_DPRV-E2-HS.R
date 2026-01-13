
library(unicefData)
tryCatch({
    df <- unicefData(
        indicator = "PV_CHLD_DPRV-E2-HS",
        
        
    )
    
    if (nrow(df) > 0) {
        write.csv(df, "C:/GitHub/myados/unicefData/validation/results/indicator_validation_20260113_002035/r/success/PV_CHLD_DPRV-E2-HS.csv", row.names = FALSE)
        cat(nrow(df))
    } else {
        cat("0")
    }
}, error = function(e) {
    writeLines(as.character(e$message), "C:/GitHub/myados/unicefData/validation/results/indicator_validation_20260113_002035/r/failed/PV_CHLD_DPRV-E2-HS.error")
    cat("ERROR")
})
