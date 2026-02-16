
library(unicefData)
tryCatch({
    df <- unicefData(
        indicator = "FD_SEVER_PHY_PUNISH",
        
        
    )
    
    if (nrow(df) > 0) {
        write.csv(df, "C:/GitHub/myados/unicefData/validation/results/indicator_validation_20260111_082711/r/success/FD_SEVER_PHY_PUNISH.csv", row.names = FALSE)
        cat(nrow(df))
    } else {
        cat("0")
    }
}, error = function(e) {
    writeLines(as.character(e$message), "C:/GitHub/myados/unicefData/validation/results/indicator_validation_20260111_082711/r/failed/FD_SEVER_PHY_PUNISH.error")
    cat("ERROR")
})
