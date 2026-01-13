
library(unicefData)
tryCatch({
    df <- unicefData(
        indicator = "ECD_CHLD_24-59M_ADLT_SRC",
        
        
    )
    
    if (nrow(df) > 0) {
        write.csv(df, "C:/GitHub/myados/unicefData/validation/results/indicator_validation_20260111_082711/r/success/ECD_CHLD_24-59M_ADLT_SRC.csv", row.names = FALSE)
        cat(nrow(df))
    } else {
        cat("0")
    }
}, error = function(e) {
    writeLines(as.character(e$message), "C:/GitHub/myados/unicefData/validation/results/indicator_validation_20260111_082711/r/failed/ECD_CHLD_24-59M_ADLT_SRC.error")
    cat("ERROR")
})
