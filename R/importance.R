#' Feature Permutation
#'
#' @param new_data new_data
#' @param feature_name feature_name
#'
#' @return
feature_permutation <- function(new_data, feature_name) {
  feature_name <- ensym(feature_name)
  dplyr::mutate(new_data, !!feature_name := sample(!!feature_name))
}

#' Object Metric
#'
#' @param object object
#' @param new_data new_data
#' @param target_name target_name
#'
#' @return
object_metric <- function(object, new_data) {
  if (object$spec$mode == "regression") {
    parsnip::predict.model_fit(object, new_data) %>%
      dplyr::bind_cols(new_data) %>%
      yardstick::mae(truth = !!sym(object$preproc$y_var), estimate = .pred)
  } else {
    parsnip::predict.model_fit(object, new_data) %>%
      dplyr::bind_cols(new_data) %>%
      yardstick::accuracy(truth = !!sym(object$preproc$y_var), estimate = .pred_class)
  }
}

#' Importance Data
#'
#' The importance_data function generates a data frame of permutation importance
#' values for each of the features in new_data.
#'
#' @param object object
#' @param new_data new_data
#' @param target_name target_name
#'
#' @return
#' @export
#'
#' @examples
importance_data <- function(object, new_data) {
  metric <- object_metric(object, new_data)
  feature_names <- names(dplyr::select(new_data, -!!sym(object$preproc$y_var)))
  purrr::map(feature_names, feature_permutation, new_data = new_data) %>%
    purrr::map_dfr(object_metric, object = object) %>%
    dplyr::bind_cols(.feature = feature_names) %>%
    dplyr::mutate(.estimate = abs(.estimate - metric$.estimate))
}

#' Importance Plot
#'
#' The importance_plot function generates a plot of permutation importance
#' values for each of the features in new_data.
#'
#' @param object object
#' @param new_data new_data
#' @param title title
#' @param subtitle subtitle
#'
#' @return
#' @export
#'
#' @examples
importance_plot <- function(object, new_data,  title = "Permutation Importance Plot", subtitle = NULL) {
  importance_data(object, new_data) %>%
    ggplot2::ggplot() +
    ggplot2::geom_bar(ggplot2::aes(x = forcats::fct_reorder(.feature, .estimate), weight = .estimate)) +
    ggplot2::coord_flip() +
    ggplot2::labs(title = title, subtitle = subtitle) +
    ggplot2::xlab("Features") +
    ggplot2::ylab(dplyr::if_else(object$spec$mode == "regression", "Importance (MAE)", "Importance (accuracy)")) +
    ggplot2::theme_grey()
}
