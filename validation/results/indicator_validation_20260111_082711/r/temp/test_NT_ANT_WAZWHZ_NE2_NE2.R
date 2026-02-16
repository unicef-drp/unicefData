
library(unicefData)
tryCatch({
    df <- unicefData(
        indicator = "NT_ANT_WAZWHZ_NE2_NE2",
        
        
    )
    
    if (nrow(df) > 0) {
        write.csv(df, "C:/GitHub/myados/unicefData/validation/results/indicator_validation_20260111_082711/r/success/NT_ANT_WAZWHZ_NE2_NE2.csv", row.names = FALSE)
        cat(nrow(df))
    } else {
        cat("0")
    }
}, error = function(e) {
    writeLines(as.character(e$message), "C:/GitHub/myados/unicefData/validation/results/indicator_validation_20260111_082711/r/failed/NT_ANT_WAZWHZ_NE2_NE2.error")
    cat("ERROR")
})
