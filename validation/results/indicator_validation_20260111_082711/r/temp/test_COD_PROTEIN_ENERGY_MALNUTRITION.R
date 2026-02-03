
library(unicefData)
tryCatch({
    df <- unicefData(
        indicator = "COD_PROTEIN_ENERGY_MALNUTRITION",
        
        
    )
    
    if (nrow(df) > 0) {
        write.csv(df, "C:/GitHub/myados/unicefData/validation/results/indicator_validation_20260111_082711/r/success/COD_PROTEIN_ENERGY_MALNUTRITION.csv", row.names = FALSE)
        cat(nrow(df))
    } else {
        cat("0")
    }
}, error = function(e) {
    writeLines(as.character(e$message), "C:/GitHub/myados/unicefData/validation/results/indicator_validation_20260111_082711/r/failed/COD_PROTEIN_ENERGY_MALNUTRITION.error")
    cat("ERROR")
})
