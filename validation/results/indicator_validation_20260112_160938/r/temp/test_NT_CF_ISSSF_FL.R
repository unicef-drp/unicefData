
library(unicefData)
tryCatch({
    df <- unicefData(
        indicator = "NT_CF_ISSSF_FL",
        
        
    )
    
    if (nrow(df) > 0) {
        write.csv(df, "C:/GitHub/myados/unicefData/validation/results/indicator_validation_20260112_160938/r/success/NT_CF_ISSSF_FL.csv", row.names = FALSE)
        cat(nrow(df))
    } else {
        cat("0")
    }
}, error = function(e) {
    writeLines(as.character(e$message), "C:/GitHub/myados/unicefData/validation/results/indicator_validation_20260112_160938/r/failed/NT_CF_ISSSF_FL.error")
    cat("ERROR")
})
