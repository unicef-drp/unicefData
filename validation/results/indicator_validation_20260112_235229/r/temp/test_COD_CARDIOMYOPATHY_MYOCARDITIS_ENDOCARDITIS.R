
library(unicefData)
tryCatch({
    df <- unicefData(
        indicator = "COD_CARDIOMYOPATHY_MYOCARDITIS_ENDOCARDITIS",
        
        
    )
    
    if (nrow(df) > 0) {
        write.csv(df, "C:/GitHub/myados/unicefData/validation/results/indicator_validation_20260112_235229/r/success/COD_CARDIOMYOPATHY_MYOCARDITIS_ENDOCARDITIS.csv", row.names = FALSE)
        cat(nrow(df))
    } else {
        cat("0")
    }
}, error = function(e) {
    writeLines(as.character(e$message), "C:/GitHub/myados/unicefData/validation/results/indicator_validation_20260112_235229/r/failed/COD_CARDIOMYOPATHY_MYOCARDITIS_ENDOCARDITIS.error")
    cat("ERROR")
})
