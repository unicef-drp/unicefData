
library(unicefData)
tryCatch({
    df <- unicefData(
        indicator = "COD_MOUTH_AND_OROPHARYNX_CANCERS",
        
        
    )
    
    if (nrow(df) > 0) {
        write.csv(df, "C:/GitHub/myados/unicefData/validation/results/indicator_validation_20260112_134236/r/success/COD_MOUTH_AND_OROPHARYNX_CANCERS.csv", row.names = FALSE)
        cat(nrow(df))
    } else {
        cat("0")
    }
}, error = function(e) {
    writeLines(as.character(e$message), "C:/GitHub/myados/unicefData/validation/results/indicator_validation_20260112_134236/r/failed/COD_MOUTH_AND_OROPHARYNX_CANCERS.error")
    cat("ERROR")
})
