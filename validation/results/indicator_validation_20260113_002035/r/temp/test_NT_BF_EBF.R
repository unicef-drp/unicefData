
library(unicefData)
tryCatch({
    df <- unicefData(
        indicator = "NT_BF_EBF",
        
        
    )
    
    if (nrow(df) > 0) {
        write.csv(df, "C:/GitHub/myados/unicefData/validation/results/indicator_validation_20260113_002035/r/success/NT_BF_EBF.csv", row.names = FALSE)
        cat(nrow(df))
    } else {
        cat("0")
    }
}, error = function(e) {
    writeLines(as.character(e$message), "C:/GitHub/myados/unicefData/validation/results/indicator_validation_20260113_002035/r/failed/NT_BF_EBF.error")
    cat("ERROR")
})
