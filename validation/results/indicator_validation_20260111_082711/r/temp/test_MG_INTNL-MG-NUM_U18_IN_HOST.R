
library(unicefData)
tryCatch({
    df <- unicefData(
        indicator = "MG_INTNL-MG-NUM_U18_IN_HOST",
        
        
    )
    
    if (nrow(df) > 0) {
        write.csv(df, "C:/GitHub/myados/unicefData/validation/results/indicator_validation_20260111_082711/r/success/MG_INTNL-MG-NUM_U18_IN_HOST.csv", row.names = FALSE)
        cat(nrow(df))
    } else {
        cat("0")
    }
}, error = function(e) {
    writeLines(as.character(e$message), "C:/GitHub/myados/unicefData/validation/results/indicator_validation_20260111_082711/r/failed/MG_INTNL-MG-NUM_U18_IN_HOST.error")
    cat("ERROR")
})
