#' Permute Feature
#'
#' @param data A rectangular data object, such as a data frame.
#' @param feature A feature variable.
#'
#' @return
permute_feature <- function(data, feature) {
  dplyr::mutate(data, {{ feature }} := sample(!!sym(feature)))
}

#' Estimate Metric
#'
#' @param object An object of class `model_fit`.
#' @param data A rectangular data object, such as a data frame.
#' @param target The target variable.
#' @param metric A metric funtion from the `yardstick` package.
#'
#' @return
estimate_metric <- function(object, data, target, metric) {
  parsnip::predict.model_fit(object, data) %>%
    dplyr::bind_cols(data) %>%
    metric(truth = {{ target }}, estimate = dplyr::first(.)) %>%
    dplyr::select(.metric, .estimate)
}

#' Estimate Importance
#'
#' @param object An object of class `model_fit`.
#' @param data A rectangular data object, such as a data frame.
#' @param target The target variable.
#' @param metric A metric funtion from the `yardstick` package.
#'
#' @return
#' @export
#'
#' @examples
estimate_importance <- function(object, data, target, metric) {
  metric_data <- estimate_metric(object, data, {{ target }}, metric)
  features <- names(dplyr::select(data, -{{ target }}))
  purrr::map(features, permute_feature, data = data) %>%
    purrr::map_dfr(estimate_metric, object = object, target = {{ target }}, metric = metric) %>%
    dplyr::bind_cols(.feature = features) %>%
    dplyr::mutate(.importance = abs(.estimate - metric_data$.estimate)) %>%
    dplyr::select(.metric, .feature, .importance)
}

#' Plot Importance
#'
#' @param object An object of class model_fit.
#' @param data A rectangular data object, such as a data frame.
#' @param target The target variable.
#' @param metric A metric funtion from the `yardstick` package.
#' @param title A character string for the title.
#'
#' @return
#' @export
#'
#' @examples
plot_importance <- function(object, data, target, metric, title = "Permutation Importance Plot") {
  importance_data <- estimate_importance(object, data, {{ target }}, metric)
  metric_name <- importance_data$.metric[[1]]
  ggplot2::ggplot(importance_data) +
    ggplot2::geom_bar(ggplot2::aes(x = forcats::fct_reorder(.feature, .importance), weight = .importance)) +
    ggplot2::coord_flip() +
    ggplot2::labs(title = title) +
    ggplot2::xlab("Feature") +
    ggplot2::ylab(glue::glue('Importance ({ metric_name })')) +
    ggplot2::theme_grey()
}
