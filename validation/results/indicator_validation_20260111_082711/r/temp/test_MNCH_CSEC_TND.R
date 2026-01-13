
library(unicefData)
tryCatch({
    df <- unicefData(
        indicator = "MNCH_CSEC_TND",
        
        
    )
    
    if (nrow(df) > 0) {
        write.csv(df, "C:/GitHub/myados/unicefData/validation/results/indicator_validation_20260111_082711/r/success/MNCH_CSEC_TND.csv", row.names = FALSE)
        cat(nrow(df))
    } else {
        cat("0")
    }
}, error = function(e) {
    writeLines(as.character(e$message), "C:/GitHub/myados/unicefData/validation/results/indicator_validation_20260111_082711/r/failed/MNCH_CSEC_TND.error")
    cat("ERROR")
})
