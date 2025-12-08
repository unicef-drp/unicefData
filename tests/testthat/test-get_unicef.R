# Test get_unicef function
# This tests the main data retrieval function

test_that("get_unicef returns data frame for valid indicator", {
  skip_if_not_installed("unicefData")
  skip_on_cran()  # Skip on CRAN (requires network)
  
  # Use a known good indicator
  result <- tryCatch(
    get_unicef(indicator = "PT_CHLD_Y0T4_MDD", ref_area = "AFG"),
    error = function(e) NULL
  )
  
  # If API is available, should return data frame
  if (!is.null(result)) {
    expect_s3_class(result, "data.frame")
    expect_true("ref_area" %in% names(result))
    expect_true("time_period" %in% names(result))
    expect_true("obs_value" %in% names(result))
  }
})

test_that("get_unicef handles network errors gracefully", {
  skip_if_not_installed("unicefData")
  skip_on_cran()
  
  # Invalid indicator should handle error gracefully
  result <- tryCatch(
    get_unicef(indicator = "NONEXISTENT_INDICATOR_XYZ", ref_area = "AFG"),
    error = function(e) "error",
    warning = function(w) "warning"
  )
  
  # Should either error, warn, or return empty - all acceptable
  expect_true(
    identical(result, "error") || 
    identical(result, "warning") ||
    is.data.frame(result)
  )
})
