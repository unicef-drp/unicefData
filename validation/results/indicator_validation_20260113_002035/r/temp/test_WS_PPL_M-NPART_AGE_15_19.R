
library(unicefData)
tryCatch({
    df <- unicefData(
        indicator = "WS_PPL_M-NPART_AGE_15_19",
        
        
    )
    
    if (nrow(df) > 0) {
        write.csv(df, "C:/GitHub/myados/unicefData/validation/results/indicator_validation_20260113_002035/r/success/WS_PPL_M-NPART_AGE_15_19.csv", row.names = FALSE)
        cat(nrow(df))
    } else {
        cat("0")
    }
}, error = function(e) {
    writeLines(as.character(e$message), "C:/GitHub/myados/unicefData/validation/results/indicator_validation_20260113_002035/r/failed/WS_PPL_M-NPART_AGE_15_19.error")
    cat("ERROR")
})
