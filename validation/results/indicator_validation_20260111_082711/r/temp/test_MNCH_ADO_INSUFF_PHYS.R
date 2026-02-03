
library(unicefData)
tryCatch({
    df <- unicefData(
        indicator = "MNCH_ADO_INSUFF_PHYS",
        
        
    )
    
    if (nrow(df) > 0) {
        write.csv(df, "C:/GitHub/myados/unicefData/validation/results/indicator_validation_20260111_082711/r/success/MNCH_ADO_INSUFF_PHYS.csv", row.names = FALSE)
        cat(nrow(df))
    } else {
        cat("0")
    }
}, error = function(e) {
    writeLines(as.character(e$message), "C:/GitHub/myados/unicefData/validation/results/indicator_validation_20260111_082711/r/failed/MNCH_ADO_INSUFF_PHYS.error")
    cat("ERROR")
})
