
library(unicefData)
tryCatch({
    df <- unicefData(
        indicator = "CME_ARR_SBR",
        
        
    )
    
    if (nrow(df) > 0) {
        write.csv(df, "C:/GitHub/myados/unicefData/validation/results/indicator_validation_20260112_131319/r/success/CME_ARR_SBR.csv", row.names = FALSE)
        cat(nrow(df))
    } else {
        cat("0")
    }
}, error = function(e) {
    writeLines(as.character(e$message), "C:/GitHub/myados/unicefData/validation/results/indicator_validation_20260112_131319/r/failed/CME_ARR_SBR.error")
    cat("ERROR")
})
