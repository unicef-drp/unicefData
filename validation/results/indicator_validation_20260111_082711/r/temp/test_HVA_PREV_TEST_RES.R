
library(unicefData)
tryCatch({
    df <- unicefData(
        indicator = "HVA_PREV_TEST_RES",
        
        
    )
    
    if (nrow(df) > 0) {
        write.csv(df, "C:/GitHub/myados/unicefData/validation/results/indicator_validation_20260111_082711/r/success/HVA_PREV_TEST_RES.csv", row.names = FALSE)
        cat(nrow(df))
    } else {
        cat("0")
    }
}, error = function(e) {
    writeLines(as.character(e$message), "C:/GitHub/myados/unicefData/validation/results/indicator_validation_20260111_082711/r/failed/HVA_PREV_TEST_RES.error")
    cat("ERROR")
})
