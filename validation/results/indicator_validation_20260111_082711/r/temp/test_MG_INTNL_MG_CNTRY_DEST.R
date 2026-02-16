
library(unicefData)
tryCatch({
    df <- unicefData(
        indicator = "MG_INTNL_MG_CNTRY_DEST",
        
        
    )
    
    if (nrow(df) > 0) {
        write.csv(df, "C:/GitHub/myados/unicefData/validation/results/indicator_validation_20260111_082711/r/success/MG_INTNL_MG_CNTRY_DEST.csv", row.names = FALSE)
        cat(nrow(df))
    } else {
        cat("0")
    }
}, error = function(e) {
    writeLines(as.character(e$message), "C:/GitHub/myados/unicefData/validation/results/indicator_validation_20260111_082711/r/failed/MG_INTNL_MG_CNTRY_DEST.error")
    cat("ERROR")
})
