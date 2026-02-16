
library(unicefData)
tryCatch({
    df <- unicefData(
        indicator = "COD_HYPERTENSIVE_HEART_DISEASE",
        
        
    )
    
    if (nrow(df) > 0) {
        write.csv(df, "C:/GitHub/myados/unicefData/validation/results/indicator_validation_20260112_224003/r/success/COD_HYPERTENSIVE_HEART_DISEASE.csv", row.names = FALSE)
        cat(nrow(df))
    } else {
        cat("0")
    }
}, error = function(e) {
    writeLines(as.character(e$message), "C:/GitHub/myados/unicefData/validation/results/indicator_validation_20260112_224003/r/failed/COD_HYPERTENSIVE_HEART_DISEASE.error")
    cat("ERROR")
})
