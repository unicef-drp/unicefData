
library(unicefData)
tryCatch({
    df <- unicefData(
        indicator = "NT_ANT_BAZ_NE2_T_NE3",
        
        
    )
    
    if (nrow(df) > 0) {
        write.csv(df, "C:/GitHub/myados/unicefData/validation/results/indicator_validation_20260111_082711/r/success/NT_ANT_BAZ_NE2_T_NE3.csv", row.names = FALSE)
        cat(nrow(df))
    } else {
        cat("0")
    }
}, error = function(e) {
    writeLines(as.character(e$message), "C:/GitHub/myados/unicefData/validation/results/indicator_validation_20260111_082711/r/failed/NT_ANT_BAZ_NE2_T_NE3.error")
    cat("ERROR")
})
