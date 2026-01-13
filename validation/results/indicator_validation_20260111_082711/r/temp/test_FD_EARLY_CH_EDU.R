
library(unicefData)
tryCatch({
    df <- unicefData(
        indicator = "FD_EARLY_CH_EDU",
        
        
    )
    
    if (nrow(df) > 0) {
        write.csv(df, "C:/GitHub/myados/unicefData/validation/results/indicator_validation_20260111_082711/r/success/FD_EARLY_CH_EDU.csv", row.names = FALSE)
        cat(nrow(df))
    } else {
        cat("0")
    }
}, error = function(e) {
    writeLines(as.character(e$message), "C:/GitHub/myados/unicefData/validation/results/indicator_validation_20260111_082711/r/failed/FD_EARLY_CH_EDU.error")
    cat("ERROR")
})
