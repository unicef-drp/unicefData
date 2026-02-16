
library(unicefData)
tryCatch({
    df <- unicefData(
        indicator = "ED_PUP_PER_READ_BOOK",
        
        
    )
    
    if (nrow(df) > 0) {
        write.csv(df, "C:/GitHub/myados/unicefData/validation/results/indicator_validation_20260111_082711/r/success/ED_PUP_PER_READ_BOOK.csv", row.names = FALSE)
        cat(nrow(df))
    } else {
        cat("0")
    }
}, error = function(e) {
    writeLines(as.character(e$message), "C:/GitHub/myados/unicefData/validation/results/indicator_validation_20260111_082711/r/failed/ED_PUP_PER_READ_BOOK.error")
    cat("ERROR")
})
