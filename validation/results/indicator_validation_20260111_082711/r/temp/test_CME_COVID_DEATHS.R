
library(unicefData)
tryCatch({
    df <- unicefData(
        indicator = "CME_COVID_DEATHS",
        
        
    )
    
    if (nrow(df) > 0) {
        write.csv(df, "C:/GitHub/myados/unicefData/validation/results/indicator_validation_20260111_082711/r/success/CME_COVID_DEATHS.csv", row.names = FALSE)
        cat(nrow(df))
    } else {
        cat("0")
    }
}, error = function(e) {
    writeLines(as.character(e$message), "C:/GitHub/myados/unicefData/validation/results/indicator_validation_20260111_082711/r/failed/CME_COVID_DEATHS.error")
    cat("ERROR")
})
