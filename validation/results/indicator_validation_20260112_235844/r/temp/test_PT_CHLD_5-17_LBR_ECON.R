
library(unicefData)
tryCatch({
    df <- unicefData(
        indicator = "PT_CHLD_5-17_LBR_ECON",
        
        
    )
    
    if (nrow(df) > 0) {
        write.csv(df, "C:/GitHub/myados/unicefData/validation/results/indicator_validation_20260112_235844/r/success/PT_CHLD_5-17_LBR_ECON.csv", row.names = FALSE)
        cat(nrow(df))
    } else {
        cat("0")
    }
}, error = function(e) {
    writeLines(as.character(e$message), "C:/GitHub/myados/unicefData/validation/results/indicator_validation_20260112_235844/r/failed/PT_CHLD_5-17_LBR_ECON.error")
    cat("ERROR")
})
