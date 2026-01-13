
library(unicefData)
tryCatch({
    df <- unicefData(
        indicator = "PT_F_GE15_SX_V_PTNR_12MNTH",
        
        
    )
    
    if (nrow(df) > 0) {
        write.csv(df, "C:/GitHub/myados/unicefData/validation/results/indicator_validation_20260113_011404/r/success/PT_F_GE15_SX_V_PTNR_12MNTH.csv", row.names = FALSE)
        cat(nrow(df))
    } else {
        cat("0")
    }
}, error = function(e) {
    writeLines(as.character(e$message), "C:/GitHub/myados/unicefData/validation/results/indicator_validation_20260113_011404/r/failed/PT_F_GE15_SX_V_PTNR_12MNTH.error")
    cat("ERROR")
})
