
library(unicefData)
tryCatch({
    df <- unicefData(
        indicator = "COD_COLON_AND_RECTUM_CANCERS",
        
        
    )
    
    if (nrow(df) > 0) {
        write.csv(df, "C:/GitHub/myados/unicefData/validation/results/indicator_validation_20260111_082711/r/success/COD_COLON_AND_RECTUM_CANCERS.csv", row.names = FALSE)
        cat(nrow(df))
    } else {
        cat("0")
    }
}, error = function(e) {
    writeLines(as.character(e$message), "C:/GitHub/myados/unicefData/validation/results/indicator_validation_20260111_082711/r/failed/COD_COLON_AND_RECTUM_CANCERS.error")
    cat("ERROR")
})
