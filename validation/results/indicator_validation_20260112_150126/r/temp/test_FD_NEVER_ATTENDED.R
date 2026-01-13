
library(unicefData)
tryCatch({
    df <- unicefData(
        indicator = "FD_NEVER_ATTENDED",
        
        
    )
    
    if (nrow(df) > 0) {
        write.csv(df, "C:/GitHub/myados/unicefData/validation/results/indicator_validation_20260112_150126/r/success/FD_NEVER_ATTENDED.csv", row.names = FALSE)
        cat(nrow(df))
    } else {
        cat("0")
    }
}, error = function(e) {
    writeLines(as.character(e$message), "C:/GitHub/myados/unicefData/validation/results/indicator_validation_20260112_150126/r/failed/FD_NEVER_ATTENDED.error")
    cat("ERROR")
})
