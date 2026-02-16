
library(unicefData)
tryCatch({
    df <- unicefData(
        indicator = "WS_SCH_S-I",
        
        
    )
    
    if (nrow(df) > 0) {
        write.csv(df, "C:/GitHub/myados/unicefData/validation/results/indicator_validation_20260112_160938/r/success/WS_SCH_S-I.csv", row.names = FALSE)
        cat(nrow(df))
    } else {
        cat("0")
    }
}, error = function(e) {
    writeLines(as.character(e$message), "C:/GitHub/myados/unicefData/validation/results/indicator_validation_20260112_160938/r/failed/WS_SCH_S-I.error")
    cat("ERROR")
})
