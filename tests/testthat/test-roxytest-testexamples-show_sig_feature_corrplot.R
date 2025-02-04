# Generated by roxytest: Do not edit by hand!
# Last updated: 2020-04-16 22:59:16

context("File R/show_sig_feature_corrplot.R: @testexamples")

test_that("Function show_sig_feature_corrplot() @ L40", {
  
  
  # The data is generated from Wang, Shixiang et al.
  load(system.file("extdata", "asso_data.RData",
    package = "sigminer", mustWork = TRUE
  ))
  
  p <- show_sig_feature_corrplot(tidy_data.seqz.feature, p_val = 0.05)
  p
  expect_s3_class(p, "ggplot")
})

