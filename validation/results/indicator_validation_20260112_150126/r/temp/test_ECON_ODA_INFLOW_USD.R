
library(unicefData)
tryCatch({
    df <- unicefData(
        indicator = "ECON_ODA_INFLOW_USD",
        
        
    )
    
    if (nrow(df) > 0) {
        write.csv(df, "C:/GitHub/myados/unicefData/validation/results/indicator_validation_20260112_150126/r/success/ECON_ODA_INFLOW_USD.csv", row.names = FALSE)
        cat(nrow(df))
    } else {
        cat("0")
    }
}, error = function(e) {
    writeLines(as.character(e$message), "C:/GitHub/myados/unicefData/validation/results/indicator_validation_20260112_150126/r/failed/ECON_ODA_INFLOW_USD.error")
    cat("ERROR")
})
