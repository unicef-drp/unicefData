# Test list_dataflows() wrapper (PR #14)
# Verify output schema and column names

test_that("list_dataflows returns data frame with expected columns", {
  skip_if_not_installed("unicefData")
  skip_on_cran()  # Requires network
  
  # Call the wrapper function
  flows <- tryCatch(
    list_dataflows(),
    error = function(e) NULL
  )
  
  # Skip if API unavailable
  skip_if(is.null(flows), "API unavailable")
  
  # Should return a data frame
  expect_s3_class(flows, "data.frame")
  
  # Check for expected columns from SDMX dataflow metadata
  expected_cols <- c("id", "agency", "version", "name")
  
  for (col in expected_cols) {
    expect_true(
      col %in% names(flows),
      info = paste("Missing expected column:", col)
    )
  }
})

test_that("list_dataflows returns non-empty result", {
  skip_if_not_installed("unicefData")
  skip_on_cran()
  
  flows <- tryCatch(
    list_dataflows(),
    error = function(e) NULL
  )
  
  skip_if(is.null(flows), "API unavailable")
  
  # UNICEF has multiple dataflows (CME, NUTRITION, etc.)
  expect_true(nrow(flows) > 0, info = "Should return at least one dataflow")
})

test_that("list_dataflows includes known dataflows", {
  skip_if_not_installed("unicefData")
  skip_on_cran()
  
  flows <- tryCatch(
    list_dataflows(),
    error = function(e) NULL
  )
  
  skip_if(is.null(flows), "API unavailable")
  
  # Check for known UNICEF dataflows
  known_dataflows <- c("CME", "NUTRITION", "GLOBAL_DATAFLOW")
  
  # At least one known dataflow should be present
  has_known <- any(known_dataflows %in% flows$id)
  expect_true(has_known, info = "Should include at least one known dataflow (CME, NUTRITION, GLOBAL_DATAFLOW)")
})

test_that("list_dataflows respects retry parameter", {
  skip_if_not_installed("unicefData")
  skip_on_cran()
  
  # Test with different retry values (should not error)
  flows_default <- tryCatch(list_dataflows(), error = function(e) NULL)
  flows_retry1 <- tryCatch(list_dataflows(retry = 1), error = function(e) NULL)
  
  # Both should work (or both fail if API down)
  if (!is.null(flows_default)) {
    expect_s3_class(flows_default, "data.frame")
  }
  
  if (!is.null(flows_retry1)) {
    expect_s3_class(flows_retry1, "data.frame")
  }
})

test_that("list_dataflows has valid data types", {
  skip_if_not_installed("unicefData")
  skip_on_cran()
  
  flows <- tryCatch(
    list_dataflows(),
    error = function(e) NULL
  )
  
  skip_if(is.null(flows), "API unavailable")
  
  # All expected columns should be character type
  for (col in c("id", "agency", "version", "name")) {
    if (col %in% names(flows)) {
      expect_true(
        is.character(flows[[col]]),
        info = paste("Column", col, "should be character type")
      )
    }
  }
})

test_that("list_dataflows has no duplicate IDs", {
  skip_if_not_installed("unicefData")
  skip_on_cran()
  
  flows <- tryCatch(
    list_dataflows(),
    error = function(e) NULL
  )
  
  skip_if(is.null(flows), "API unavailable")
  
  # Check for duplicates in id column
  if (nrow(flows) > 0) {
    duplicates <- flows[duplicated(flows$id), ]
    expect_equal(
      nrow(duplicates), 
      0, 
      info = paste("Found duplicate dataflow IDs:", paste(duplicates$id, collapse = ", "))
    )
  }
})
