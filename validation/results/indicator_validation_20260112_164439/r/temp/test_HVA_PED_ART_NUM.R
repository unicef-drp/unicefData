
library(unicefData)
tryCatch({
    df <- unicefData(
        indicator = "HVA_PED_ART_NUM",
        
        
    )
    
    if (nrow(df) > 0) {
        write.csv(df, "C:/GitHub/myados/unicefData/validation/results/indicator_validation_20260112_164439/r/success/HVA_PED_ART_NUM.csv", row.names = FALSE)
        cat(nrow(df))
    } else {
        cat("0")
    }
}, error = function(e) {
    writeLines(as.character(e$message), "C:/GitHub/myados/unicefData/validation/results/indicator_validation_20260112_164439/r/failed/HVA_PED_ART_NUM.error")
    cat("ERROR")
})
