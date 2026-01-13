
library(unicefData)
tryCatch({
    df <- unicefData(
        indicator = "DM_POP_ADLCNT_PROP",
        
        
    )
    
    if (nrow(df) > 0) {
        write.csv(df, "C:/GitHub/myados/unicefData/validation/results/indicator_validation_20260111_082711/r/success/DM_POP_ADLCNT_PROP.csv", row.names = FALSE)
        cat(nrow(df))
    } else {
        cat("0")
    }
}, error = function(e) {
    writeLines(as.character(e$message), "C:/GitHub/myados/unicefData/validation/results/indicator_validation_20260111_082711/r/failed/DM_POP_ADLCNT_PROP.error")
    cat("ERROR")
})
