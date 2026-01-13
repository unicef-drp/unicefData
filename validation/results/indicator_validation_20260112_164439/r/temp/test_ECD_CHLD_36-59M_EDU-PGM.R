
library(unicefData)
tryCatch({
    df <- unicefData(
        indicator = "ECD_CHLD_36-59M_EDU-PGM",
        
        
    )
    
    if (nrow(df) > 0) {
        write.csv(df, "C:/GitHub/myados/unicefData/validation/results/indicator_validation_20260112_164439/r/success/ECD_CHLD_36-59M_EDU-PGM.csv", row.names = FALSE)
        cat(nrow(df))
    } else {
        cat("0")
    }
}, error = function(e) {
    writeLines(as.character(e$message), "C:/GitHub/myados/unicefData/validation/results/indicator_validation_20260112_164439/r/failed/ECD_CHLD_36-59M_EDU-PGM.error")
    cat("ERROR")
})
