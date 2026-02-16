
library(unicefData)
tryCatch({
    df <- unicefData(
        indicator = "PT_CHLD_1-14_PS-PSY-V_CGVR",
        countries = c("USA", "BRA", "IND", "KEN", "CHN"),
        year = "2020"
    )
    
    if (nrow(df) > 0) {
        write.csv(df, "C:/GitHub/myados/unicefData/validation/results/indicator_validation_20260111_005530/r/success/PT_CHLD_1-14_PS-PSY-V_CGVR.csv", row.names = FALSE)
        cat(nrow(df))
    } else {
        cat("0")
    }
}, error = function(e) {
    writeLines(as.character(e$message), "C:/GitHub/myados/unicefData/validation/results/indicator_validation_20260111_005530/r/failed/PT_CHLD_1-14_PS-PSY-V_CGVR.error")
    cat("ERROR")
})
