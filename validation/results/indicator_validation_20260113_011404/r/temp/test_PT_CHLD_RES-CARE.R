
library(unicefData)
tryCatch({
    df <- unicefData(
        indicator = "PT_CHLD_RES-CARE",
        
        
    )
    
    if (nrow(df) > 0) {
        write.csv(df, "C:/GitHub/myados/unicefData/validation/results/indicator_validation_20260113_011404/r/success/PT_CHLD_RES-CARE.csv", row.names = FALSE)
        cat(nrow(df))
    } else {
        cat("0")
    }
}, error = function(e) {
    writeLines(as.character(e$message), "C:/GitHub/myados/unicefData/validation/results/indicator_validation_20260113_011404/r/failed/PT_CHLD_RES-CARE.error")
    cat("ERROR")
})
