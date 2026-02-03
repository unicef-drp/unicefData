
library(unicefData)
tryCatch({
    df <- unicefData(
        indicator = "COD_TRACHEA_BRONCHUS_LUNG_CANCERS",
        
        
    )
    
    if (nrow(df) > 0) {
        write.csv(df, "C:/GitHub/myados/unicefData/validation/results/indicator_validation_20260111_082711/r/success/COD_TRACHEA_BRONCHUS_LUNG_CANCERS.csv", row.names = FALSE)
        cat(nrow(df))
    } else {
        cat("0")
    }
}, error = function(e) {
    writeLines(as.character(e$message), "C:/GitHub/myados/unicefData/validation/results/indicator_validation_20260111_082711/r/failed/COD_TRACHEA_BRONCHUS_LUNG_CANCERS.error")
    cat("ERROR")
})
