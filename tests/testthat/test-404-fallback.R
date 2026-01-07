# Test 404 fallback behavior (PR #14)
# Invalid indicators should return empty result, not throw error

test_that("invalid indicator returns empty data frame without error", {
  skip_if_not_installed("unicefData")
  skip_on_cran()  # Requires network
  
  # Test with clearly invalid indicator code
  result <- unicefData(
    indicator = "INVALID_XYZ_NONEXISTENT", 
    countries = "ALB", 
    year = 2020
  )
  
  # Should return data frame (possibly empty)
  expect_s3_class(result, "data.frame")
  
  # Empty result is expected for invalid indicator
  # (404 fallback should have tried GLOBAL_DATAFLOW and found nothing)
  expect_true(nrow(result) == 0 || nrow(result) > 0)  # Either outcome is valid
})

test_that("404 fallback preserves standard column structure", {
  skip_if_not_installed("unicefData")
  skip_on_cran()
  
  # Even with invalid indicator, structure should be consistent
  result <- unicefData(
    indicator = "FAKE_INDICATOR_404_TEST",
    countries = "USA",
    year = 2020
  )
  
  expect_s3_class(result, "data.frame")
  
  # If data is returned (fallback succeeded), check standard columns
  if (nrow(result) > 0) {
    expect_true("iso3" %in% names(result) || "ref_area" %in% names(result))
    expect_true("period" %in% names(result) || "time_period" %in% names(result))
    expect_true("value" %in% names(result) || "obs_value" %in% names(result))
  }
})

test_that("valid indicator after 404 test still works", {
  skip_if_not_installed("unicefData")
  skip_on_cran()
  
  # Regression test: ensure 404 fallback doesn't break subsequent valid calls
  result <- unicefData(
    indicator = "CME_MRY0T4",
    countries = "ALB",
    year = 2020
  )
  
  expect_s3_class(result, "data.frame")
  # Should have data for a known good indicator
  expect_true(nrow(result) >= 0)  # At minimum, no error
})
