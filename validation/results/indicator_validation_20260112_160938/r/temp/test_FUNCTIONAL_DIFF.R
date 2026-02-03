
library(unicefData)
tryCatch({
    df <- unicefData(
        indicator = "FUNCTIONAL_DIFF",
        
        
    )
    
    if (nrow(df) > 0) {
        write.csv(df, "C:/GitHub/myados/unicefData/validation/results/indicator_validation_20260112_160938/r/success/FUNCTIONAL_DIFF.csv", row.names = FALSE)
        cat(nrow(df))
    } else {
        cat("0")
    }
}, error = function(e) {
    writeLines(as.character(e$message), "C:/GitHub/myados/unicefData/validation/results/indicator_validation_20260112_160938/r/failed/FUNCTIONAL_DIFF.error")
    cat("ERROR")
})
