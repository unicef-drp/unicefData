
library(unicefData)
tryCatch({
    df <- unicefData(
        indicator = "COD_IRON_DEFICIENCY_ANAEMIA",
        
        
    )
    
    if (nrow(df) > 0) {
        write.csv(df, "C:/GitHub/myados/unicefData/validation/results/indicator_validation_20260112_134236/r/success/COD_IRON_DEFICIENCY_ANAEMIA.csv", row.names = FALSE)
        cat(nrow(df))
    } else {
        cat("0")
    }
}, error = function(e) {
    writeLines(as.character(e$message), "C:/GitHub/myados/unicefData/validation/results/indicator_validation_20260112_134236/r/failed/COD_IRON_DEFICIENCY_ANAEMIA.error")
    cat("ERROR")
})
