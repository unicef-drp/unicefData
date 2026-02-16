
library(unicefData)
tryCatch({
    df <- unicefData(
        indicator = "CME_MRM0",
        countries = c("USA", "BRA", "IND", "KEN", "CHN"),
        year = "2020"
    )
    
    if (nrow(df) > 0) {
        write.csv(df, "C:/GitHub/myados/unicefData/validation/results/indicator_validation_20260111_004809/r/success/CME_MRM0.csv", row.names = FALSE)
        cat(nrow(df))
    } else {
        cat("0")
    }
}, error = function(e) {
    writeLines(as.character(e$message), "C:/GitHub/myados/unicefData/validation/results/indicator_validation_20260111_004809/r/failed/CME_MRM0.error")
    cat("ERROR")
})
