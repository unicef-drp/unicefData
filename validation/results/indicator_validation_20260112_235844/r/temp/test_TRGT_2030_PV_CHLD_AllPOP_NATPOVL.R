
library(unicefData)
tryCatch({
    df <- unicefData(
        indicator = "TRGT_2030_PV_CHLD_AllPOP_NATPOVL",
        
        
    )
    
    if (nrow(df) > 0) {
        write.csv(df, "C:/GitHub/myados/unicefData/validation/results/indicator_validation_20260112_235844/r/success/TRGT_2030_PV_CHLD_AllPOP_NATPOVL.csv", row.names = FALSE)
        cat(nrow(df))
    } else {
        cat("0")
    }
}, error = function(e) {
    writeLines(as.character(e$message), "C:/GitHub/myados/unicefData/validation/results/indicator_validation_20260112_235844/r/failed/TRGT_2030_PV_CHLD_AllPOP_NATPOVL.error")
    cat("ERROR")
})
