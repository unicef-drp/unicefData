
library(unicefData)
tryCatch({
    df <- unicefData(
        indicator = "SPP_MOTHERS_CASH_BNF",
        
        
    )
    
    if (nrow(df) > 0) {
        write.csv(df, "C:/GitHub/myados/unicefData/validation/results/indicator_validation_20260112_160938/r/success/SPP_MOTHERS_CASH_BNF.csv", row.names = FALSE)
        cat(nrow(df))
    } else {
        cat("0")
    }
}, error = function(e) {
    writeLines(as.character(e$message), "C:/GitHub/myados/unicefData/validation/results/indicator_validation_20260112_160938/r/failed/SPP_MOTHERS_CASH_BNF.error")
    cat("ERROR")
})
