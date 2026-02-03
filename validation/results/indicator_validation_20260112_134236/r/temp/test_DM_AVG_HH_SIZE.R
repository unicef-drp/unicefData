
library(unicefData)
tryCatch({
    df <- unicefData(
        indicator = "DM_AVG_HH_SIZE",
        
        
    )
    
    if (nrow(df) > 0) {
        write.csv(df, "C:/GitHub/myados/unicefData/validation/results/indicator_validation_20260112_134236/r/success/DM_AVG_HH_SIZE.csv", row.names = FALSE)
        cat(nrow(df))
    } else {
        cat("0")
    }
}, error = function(e) {
    writeLines(as.character(e$message), "C:/GitHub/myados/unicefData/validation/results/indicator_validation_20260112_134236/r/failed/DM_AVG_HH_SIZE.error")
    cat("ERROR")
})
