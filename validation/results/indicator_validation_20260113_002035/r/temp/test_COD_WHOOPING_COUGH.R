
library(unicefData)
tryCatch({
    df <- unicefData(
        indicator = "COD_WHOOPING_COUGH",
        
        
    )
    
    if (nrow(df) > 0) {
        write.csv(df, "C:/GitHub/myados/unicefData/validation/results/indicator_validation_20260113_002035/r/success/COD_WHOOPING_COUGH.csv", row.names = FALSE)
        cat(nrow(df))
    } else {
        cat("0")
    }
}, error = function(e) {
    writeLines(as.character(e$message), "C:/GitHub/myados/unicefData/validation/results/indicator_validation_20260113_002035/r/failed/COD_WHOOPING_COUGH.error")
    cat("ERROR")
})
