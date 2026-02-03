
library(unicefData)
tryCatch({
    df <- unicefData(
        indicator = "WT_ADLS_15-19_ED_NEET",
        
        
    )
    
    if (nrow(df) > 0) {
        write.csv(df, "C:/GitHub/myados/unicefData/validation/results/indicator_validation_20260112_160938/r/success/WT_ADLS_15-19_ED_NEET.csv", row.names = FALSE)
        cat(nrow(df))
    } else {
        cat("0")
    }
}, error = function(e) {
    writeLines(as.character(e$message), "C:/GitHub/myados/unicefData/validation/results/indicator_validation_20260112_160938/r/failed/WT_ADLS_15-19_ED_NEET.error")
    cat("ERROR")
})
