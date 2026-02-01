# R/clean_and_summarize.R
# Pure functions for iris analysis
#' @importFrom dplyr filter mutate across where group_by summarise n
#' @importFrom tidyr pivot_longer
#' @importFrom ggplot2 ggplot geom_boxplot facet_wrap theme_minimal aes labs
#' @importFrom rlang .data
NULL

#' Clean and filter iris data
#'
#' Filters the iris dataset to keep only specified species and imputes missing
#' numeric values with column means.
#'
#' @param data A data.frame with the structure of `iris` (must contain a `Species` column).
#' @param species Character vector of species to retain. Default is all unique species in the data.
#'
#' @return A cleaned data.frame with the same structure as input, but filtered and with NAs imputed.
#' @export
#' @examples
#' data(iris)
#' cleaned <- clean_iris(iris, species = c("setosa", "versicolor"))
#' head(cleaned)
clean_iris <- function(data, species = unique(data$Species)) {
  stopifnot(is.data.frame(data), "Species" %in% names(data))
  
  data |>
    dplyr::filter(Species %in% species) |>
    dplyr::mutate(across(where(is.numeric), ~ifelse(is.na(.), mean(., na.rm = TRUE), .)))
}

#' Summarize measurements by species
#'
#' Computes mean, standard deviation, and count for each numeric measurement grouped by species.
#'
#' @param data A cleaned data.frame (output of `clean_iris()` or similar).
#'
#' @return A tibble with one row per species and columns for mean/sd of each measurement plus count.
#' @export
summarize_by_species <- function(data) {
  stopifnot(is.data.frame(data), "Species" %in% names(data))
  
  data |>
    dplyr::group_by(Species) |>
    dplyr::summarise(
      across(where(is.numeric),
             list(mean = ~mean(., na.rm = TRUE),
                  sd   = ~sd(.,   na.rm = TRUE))),
      n = dplyr::n(),
      .groups = "drop"
    )
}

#' Plot boxplots of iris measurements by species
#'
#' Creates faceted boxplots for all numeric measurements, grouped by species.
#'
#' @param data A cleaned data.frame (output of `clean_iris()` or similar).
#'
#' @return A ggplot object (boxplots faceted by measurement).
#' @export
plot_iris_boxplots <- function(data) {
  stopifnot(is.data.frame(data))
  
  data_long <- data |>
    tidyr::pivot_longer(
      cols = where(is.numeric),
      names_to = "measurement",
      values_to = "value"
    )
  
  ggplot2::ggplot(data_long, ggplot2::aes(x = Species, y = value, fill = Species)) +
    ggplot2::geom_boxplot() +
    ggplot2::facet_wrap(~ measurement, scales = "free_y") +
    ggplot2::theme_minimal() +
    ggplot2::labs(title = "Iris Measurements by Species",
                  subtitle = "Boxplots of Sepal/Petal dimensions")
}