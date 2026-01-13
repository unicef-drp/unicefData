
library(unicefData)
tryCatch({
    df <- unicefData(
        indicator = "ED_ROFST_L1_UIS",
        
        
    )
    
    if (nrow(df) > 0) {
        write.csv(df, "C:/GitHub/myados/unicefData/validation/results/indicator_validation_20260113_011404/r/success/ED_ROFST_L1_UIS.csv", row.names = FALSE)
        cat(nrow(df))
    } else {
        cat("0")
    }
}, error = function(e) {
    writeLines(as.character(e$message), "C:/GitHub/myados/unicefData/validation/results/indicator_validation_20260113_011404/r/failed/ED_ROFST_L1_UIS.error")
    cat("ERROR")
})
