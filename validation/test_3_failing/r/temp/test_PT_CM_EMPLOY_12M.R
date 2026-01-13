
library(unicefData)
tryCatch({
    df <- unicefData(
        indicator = "PT_CM_EMPLOY_12M",
        
        
    )
    
    if (nrow(df) > 0) {
        write.csv(df, "C:/GitHub/myados/unicefData/validation/test_3_failing/r/success/PT_CM_EMPLOY_12M.csv", row.names = FALSE)
        cat(nrow(df))
    } else {
        cat("0")
    }
}, error = function(e) {
    writeLines(as.character(e$message), "C:/GitHub/myados/unicefData/validation/test_3_failing/r/failed/PT_CM_EMPLOY_12M.error")
    cat("ERROR")
})
