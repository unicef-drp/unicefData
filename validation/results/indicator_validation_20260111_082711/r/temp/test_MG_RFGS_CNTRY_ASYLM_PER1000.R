
library(unicefData)
tryCatch({
    df <- unicefData(
        indicator = "MG_RFGS_CNTRY_ASYLM_PER1000",
        
        
    )
    
    if (nrow(df) > 0) {
        write.csv(df, "C:/GitHub/myados/unicefData/validation/results/indicator_validation_20260111_082711/r/success/MG_RFGS_CNTRY_ASYLM_PER1000.csv", row.names = FALSE)
        cat(nrow(df))
    } else {
        cat("0")
    }
}, error = function(e) {
    writeLines(as.character(e$message), "C:/GitHub/myados/unicefData/validation/results/indicator_validation_20260111_082711/r/failed/MG_RFGS_CNTRY_ASYLM_PER1000.error")
    cat("ERROR")
})
