
library(unicefData)
tryCatch({
    df <- unicefData(
        indicator = "COD_DIABETES_MELLITUS",
        
        
    )
    
    if (nrow(df) > 0) {
        write.csv(df, "C:/GitHub/myados/unicefData/validation/results/indicator_validation_20260111_082711/r/success/COD_DIABETES_MELLITUS.csv", row.names = FALSE)
        cat(nrow(df))
    } else {
        cat("0")
    }
}, error = function(e) {
    writeLines(as.character(e$message), "C:/GitHub/myados/unicefData/validation/results/indicator_validation_20260111_082711/r/failed/COD_DIABETES_MELLITUS.error")
    cat("ERROR")
})
