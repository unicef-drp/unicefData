
library(unicefData)
tryCatch({
    df <- unicefData(
        indicator = "MG_INTERNAL_DISP_PERS",
        
        
    )
    
    if (nrow(df) > 0) {
        write.csv(df, "C:/GitHub/myados/unicefData/validation/results/indicator_validation_20260111_082711/r/success/MG_INTERNAL_DISP_PERS.csv", row.names = FALSE)
        cat(nrow(df))
    } else {
        cat("0")
    }
}, error = function(e) {
    writeLines(as.character(e$message), "C:/GitHub/myados/unicefData/validation/results/indicator_validation_20260111_082711/r/failed/MG_INTERNAL_DISP_PERS.error")
    cat("ERROR")
})
