
library(unicefData)
tryCatch({
    df <- unicefData(
        indicator = "TRGT",
        
        
    )
    
    if (nrow(df) > 0) {
        write.csv(df, "C:/GitHub/myados/unicefData/validation/results/indicator_validation_20260112_231042/r/success/TRGT.csv", row.names = FALSE)
        cat(nrow(df))
    } else {
        cat("0")
    }
}, error = function(e) {
    writeLines(as.character(e$message), "C:/GitHub/myados/unicefData/validation/results/indicator_validation_20260112_231042/r/failed/TRGT.error")
    cat("ERROR")
})
