
library(unicefData)
tryCatch({
    df <- unicefData(
        indicator = "NT_BF_EIBF",
        
        
    )
    
    if (nrow(df) > 0) {
        write.csv(df, "C:/GitHub/myados/unicefData/validation/results/indicator_validation_20260112_231042/r/success/NT_BF_EIBF.csv", row.names = FALSE)
        cat(nrow(df))
    } else {
        cat("0")
    }
}, error = function(e) {
    writeLines(as.character(e$message), "C:/GitHub/myados/unicefData/validation/results/indicator_validation_20260112_231042/r/failed/NT_BF_EIBF.error")
    cat("ERROR")
})
