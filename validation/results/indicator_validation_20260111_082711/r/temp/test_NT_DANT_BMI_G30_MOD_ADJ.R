
library(unicefData)
tryCatch({
    df <- unicefData(
        indicator = "NT_DANT_BMI_G30_MOD_ADJ",
        
        
    )
    
    if (nrow(df) > 0) {
        write.csv(df, "C:/GitHub/myados/unicefData/validation/results/indicator_validation_20260111_082711/r/success/NT_DANT_BMI_G30_MOD_ADJ.csv", row.names = FALSE)
        cat(nrow(df))
    } else {
        cat("0")
    }
}, error = function(e) {
    writeLines(as.character(e$message), "C:/GitHub/myados/unicefData/validation/results/indicator_validation_20260111_082711/r/failed/NT_DANT_BMI_G30_MOD_ADJ.error")
    cat("ERROR")
})
