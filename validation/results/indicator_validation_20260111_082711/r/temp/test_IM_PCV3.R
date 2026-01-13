
library(unicefData)
tryCatch({
    df <- unicefData(
        indicator = "IM_PCV3",
        
        
    )
    
    if (nrow(df) > 0) {
        write.csv(df, "C:/GitHub/myados/unicefData/validation/results/indicator_validation_20260111_082711/r/success/IM_PCV3.csv", row.names = FALSE)
        cat(nrow(df))
    } else {
        cat("0")
    }
}, error = function(e) {
    writeLines(as.character(e$message), "C:/GitHub/myados/unicefData/validation/results/indicator_validation_20260111_082711/r/failed/IM_PCV3.error")
    cat("ERROR")
})
