
library(unicefData)
tryCatch({
    df <- unicefData(
        indicator = "MNCH_MLRCARE",
        
        
    )
    
    if (nrow(df) > 0) {
        write.csv(df, "C:/GitHub/myados/unicefData/validation/results/indicator_validation_20260112_150126/r/success/MNCH_MLRCARE.csv", row.names = FALSE)
        cat(nrow(df))
    } else {
        cat("0")
    }
}, error = function(e) {
    writeLines(as.character(e$message), "C:/GitHub/myados/unicefData/validation/results/indicator_validation_20260112_150126/r/failed/MNCH_MLRCARE.error")
    cat("ERROR")
})
