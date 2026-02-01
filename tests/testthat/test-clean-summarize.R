# tests/testthat/test-clean-summarize.R

library(testthat)
library(irisrap)

test_data <- iris

test_that("clean_iris filters species correctly", {
  cleaned_setosa <- clean_iris(test_data, species = "setosa")
  expect_equal(as.character(unique(cleaned_setosa$Species)), "setosa")  # coerce to character
  expect_equal(nrow(cleaned_setosa), 50)
})

test_that("summarize_by_species produces correct structure", {
  cleaned <- clean_iris(test_data)
  summary <- summarize_by_species(cleaned)
  expect_s3_class(summary, "tbl_df")
  expect_equal(ncol(summary), 10)  # Species + 8 (4 vars × 2) + n
  expect_equal(as.character(unique(summary$Species)), levels(test_data$Species))  # character comparison
})