
library(unicefData)
tryCatch({
    df <- unicefData(
        indicator = "HVA_PMTCT_TEST_CVG",
        
        
    )
    
    if (nrow(df) > 0) {
        write.csv(df, "C:/GitHub/myados/unicefData/validation/results/indicator_validation_20260111_082711/r/success/HVA_PMTCT_TEST_CVG.csv", row.names = FALSE)
        cat(nrow(df))
    } else {
        cat("0")
    }
}, error = function(e) {
    writeLines(as.character(e$message), "C:/GitHub/myados/unicefData/validation/results/indicator_validation_20260111_082711/r/failed/HVA_PMTCT_TEST_CVG.error")
    cat("ERROR")
})
