
library(unicefData)
tryCatch({
    df <- unicefData(
        indicator = "COD_ISCHAEMIC_HEART_DISEASE",
        
        
    )
    
    if (nrow(df) > 0) {
        write.csv(df, "C:/GitHub/myados/unicefData/validation/results/indicator_validation_20260111_082711/r/success/COD_ISCHAEMIC_HEART_DISEASE.csv", row.names = FALSE)
        cat(nrow(df))
    } else {
        cat("0")
    }
}, error = function(e) {
    writeLines(as.character(e$message), "C:/GitHub/myados/unicefData/validation/results/indicator_validation_20260111_082711/r/failed/COD_ISCHAEMIC_HEART_DISEASE.error")
    cat("ERROR")
})
