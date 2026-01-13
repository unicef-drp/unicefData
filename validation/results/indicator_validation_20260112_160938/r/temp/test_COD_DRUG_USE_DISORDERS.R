
library(unicefData)
tryCatch({
    df <- unicefData(
        indicator = "COD_DRUG_USE_DISORDERS",
        
        
    )
    
    if (nrow(df) > 0) {
        write.csv(df, "C:/GitHub/myados/unicefData/validation/results/indicator_validation_20260112_160938/r/success/COD_DRUG_USE_DISORDERS.csv", row.names = FALSE)
        cat(nrow(df))
    } else {
        cat("0")
    }
}, error = function(e) {
    writeLines(as.character(e$message), "C:/GitHub/myados/unicefData/validation/results/indicator_validation_20260112_160938/r/failed/COD_DRUG_USE_DISORDERS.error")
    cat("ERROR")
})
