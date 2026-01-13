
library(unicefData)
tryCatch({
    df <- unicefData(
        indicator = "COD_MELANOMA_AND_OTHER_SKIN_CANCERS",
        
        
    )
    
    if (nrow(df) > 0) {
        write.csv(df, "C:/GitHub/myados/unicefData/validation/results/indicator_validation_20260112_134236/r/success/COD_MELANOMA_AND_OTHER_SKIN_CANCERS.csv", row.names = FALSE)
        cat(nrow(df))
    } else {
        cat("0")
    }
}, error = function(e) {
    writeLines(as.character(e$message), "C:/GitHub/myados/unicefData/validation/results/indicator_validation_20260112_134236/r/failed/COD_MELANOMA_AND_OTHER_SKIN_CANCERS.error")
    cat("ERROR")
})
