
library(unicefData)
tryCatch({
    df <- unicefData(
        indicator = "CME_COVID_DEATHS_SHARE",
        
        
    )
    
    if (nrow(df) > 0) {
        write.csv(df, "C:/GitHub/myados/unicefData/validation/results/indicator_validation_20260112_211440/r/success/CME_COVID_DEATHS_SHARE.csv", row.names = FALSE)
        cat(nrow(df))
    } else {
        cat("0")
    }
}, error = function(e) {
    writeLines(as.character(e$message), "C:/GitHub/myados/unicefData/validation/results/indicator_validation_20260112_211440/r/failed/CME_COVID_DEATHS_SHARE.error")
    cat("ERROR")
})
