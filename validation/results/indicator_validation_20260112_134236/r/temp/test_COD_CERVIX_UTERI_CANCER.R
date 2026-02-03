
library(unicefData)
tryCatch({
    df <- unicefData(
        indicator = "COD_CERVIX_UTERI_CANCER",
        
        
    )
    
    if (nrow(df) > 0) {
        write.csv(df, "C:/GitHub/myados/unicefData/validation/results/indicator_validation_20260112_134236/r/success/COD_CERVIX_UTERI_CANCER.csv", row.names = FALSE)
        cat(nrow(df))
    } else {
        cat("0")
    }
}, error = function(e) {
    writeLines(as.character(e$message), "C:/GitHub/myados/unicefData/validation/results/indicator_validation_20260112_134236/r/failed/COD_CERVIX_UTERI_CANCER.error")
    cat("ERROR")
})
