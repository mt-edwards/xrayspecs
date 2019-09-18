#' Permute Feature
#'
#' @param data A rectangular data object, such as a data frame.
#' @param feature A feature variable.
#'
#' @return
permute_feature <- function(data, feature) {
  dplyr::mutate(data, {{feature}} := sample({{feature}}))
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
    metric(truth = {{target}}, estimate = dplyr::first(.)) %>%
    dplyr::select(.estimate)
}

#' Estimate Importance
#'
#' @param object An object of class `model_fit`.
#' @param data A rectangular data object, such as a data frame.
#' @param feature A feature variable.
#' @param target The target variable.
#' @param metric A metric funtion from the `yardstick` package.
#' @param sample_size The sample size used to estimate mean importance.
#'
#' @return
#' @export
#'
#' @examples
estimate_importance <- function(object, data, feature, target, metric, sample_size) {
  metric_data <- estimate_metric(object, data, {{target}}, metric)
  seq_len(sample_size) %>%
    purrr::map(~ permute_feature(data, {{feature}})) %>%
    purrr::map_dfr(estimate_metric,
      object = object,
      target = {{target}},
      metric = metric
    ) %>%
    dplyr::mutate(.importance = abs(.estimate - metric_data$.estimate)) %>%
    dplyr::summarise(
      .feature = rlang::as_string(ensym(feature)),
      .lower   = quantile(.importance, prob = 0.025),
      .mean    = mean(.importance),
      .upper   = quantile(.importance, prob = 0.975)
    )
}

#' Plot Importance
#'
#' @param object An object of class model_fit.
#' @param data A rectangular data object, such as a data frame.
#' @param target The target variable.
#' @param metric A metric funtion from the `yardstick` package.
#' @param sample_size The sample size used to estimate mean importance.
#'
#' @return
#' @export
#'
#' @examples
plot_importance <- function(object, data, target, metric, sample_size = 100) {
  syms(names(dplyr::select(data, -{{target}}))) %>%
    purrr::map_dfr(estimate_importance,
      object      = object,
      data        = data,
      target      = {{target}},
      metric      = metric,
      sample_size = sample_size
    ) %>%
    ggplot2::ggplot(ggplot2::aes(x = forcats::fct_reorder(.feature, .mean), y = .mean)) +
    ggplot2::geom_errorbar(ggplot2::aes(ymin = .lower, ymax = .upper), width = 0.3) +
    ggplot2::geom_point(size = 2) +
    ggplot2::coord_flip() +
    ggplot2::xlab("Feature") +
    ggplot2::ylab("Importance") +
    ggplot2::theme_grey()
}
