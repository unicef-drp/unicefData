
library(unicefData)
tryCatch({
    df <- unicefData(
        indicator = "COD_EXPOSURE_TO_MECHANICAL_FORCES",
        
        
    )
    
    if (nrow(df) > 0) {
        write.csv(df, "C:/GitHub/myados/unicefData/validation/results/indicator_validation_20260113_011404/r/success/COD_EXPOSURE_TO_MECHANICAL_FORCES.csv", row.names = FALSE)
        cat(nrow(df))
    } else {
        cat("0")
    }
}, error = function(e) {
    writeLines(as.character(e$message), "C:/GitHub/myados/unicefData/validation/results/indicator_validation_20260113_011404/r/failed/COD_EXPOSURE_TO_MECHANICAL_FORCES.error")
    cat("ERROR")
})
