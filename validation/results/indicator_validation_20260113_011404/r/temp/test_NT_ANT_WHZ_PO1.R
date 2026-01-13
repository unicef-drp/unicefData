
library(unicefData)
tryCatch({
    df <- unicefData(
        indicator = "NT_ANT_WHZ_PO1",
        
        
    )
    
    if (nrow(df) > 0) {
        write.csv(df, "C:/GitHub/myados/unicefData/validation/results/indicator_validation_20260113_011404/r/success/NT_ANT_WHZ_PO1.csv", row.names = FALSE)
        cat(nrow(df))
    } else {
        cat("0")
    }
}, error = function(e) {
    writeLines(as.character(e$message), "C:/GitHub/myados/unicefData/validation/results/indicator_validation_20260113_011404/r/failed/NT_ANT_WHZ_PO1.error")
    cat("ERROR")
})
