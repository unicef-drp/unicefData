
library(unicefData)
tryCatch({
    df <- unicefData(
        indicator = "TRGT_2030_IM_HPV",
        
        
    )
    
    if (nrow(df) > 0) {
        write.csv(df, "C:/GitHub/myados/unicefData/validation/results/indicator_validation_20260112_235844/r/success/TRGT_2030_IM_HPV.csv", row.names = FALSE)
        cat(nrow(df))
    } else {
        cat("0")
    }
}, error = function(e) {
    writeLines(as.character(e$message), "C:/GitHub/myados/unicefData/validation/results/indicator_validation_20260112_235844/r/failed/TRGT_2030_IM_HPV.error")
    cat("ERROR")
})
