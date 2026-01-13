
library(unicefData)
tryCatch({
    df <- unicefData(
        indicator = "MG_INTNL-MG-PCNT_T-POP",
        
        
    )
    
    if (nrow(df) > 0) {
        write.csv(df, "C:/GitHub/myados/unicefData/validation/results/indicator_validation_20260112_235844/r/success/MG_INTNL-MG-PCNT_T-POP.csv", row.names = FALSE)
        cat(nrow(df))
    } else {
        cat("0")
    }
}, error = function(e) {
    writeLines(as.character(e$message), "C:/GitHub/myados/unicefData/validation/results/indicator_validation_20260112_235844/r/failed/MG_INTNL-MG-PCNT_T-POP.error")
    cat("ERROR")
})
