
library(unicefData)
tryCatch({
    df <- unicefData(
        indicator = "DM_BRTS_SURVIVING_1",
        
        
    )
    
    if (nrow(df) > 0) {
        write.csv(df, "C:/GitHub/myados/unicefData/validation/results/indicator_validation_20260111_082711/r/success/DM_BRTS_SURVIVING_1.csv", row.names = FALSE)
        cat(nrow(df))
    } else {
        cat("0")
    }
}, error = function(e) {
    writeLines(as.character(e$message), "C:/GitHub/myados/unicefData/validation/results/indicator_validation_20260111_082711/r/failed/DM_BRTS_SURVIVING_1.error")
    cat("ERROR")
})
