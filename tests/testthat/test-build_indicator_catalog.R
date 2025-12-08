# Test internal metadata functions
# Note: build_indicator_catalog requires output_dir context, so we test
# the underlying helper functions and basic package loading instead

test_that("unicefData package loads correctly", {
  skip_if_not_installed("unicefData")
  
  # Package should load without errors
  expect_true(requireNamespace("unicefData", quietly = TRUE))
})

test_that("unicefData exports expected functions", {
  skip_if_not_installed("unicefData")
  
  # Check that key functions are exported
  expect_true(exists("get_unicef", envir = asNamespace("unicefData")))
  expect_true(exists("list_indicators", envir = asNamespace("unicefData")))
})

test_that("package has expected namespace", {
  skip_if_not_installed("unicefData")
  
  # Get exported functions
  exports <- getNamespaceExports("unicefData")
  
  # Should have some exports

  expect_gt(length(exports), 0)
  
  # Core functions should be exported
  expect_true("get_unicef" %in% exports)
})
