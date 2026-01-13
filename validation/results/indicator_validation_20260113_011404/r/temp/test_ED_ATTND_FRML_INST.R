
library(unicefData)
tryCatch({
    df <- unicefData(
        indicator = "ED_ATTND_FRML_INST",
        
        
    )
    
    if (nrow(df) > 0) {
        write.csv(df, "C:/GitHub/myados/unicefData/validation/results/indicator_validation_20260113_011404/r/success/ED_ATTND_FRML_INST.csv", row.names = FALSE)
        cat(nrow(df))
    } else {
        cat("0")
    }
}, error = function(e) {
    writeLines(as.character(e$message), "C:/GitHub/myados/unicefData/validation/results/indicator_validation_20260113_011404/r/failed/ED_ATTND_FRML_INST.error")
    cat("ERROR")
})
