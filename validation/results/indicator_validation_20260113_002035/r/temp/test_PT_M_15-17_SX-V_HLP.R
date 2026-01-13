
library(unicefData)
tryCatch({
    df <- unicefData(
        indicator = "PT_M_15-17_SX-V_HLP",
        
        
    )
    
    if (nrow(df) > 0) {
        write.csv(df, "C:/GitHub/myados/unicefData/validation/results/indicator_validation_20260113_002035/r/success/PT_M_15-17_SX-V_HLP.csv", row.names = FALSE)
        cat(nrow(df))
    } else {
        cat("0")
    }
}, error = function(e) {
    writeLines(as.character(e$message), "C:/GitHub/myados/unicefData/validation/results/indicator_validation_20260113_002035/r/failed/PT_M_15-17_SX-V_HLP.error")
    cat("ERROR")
})
