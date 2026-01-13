
library(unicefData)
tryCatch({
    df <- unicefData(
        indicator = "COD_LOWER_RESPIRATORY_INFECTIONS",
        
        
    )
    
    if (nrow(df) > 0) {
        write.csv(df, "C:/GitHub/myados/unicefData/validation/results/indicator_validation_20260112_235844/r/success/COD_LOWER_RESPIRATORY_INFECTIONS.csv", row.names = FALSE)
        cat(nrow(df))
    } else {
        cat("0")
    }
}, error = function(e) {
    writeLines(as.character(e$message), "C:/GitHub/myados/unicefData/validation/results/indicator_validation_20260112_235844/r/failed/COD_LOWER_RESPIRATORY_INFECTIONS.error")
    cat("ERROR")
})
