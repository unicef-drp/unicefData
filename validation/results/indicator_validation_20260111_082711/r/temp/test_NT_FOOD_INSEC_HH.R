
library(unicefData)
tryCatch({
    df <- unicefData(
        indicator = "NT_FOOD_INSEC_HH",
        
        
    )
    
    if (nrow(df) > 0) {
        write.csv(df, "C:/GitHub/myados/unicefData/validation/results/indicator_validation_20260111_082711/r/success/NT_FOOD_INSEC_HH.csv", row.names = FALSE)
        cat(nrow(df))
    } else {
        cat("0")
    }
}, error = function(e) {
    writeLines(as.character(e$message), "C:/GitHub/myados/unicefData/validation/results/indicator_validation_20260111_082711/r/failed/NT_FOOD_INSEC_HH.error")
    cat("ERROR")
})
