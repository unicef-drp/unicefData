
library(unicefData)
tryCatch({
    df <- unicefData(
        indicator = "COD_GALLBLADDER_AND_BILIARY_DISEASES",
        
        
    )
    
    if (nrow(df) > 0) {
        write.csv(df, "C:/GitHub/myados/unicefData/validation/results/indicator_validation_20260112_164439/r/success/COD_GALLBLADDER_AND_BILIARY_DISEASES.csv", row.names = FALSE)
        cat(nrow(df))
    } else {
        cat("0")
    }
}, error = function(e) {
    writeLines(as.character(e$message), "C:/GitHub/myados/unicefData/validation/results/indicator_validation_20260112_164439/r/failed/COD_GALLBLADDER_AND_BILIARY_DISEASES.error")
    cat("ERROR")
})
