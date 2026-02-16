
library(unicefData)
tryCatch({
    df <- unicefData(
        indicator = "ED_SE_LPV_PRIM_SD",
        
        
    )
    
    if (nrow(df) > 0) {
        write.csv(df, "C:/GitHub/myados/unicefData/validation/results/indicator_validation_20260111_082711/r/success/ED_SE_LPV_PRIM_SD.csv", row.names = FALSE)
        cat(nrow(df))
    } else {
        cat("0")
    }
}, error = function(e) {
    writeLines(as.character(e$message), "C:/GitHub/myados/unicefData/validation/results/indicator_validation_20260111_082711/r/failed/ED_SE_LPV_PRIM_SD.error")
    cat("ERROR")
})
