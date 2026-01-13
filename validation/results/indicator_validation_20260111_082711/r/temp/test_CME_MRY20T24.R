
library(unicefData)
tryCatch({
    df <- unicefData(
        indicator = "CME_MRY20T24",
        
        
    )
    
    if (nrow(df) > 0) {
        write.csv(df, "C:/GitHub/myados/unicefData/validation/results/indicator_validation_20260111_082711/r/success/CME_MRY20T24.csv", row.names = FALSE)
        cat(nrow(df))
    } else {
        cat("0")
    }
}, error = function(e) {
    writeLines(as.character(e$message), "C:/GitHub/myados/unicefData/validation/results/indicator_validation_20260111_082711/r/failed/CME_MRY20T24.error")
    cat("ERROR")
})
