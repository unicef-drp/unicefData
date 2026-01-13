
library(unicefData)
tryCatch({
    df <- unicefData(
        indicator = "COD_BRAIN_AND_NERVOUS_SYSTEM_CANCERS",
        
        
    )
    
    if (nrow(df) > 0) {
        write.csv(df, "C:/GitHub/myados/unicefData/validation/results/indicator_validation_20260111_082711/r/success/COD_BRAIN_AND_NERVOUS_SYSTEM_CANCERS.csv", row.names = FALSE)
        cat(nrow(df))
    } else {
        cat("0")
    }
}, error = function(e) {
    writeLines(as.character(e$message), "C:/GitHub/myados/unicefData/validation/results/indicator_validation_20260111_082711/r/failed/COD_BRAIN_AND_NERVOUS_SYSTEM_CANCERS.error")
    cat("ERROR")
})
