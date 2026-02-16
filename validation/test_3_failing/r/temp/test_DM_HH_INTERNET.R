
library(unicefData)
tryCatch({
    df <- unicefData(
        indicator = "DM_HH_INTERNET",
        
        
    )
    
    if (nrow(df) > 0) {
        write.csv(df, "C:/GitHub/myados/unicefData/validation/test_3_failing/r/success/DM_HH_INTERNET.csv", row.names = FALSE)
        cat(nrow(df))
    } else {
        cat("0")
    }
}, error = function(e) {
    writeLines(as.character(e$message), "C:/GitHub/myados/unicefData/validation/test_3_failing/r/failed/DM_HH_INTERNET.error")
    cat("ERROR")
})
