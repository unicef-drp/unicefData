
library(unicefData)
tryCatch({
    df <- unicefData(
        indicator = "ED_RLRI_L2",
        
        
    )
    
    if (nrow(df) > 0) {
        write.csv(df, "C:/GitHub/myados/unicefData/validation/results/indicator_validation_20260113_011404/r/success/ED_RLRI_L2.csv", row.names = FALSE)
        cat(nrow(df))
    } else {
        cat("0")
    }
}, error = function(e) {
    writeLines(as.character(e$message), "C:/GitHub/myados/unicefData/validation/results/indicator_validation_20260113_011404/r/failed/ED_RLRI_L2.error")
    cat("ERROR")
})
