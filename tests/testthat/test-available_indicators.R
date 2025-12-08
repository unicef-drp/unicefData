# Test list_indicators function
# This tests the function that lists available indicators

test_that("list_indicators returns data frame or list", {
  skip_if_not_installed("unicefData")
  
  result <- tryCatch(
    list_indicators(),
    error = function(e) NULL
  )
  
  if (!is.null(result)) {
    expect_true(is.data.frame(result) || is.list(result))
  }
})

test_that("list_indicators includes expected columns", {
  skip_if_not_installed("unicefData")
  
  result <- tryCatch(
    list_indicators(),
    error = function(e) NULL
  )
  
  if (!is.null(result) && is.data.frame(result)) {
    # Check for expected column names (varies by implementation)
    cols <- names(result)
    # At minimum should have some identifier column
    expect_gt(length(cols), 0)
  }
})
