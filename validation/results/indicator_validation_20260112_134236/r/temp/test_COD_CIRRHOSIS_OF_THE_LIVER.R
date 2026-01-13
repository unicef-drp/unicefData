
library(unicefData)
tryCatch({
    df <- unicefData(
        indicator = "COD_CIRRHOSIS_OF_THE_LIVER",
        
        
    )
    
    if (nrow(df) > 0) {
        write.csv(df, "C:/GitHub/myados/unicefData/validation/results/indicator_validation_20260112_134236/r/success/COD_CIRRHOSIS_OF_THE_LIVER.csv", row.names = FALSE)
        cat(nrow(df))
    } else {
        cat("0")
    }
}, error = function(e) {
    writeLines(as.character(e$message), "C:/GitHub/myados/unicefData/validation/results/indicator_validation_20260112_134236/r/failed/COD_CIRRHOSIS_OF_THE_LIVER.error")
    cat("ERROR")
})
