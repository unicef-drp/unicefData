
library(unicefData)
tryCatch({
    df <- unicefData(
        indicator = "COD_ALCOHOL_USE_DISORDERS",
        
        
    )
    
    if (nrow(df) > 0) {
        write.csv(df, "C:/GitHub/myados/unicefData/validation/test_3_failing/r/success/COD_ALCOHOL_USE_DISORDERS.csv", row.names = FALSE)
        cat(nrow(df))
    } else {
        cat("0")
    }
}, error = function(e) {
    writeLines(as.character(e$message), "C:/GitHub/myados/unicefData/validation/test_3_failing/r/failed/COD_ALCOHOL_USE_DISORDERS.error")
    cat("ERROR")
})
