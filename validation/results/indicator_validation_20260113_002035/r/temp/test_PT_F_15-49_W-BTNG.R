
library(unicefData)
tryCatch({
    df <- unicefData(
        indicator = "PT_F_15-49_W-BTNG",
        
        
    )
    
    if (nrow(df) > 0) {
        write.csv(df, "C:/GitHub/myados/unicefData/validation/results/indicator_validation_20260113_002035/r/success/PT_F_15-49_W-BTNG.csv", row.names = FALSE)
        cat(nrow(df))
    } else {
        cat("0")
    }
}, error = function(e) {
    writeLines(as.character(e$message), "C:/GitHub/myados/unicefData/validation/results/indicator_validation_20260113_002035/r/failed/PT_F_15-49_W-BTNG.error")
    cat("ERROR")
})
