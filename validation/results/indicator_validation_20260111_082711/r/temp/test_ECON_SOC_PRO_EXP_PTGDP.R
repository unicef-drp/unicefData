
library(unicefData)
tryCatch({
    df <- unicefData(
        indicator = "ECON_SOC_PRO_EXP_PTGDP",
        
        
    )
    
    if (nrow(df) > 0) {
        write.csv(df, "C:/GitHub/myados/unicefData/validation/results/indicator_validation_20260111_082711/r/success/ECON_SOC_PRO_EXP_PTGDP.csv", row.names = FALSE)
        cat(nrow(df))
    } else {
        cat("0")
    }
}, error = function(e) {
    writeLines(as.character(e$message), "C:/GitHub/myados/unicefData/validation/results/indicator_validation_20260111_082711/r/failed/ECON_SOC_PRO_EXP_PTGDP.error")
    cat("ERROR")
})
