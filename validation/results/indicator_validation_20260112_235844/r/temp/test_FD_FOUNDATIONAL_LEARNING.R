
library(unicefData)
tryCatch({
    df <- unicefData(
        indicator = "FD_FOUNDATIONAL_LEARNING",
        
        
    )
    
    if (nrow(df) > 0) {
        write.csv(df, "C:/GitHub/myados/unicefData/validation/results/indicator_validation_20260112_235844/r/success/FD_FOUNDATIONAL_LEARNING.csv", row.names = FALSE)
        cat(nrow(df))
    } else {
        cat("0")
    }
}, error = function(e) {
    writeLines(as.character(e$message), "C:/GitHub/myados/unicefData/validation/results/indicator_validation_20260112_235844/r/failed/FD_FOUNDATIONAL_LEARNING.error")
    cat("ERROR")
})
