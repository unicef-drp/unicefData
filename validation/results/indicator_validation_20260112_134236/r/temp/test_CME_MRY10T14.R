
library(unicefData)
tryCatch({
    df <- unicefData(
        indicator = "CME_MRY10T14",
        
        
    )
    
    if (nrow(df) > 0) {
        write.csv(df, "C:/GitHub/myados/unicefData/validation/results/indicator_validation_20260112_134236/r/success/CME_MRY10T14.csv", row.names = FALSE)
        cat(nrow(df))
    } else {
        cat("0")
    }
}, error = function(e) {
    writeLines(as.character(e$message), "C:/GitHub/myados/unicefData/validation/results/indicator_validation_20260112_134236/r/failed/CME_MRY10T14.error")
    cat("ERROR")
})
