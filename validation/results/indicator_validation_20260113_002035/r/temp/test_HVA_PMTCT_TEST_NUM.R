
library(unicefData)
tryCatch({
    df <- unicefData(
        indicator = "HVA_PMTCT_TEST_NUM",
        
        
    )
    
    if (nrow(df) > 0) {
        write.csv(df, "C:/GitHub/myados/unicefData/validation/results/indicator_validation_20260113_002035/r/success/HVA_PMTCT_TEST_NUM.csv", row.names = FALSE)
        cat(nrow(df))
    } else {
        cat("0")
    }
}, error = function(e) {
    writeLines(as.character(e$message), "C:/GitHub/myados/unicefData/validation/results/indicator_validation_20260113_002035/r/failed/HVA_PMTCT_TEST_NUM.error")
    cat("ERROR")
})
