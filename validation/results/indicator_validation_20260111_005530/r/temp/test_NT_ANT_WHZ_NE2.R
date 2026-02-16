
library(unicefData)
tryCatch({
    df <- unicefData(
        indicator = "NT_ANT_WHZ_NE2",
        countries = c("USA", "BRA", "IND", "KEN", "CHN"),
        year = "2020"
    )
    
    if (nrow(df) > 0) {
        write.csv(df, "C:/GitHub/myados/unicefData/validation/results/indicator_validation_20260111_005530/r/success/NT_ANT_WHZ_NE2.csv", row.names = FALSE)
        cat(nrow(df))
    } else {
        cat("0")
    }
}, error = function(e) {
    writeLines(as.character(e$message), "C:/GitHub/myados/unicefData/validation/results/indicator_validation_20260111_005530/r/failed/NT_ANT_WHZ_NE2.error")
    cat("ERROR")
})
