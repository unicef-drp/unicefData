
library(unicefData)
tryCatch({
    df <- unicefData(
        indicator = "COD_IDIOPATHIC_INTELLECTUAL_DISABILITY",
        
        
    )
    
    if (nrow(df) > 0) {
        write.csv(df, "C:/GitHub/myados/unicefData/validation/results/indicator_validation_20260112_134236/r/success/COD_IDIOPATHIC_INTELLECTUAL_DISABILITY.csv", row.names = FALSE)
        cat(nrow(df))
    } else {
        cat("0")
    }
}, error = function(e) {
    writeLines(as.character(e$message), "C:/GitHub/myados/unicefData/validation/results/indicator_validation_20260112_134236/r/failed/COD_IDIOPATHIC_INTELLECTUAL_DISABILITY.error")
    cat("ERROR")
})
