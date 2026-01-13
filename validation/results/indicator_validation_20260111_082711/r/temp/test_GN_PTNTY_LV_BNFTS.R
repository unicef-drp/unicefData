
library(unicefData)
tryCatch({
    df <- unicefData(
        indicator = "GN_PTNTY_LV_BNFTS",
        
        
    )
    
    if (nrow(df) > 0) {
        write.csv(df, "C:/GitHub/myados/unicefData/validation/results/indicator_validation_20260111_082711/r/success/GN_PTNTY_LV_BNFTS.csv", row.names = FALSE)
        cat(nrow(df))
    } else {
        cat("0")
    }
}, error = function(e) {
    writeLines(as.character(e$message), "C:/GitHub/myados/unicefData/validation/results/indicator_validation_20260111_082711/r/failed/GN_PTNTY_LV_BNFTS.error")
    cat("ERROR")
})
