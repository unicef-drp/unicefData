
library(unicefData)
tryCatch({
    df <- unicefData(
        indicator = "DM_NET_MG_RATE",
        
        
    )
    
    if (nrow(df) > 0) {
        write.csv(df, "C:/GitHub/myados/unicefData/validation/results/indicator_validation_20260111_082711/r/success/DM_NET_MG_RATE.csv", row.names = FALSE)
        cat(nrow(df))
    } else {
        cat("0")
    }
}, error = function(e) {
    writeLines(as.character(e$message), "C:/GitHub/myados/unicefData/validation/results/indicator_validation_20260111_082711/r/failed/DM_NET_MG_RATE.error")
    cat("ERROR")
})
