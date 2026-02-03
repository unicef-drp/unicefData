
library(unicefData)
tryCatch({
    df <- unicefData(
        indicator = "WS_HCF_W-B",
        
        
    )
    
    if (nrow(df) > 0) {
        write.csv(df, "C:/GitHub/myados/unicefData/validation/results/indicator_validation_20260112_160938/r/success/WS_HCF_W-B.csv", row.names = FALSE)
        cat(nrow(df))
    } else {
        cat("0")
    }
}, error = function(e) {
    writeLines(as.character(e$message), "C:/GitHub/myados/unicefData/validation/results/indicator_validation_20260112_160938/r/failed/WS_HCF_W-B.error")
    cat("ERROR")
})
