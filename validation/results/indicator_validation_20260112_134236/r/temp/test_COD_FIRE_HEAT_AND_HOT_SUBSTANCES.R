
library(unicefData)
tryCatch({
    df <- unicefData(
        indicator = "COD_FIRE_HEAT_AND_HOT_SUBSTANCES",
        
        
    )
    
    if (nrow(df) > 0) {
        write.csv(df, "C:/GitHub/myados/unicefData/validation/results/indicator_validation_20260112_134236/r/success/COD_FIRE_HEAT_AND_HOT_SUBSTANCES.csv", row.names = FALSE)
        cat(nrow(df))
    } else {
        cat("0")
    }
}, error = function(e) {
    writeLines(as.character(e$message), "C:/GitHub/myados/unicefData/validation/results/indicator_validation_20260112_134236/r/failed/COD_FIRE_HEAT_AND_HOT_SUBSTANCES.error")
    cat("ERROR")
})
