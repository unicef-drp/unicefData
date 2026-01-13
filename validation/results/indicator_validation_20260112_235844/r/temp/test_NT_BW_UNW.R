
library(unicefData)
tryCatch({
    df <- unicefData(
        indicator = "NT_BW_UNW",
        
        
    )
    
    if (nrow(df) > 0) {
        write.csv(df, "C:/GitHub/myados/unicefData/validation/results/indicator_validation_20260112_235844/r/success/NT_BW_UNW.csv", row.names = FALSE)
        cat(nrow(df))
    } else {
        cat("0")
    }
}, error = function(e) {
    writeLines(as.character(e$message), "C:/GitHub/myados/unicefData/validation/results/indicator_validation_20260112_235844/r/failed/NT_BW_UNW.error")
    cat("ERROR")
})
