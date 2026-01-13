
library(unicefData)
tryCatch({
    df <- unicefData(
        indicator = "TRGT_2030_PT_M_18-29_SX-V_AGE-18",
        
        
    )
    
    if (nrow(df) > 0) {
        write.csv(df, "C:/GitHub/myados/unicefData/validation/results/indicator_validation_20260112_231042/r/success/TRGT_2030_PT_M_18-29_SX-V_AGE-18.csv", row.names = FALSE)
        cat(nrow(df))
    } else {
        cat("0")
    }
}, error = function(e) {
    writeLines(as.character(e$message), "C:/GitHub/myados/unicefData/validation/results/indicator_validation_20260112_231042/r/failed/TRGT_2030_PT_M_18-29_SX-V_AGE-18.error")
    cat("ERROR")
})
