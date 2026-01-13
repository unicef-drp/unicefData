
library(unicefData)
tryCatch({
    df <- unicefData(
        indicator = "HVA_EPI_DTH_RT",
        
        
    )
    
    if (nrow(df) > 0) {
        write.csv(df, "C:/GitHub/myados/unicefData/validation/results/indicator_validation_20260113_002035/r/success/HVA_EPI_DTH_RT.csv", row.names = FALSE)
        cat(nrow(df))
    } else {
        cat("0")
    }
}, error = function(e) {
    writeLines(as.character(e$message), "C:/GitHub/myados/unicefData/validation/results/indicator_validation_20260113_002035/r/failed/HVA_EPI_DTH_RT.error")
    cat("ERROR")
})
