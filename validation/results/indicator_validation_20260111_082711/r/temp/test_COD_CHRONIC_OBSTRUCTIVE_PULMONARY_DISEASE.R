
library(unicefData)
tryCatch({
    df <- unicefData(
        indicator = "COD_CHRONIC_OBSTRUCTIVE_PULMONARY_DISEASE",
        
        
    )
    
    if (nrow(df) > 0) {
        write.csv(df, "C:/GitHub/myados/unicefData/validation/results/indicator_validation_20260111_082711/r/success/COD_CHRONIC_OBSTRUCTIVE_PULMONARY_DISEASE.csv", row.names = FALSE)
        cat(nrow(df))
    } else {
        cat("0")
    }
}, error = function(e) {
    writeLines(as.character(e$message), "C:/GitHub/myados/unicefData/validation/results/indicator_validation_20260111_082711/r/failed/COD_CHRONIC_OBSTRUCTIVE_PULMONARY_DISEASE.error")
    cat("ERROR")
})
