
library(unicefData)
tryCatch({
    df <- unicefData(
        indicator = "TRGT_2030_WS_PPL_S-SM",
        
        
    )
    
    if (nrow(df) > 0) {
        write.csv(df, "C:/GitHub/myados/unicefData/validation/results/indicator_validation_20260113_002035/r/success/TRGT_2030_WS_PPL_S-SM.csv", row.names = FALSE)
        cat(nrow(df))
    } else {
        cat("0")
    }
}, error = function(e) {
    writeLines(as.character(e$message), "C:/GitHub/myados/unicefData/validation/results/indicator_validation_20260113_002035/r/failed/TRGT_2030_WS_PPL_S-SM.error")
    cat("ERROR")
})
