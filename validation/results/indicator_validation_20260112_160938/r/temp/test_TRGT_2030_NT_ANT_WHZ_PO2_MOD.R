
library(unicefData)
tryCatch({
    df <- unicefData(
        indicator = "TRGT_2030_NT_ANT_WHZ_PO2_MOD",
        
        
    )
    
    if (nrow(df) > 0) {
        write.csv(df, "C:/GitHub/myados/unicefData/validation/results/indicator_validation_20260112_160938/r/success/TRGT_2030_NT_ANT_WHZ_PO2_MOD.csv", row.names = FALSE)
        cat(nrow(df))
    } else {
        cat("0")
    }
}, error = function(e) {
    writeLines(as.character(e$message), "C:/GitHub/myados/unicefData/validation/results/indicator_validation_20260112_160938/r/failed/TRGT_2030_NT_ANT_WHZ_PO2_MOD.error")
    cat("ERROR")
})
