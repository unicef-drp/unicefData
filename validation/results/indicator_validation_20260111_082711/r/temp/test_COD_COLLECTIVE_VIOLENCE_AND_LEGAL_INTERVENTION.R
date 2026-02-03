
library(unicefData)
tryCatch({
    df <- unicefData(
        indicator = "COD_COLLECTIVE_VIOLENCE_AND_LEGAL_INTERVENTION",
        
        
    )
    
    if (nrow(df) > 0) {
        write.csv(df, "C:/GitHub/myados/unicefData/validation/results/indicator_validation_20260111_082711/r/success/COD_COLLECTIVE_VIOLENCE_AND_LEGAL_INTERVENTION.csv", row.names = FALSE)
        cat(nrow(df))
    } else {
        cat("0")
    }
}, error = function(e) {
    writeLines(as.character(e$message), "C:/GitHub/myados/unicefData/validation/results/indicator_validation_20260111_082711/r/failed/COD_COLLECTIVE_VIOLENCE_AND_LEGAL_INTERVENTION.error")
    cat("ERROR")
})
