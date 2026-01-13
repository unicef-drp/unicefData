
library(unicefData)
tryCatch({
    df <- unicefData(
        indicator = "PV_PRO_PSS_EDU_BOTTOM20",
        
        
    )
    
    if (nrow(df) > 0) {
        write.csv(df, "C:/GitHub/myados/unicefData/validation/results/indicator_validation_20260113_002035/r/success/PV_PRO_PSS_EDU_BOTTOM20.csv", row.names = FALSE)
        cat(nrow(df))
    } else {
        cat("0")
    }
}, error = function(e) {
    writeLines(as.character(e$message), "C:/GitHub/myados/unicefData/validation/results/indicator_validation_20260113_002035/r/failed/PV_PRO_PSS_EDU_BOTTOM20.error")
    cat("ERROR")
})
