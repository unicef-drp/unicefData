
library(unicefData)
tryCatch({
    df <- unicefData(
        indicator = "NT_ANE_WOM_15_19",
        
        
    )
    
    if (nrow(df) > 0) {
        write.csv(df, "C:/GitHub/myados/unicefData/validation/results/indicator_validation_20260111_082711/r/success/NT_ANE_WOM_15_19.csv", row.names = FALSE)
        cat(nrow(df))
    } else {
        cat("0")
    }
}, error = function(e) {
    writeLines(as.character(e$message), "C:/GitHub/myados/unicefData/validation/results/indicator_validation_20260111_082711/r/failed/NT_ANE_WOM_15_19.error")
    cat("ERROR")
})
