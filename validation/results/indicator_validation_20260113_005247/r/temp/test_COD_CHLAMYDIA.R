
library(unicefData)
tryCatch({
    df <- unicefData(
        indicator = "COD_CHLAMYDIA",
        
        
    )
    
    if (nrow(df) > 0) {
        write.csv(df, "C:/GitHub/myados/unicefData/validation/results/indicator_validation_20260113_005247/r/success/COD_CHLAMYDIA.csv", row.names = FALSE)
        cat(nrow(df))
    } else {
        cat("0")
    }
}, error = function(e) {
    writeLines(as.character(e$message), "C:/GitHub/myados/unicefData/validation/results/indicator_validation_20260113_005247/r/failed/COD_CHLAMYDIA.error")
    cat("ERROR")
})
