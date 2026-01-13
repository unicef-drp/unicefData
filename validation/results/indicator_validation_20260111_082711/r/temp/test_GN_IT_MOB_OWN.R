
library(unicefData)
tryCatch({
    df <- unicefData(
        indicator = "GN_IT_MOB_OWN",
        
        
    )
    
    if (nrow(df) > 0) {
        write.csv(df, "C:/GitHub/myados/unicefData/validation/results/indicator_validation_20260111_082711/r/success/GN_IT_MOB_OWN.csv", row.names = FALSE)
        cat(nrow(df))
    } else {
        cat("0")
    }
}, error = function(e) {
    writeLines(as.character(e$message), "C:/GitHub/myados/unicefData/validation/results/indicator_validation_20260111_082711/r/failed/GN_IT_MOB_OWN.error")
    cat("ERROR")
})
