
library(unicefData)
tryCatch({
    df <- unicefData(
        indicator = "PV_CHLD_DPRV-S-L1-HS",
        countries = c("USA", "BRA", "IND", "KEN", "CHN"),
        year = "2020"
    )
    
    if (nrow(df) > 0) {
        write.csv(df, "C:/GitHub/myados/unicefData/validation/results/indicator_validation_20260111_005530/r/success/PV_CHLD_DPRV-S-L1-HS.csv", row.names = FALSE)
        cat(nrow(df))
    } else {
        cat("0")
    }
}, error = function(e) {
    writeLines(as.character(e$message), "C:/GitHub/myados/unicefData/validation/results/indicator_validation_20260111_005530/r/failed/PV_CHLD_DPRV-S-L1-HS.error")
    cat("ERROR")
})
