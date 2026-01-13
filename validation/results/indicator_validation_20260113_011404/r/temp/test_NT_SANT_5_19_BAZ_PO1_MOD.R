
library(unicefData)
tryCatch({
    df <- unicefData(
        indicator = "NT_SANT_5_19_BAZ_PO1_MOD",
        
        
    )
    
    if (nrow(df) > 0) {
        write.csv(df, "C:/GitHub/myados/unicefData/validation/results/indicator_validation_20260113_011404/r/success/NT_SANT_5_19_BAZ_PO1_MOD.csv", row.names = FALSE)
        cat(nrow(df))
    } else {
        cat("0")
    }
}, error = function(e) {
    writeLines(as.character(e$message), "C:/GitHub/myados/unicefData/validation/results/indicator_validation_20260113_011404/r/failed/NT_SANT_5_19_BAZ_PO1_MOD.error")
    cat("ERROR")
})
