#' Feature Permutation
#'
#' @param data data
#' @param feature_name feature_name
#'
#' @return
#' @export
#'
#' @examples
feature_permutation <- function(data, feature_name) {
  feature_name <- ensym(feature_name)
  dplyr::mutate(data, !!feature_name := sample(!!feature_name))
}

#' Object Metric
#'
#' @param object object
#' @param data data
#' @param target_name target_name
#'
#' @return
#' @export
#'
#' @examples
object_metric <- function(object, data, target_name) {
  target_name <- ensym(target_name)
  if (object$spec$mode == "regression") {
    parsnip::predict.model_fit(object, data) %>%
      dplyr::bind_cols(data) %>%
      yardstick::rmse(truth = !!target_name, estimate = .pred)
  } else if (object$spec$mode == "classification") {
    parsnip::predict.model_fit(object, data) %>%
      dplyr::bind_cols(data) %>%
      yardstick::accuracy(truth = !!target_name, estimate = .pred_class)
  }
}

#' Importance
#'
#' @param object object
#' @param data data
#' @param target_name target_name
#'
#' @return
#' @export
#'
#' @examples
importance <- function(object, data, target_name) {
  target_name <- ensym(target_name)
  metric <- object_metric(object, data, !!target_name)
  feature_names <- names(dplyr::select(data, -!!target_name))
  purrr::map(feature_names, feature_permutation, data = data) %>%
    purrr::map_dfr(object_metric, object = object, target_name = !!target_name) %>%
    dplyr::bind_cols(feature = feature_names) %>%
    dplyr::mutate(.estimate = abs(.estimate - metric$.estimate))
}

#' Importance Plot
#'
#' @param object object
#' @param data data
#' @param target_name target_name
#'
#' @return
#' @export
#'
#' @examples
importance_plot <- function(object, data, target_name) {
  importance(object, data, !!ensym(target_name)) %>%
    ggplot2::ggplot() +
    ggplot2::geom_bar(ggplot2::aes(x = forcats::fct_reorder(feature, .estimate, .desc = TRUE), weight = .estimate)) +
    ggplot2::xlab("Features") +
    ggplot2::ylab(dplyr::if_else(object$spec$mode == "regression", "Root Mean Square Error Drop", "Accuracy Drop"))
}
