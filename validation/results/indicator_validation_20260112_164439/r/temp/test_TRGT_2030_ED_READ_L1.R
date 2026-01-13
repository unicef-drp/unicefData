
library(unicefData)
tryCatch({
    df <- unicefData(
        indicator = "TRGT_2030_ED_READ_L1",
        
        
    )
    
    if (nrow(df) > 0) {
        write.csv(df, "C:/GitHub/myados/unicefData/validation/results/indicator_validation_20260112_164439/r/success/TRGT_2030_ED_READ_L1.csv", row.names = FALSE)
        cat(nrow(df))
    } else {
        cat("0")
    }
}, error = function(e) {
    writeLines(as.character(e$message), "C:/GitHub/myados/unicefData/validation/results/indicator_validation_20260112_164439/r/failed/TRGT_2030_ED_READ_L1.error")
    cat("ERROR")
})
