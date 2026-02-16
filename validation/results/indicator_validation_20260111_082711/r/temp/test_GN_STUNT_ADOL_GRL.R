
library(unicefData)
tryCatch({
    df <- unicefData(
        indicator = "GN_STUNT_ADOL_GRL",
        
        
    )
    
    if (nrow(df) > 0) {
        write.csv(df, "C:/GitHub/myados/unicefData/validation/results/indicator_validation_20260111_082711/r/success/GN_STUNT_ADOL_GRL.csv", row.names = FALSE)
        cat(nrow(df))
    } else {
        cat("0")
    }
}, error = function(e) {
    writeLines(as.character(e$message), "C:/GitHub/myados/unicefData/validation/results/indicator_validation_20260111_082711/r/failed/GN_STUNT_ADOL_GRL.error")
    cat("ERROR")
})
