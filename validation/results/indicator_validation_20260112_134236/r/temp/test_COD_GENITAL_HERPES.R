
library(unicefData)
tryCatch({
    df <- unicefData(
        indicator = "COD_GENITAL_HERPES",
        
        
    )
    
    if (nrow(df) > 0) {
        write.csv(df, "C:/GitHub/myados/unicefData/validation/results/indicator_validation_20260112_134236/r/success/COD_GENITAL_HERPES.csv", row.names = FALSE)
        cat(nrow(df))
    } else {
        cat("0")
    }
}, error = function(e) {
    writeLines(as.character(e$message), "C:/GitHub/myados/unicefData/validation/results/indicator_validation_20260112_134236/r/failed/COD_GENITAL_HERPES.error")
    cat("ERROR")
})
