
library(unicefData)
tryCatch({
    df <- unicefData(
        indicator = "ECD_CHLD_LMPSL_PRXY",
        
        
    )
    
    if (nrow(df) > 0) {
        write.csv(df, "C:/GitHub/myados/unicefData/validation/results/indicator_validation_20260112_235844/r/success/ECD_CHLD_LMPSL_PRXY.csv", row.names = FALSE)
        cat(nrow(df))
    } else {
        cat("0")
    }
}, error = function(e) {
    writeLines(as.character(e$message), "C:/GitHub/myados/unicefData/validation/results/indicator_validation_20260112_235844/r/failed/ECD_CHLD_LMPSL_PRXY.error")
    cat("ERROR")
})
