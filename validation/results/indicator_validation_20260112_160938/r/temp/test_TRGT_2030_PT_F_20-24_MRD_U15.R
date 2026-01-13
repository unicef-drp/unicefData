
library(unicefData)
tryCatch({
    df <- unicefData(
        indicator = "TRGT_2030_PT_F_20-24_MRD_U15",
        
        
    )
    
    if (nrow(df) > 0) {
        write.csv(df, "C:/GitHub/myados/unicefData/validation/results/indicator_validation_20260112_160938/r/success/TRGT_2030_PT_F_20-24_MRD_U15.csv", row.names = FALSE)
        cat(nrow(df))
    } else {
        cat("0")
    }
}, error = function(e) {
    writeLines(as.character(e$message), "C:/GitHub/myados/unicefData/validation/results/indicator_validation_20260112_160938/r/failed/TRGT_2030_PT_F_20-24_MRD_U15.error")
    cat("ERROR")
})
