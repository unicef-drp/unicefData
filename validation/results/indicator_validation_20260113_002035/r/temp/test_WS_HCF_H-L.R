
library(unicefData)
tryCatch({
    df <- unicefData(
        indicator = "WS_HCF_H-L",
        
        
    )
    
    if (nrow(df) > 0) {
        write.csv(df, "C:/GitHub/myados/unicefData/validation/results/indicator_validation_20260113_002035/r/success/WS_HCF_H-L.csv", row.names = FALSE)
        cat(nrow(df))
    } else {
        cat("0")
    }
}, error = function(e) {
    writeLines(as.character(e$message), "C:/GitHub/myados/unicefData/validation/results/indicator_validation_20260113_002035/r/failed/WS_HCF_H-L.error")
    cat("ERROR")
})
