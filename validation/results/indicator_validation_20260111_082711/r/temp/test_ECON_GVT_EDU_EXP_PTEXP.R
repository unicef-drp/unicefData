
library(unicefData)
tryCatch({
    df <- unicefData(
        indicator = "ECON_GVT_EDU_EXP_PTEXP",
        
        
    )
    
    if (nrow(df) > 0) {
        write.csv(df, "C:/GitHub/myados/unicefData/validation/results/indicator_validation_20260111_082711/r/success/ECON_GVT_EDU_EXP_PTEXP.csv", row.names = FALSE)
        cat(nrow(df))
    } else {
        cat("0")
    }
}, error = function(e) {
    writeLines(as.character(e$message), "C:/GitHub/myados/unicefData/validation/results/indicator_validation_20260111_082711/r/failed/ECON_GVT_EDU_EXP_PTEXP.error")
    cat("ERROR")
})
