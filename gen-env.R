# gen-env.R
# This script generates default.nix using {rix}

library(rix)

rix(
  # Use a recent date from available_dates() – adjust if needed
  date = "2026-01-14",   # or run available_dates() and pick latest

  r_pkgs = c(
    "tidyverse",         # dplyr, ggplot2, readr, etc.
    "testthat",          # unit testing
    "languageserver",    # for editor integration
    "quarto"             # quarto CLI
  ),

  py_conf = list(
    py_version = "3.11",
    py_pkgs = c(
      "pandas",
      "seaborn",
      "matplotlib"
    )
  ),

  # No git repo yet → we set project_path to current directory
  project_path = ".",
  overwrite = TRUE,
  print = TRUE
)