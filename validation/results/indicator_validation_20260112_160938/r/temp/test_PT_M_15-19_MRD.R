
library(unicefData)
tryCatch({
    df <- unicefData(
        indicator = "PT_M_15-19_MRD",
        
        
    )
    
    if (nrow(df) > 0) {
        write.csv(df, "C:/GitHub/myados/unicefData/validation/results/indicator_validation_20260112_160938/r/success/PT_M_15-19_MRD.csv", row.names = FALSE)
        cat(nrow(df))
    } else {
        cat("0")
    }
}, error = function(e) {
    writeLines(as.character(e$message), "C:/GitHub/myados/unicefData/validation/results/indicator_validation_20260112_160938/r/failed/PT_M_15-19_MRD.error")
    cat("ERROR")
})
