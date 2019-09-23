#' Feature Sequence
#'
#' @param feature A feature variable.
#' @param len The feature sequence length if the feature variable is of class `numeric`.
#'
#' @return
sequence_feature <- function(feature, len) {
  switch(class(feature),
    numeric  = seq(min(feature), max(feature), length.out = len),
    factor   = factor(levels(feature))
  )
}

#' Replace Replace
#'
#' @param data A rectangular data object, such as a data frame.
#' @param feature A feature variable.
#' @param feature_value A feature variable value.
#'
#' @return
replace_feature <- function(data, feature, feature_value) {
  dplyr::mutate(data, {{feature}} := feature_value)
}

#' Calculate Prediction
#'
#' @param object An object of class `model_fit`.
#' @param data A rectangular data object, such as a data frame.
#' @param class The class probability to predict if the object has mode classification.
#'
#' @return
calculate_prediction <- function(object, data, class) {
  if (object$spec$mode == "regression") {
    parsnip::predict.model_fit(object, data)
  } else if (object$spec$mode == "classification") {
    parsnip::predict.model_fit(object, data, type = "prob") %>%
      dplyr::select(.pred = dplyr::pull(.data, class))
  }
}

#' Center Prediction
#'
#' @param data A rectangular data object, such as a data frame.
#'
#' @return
center_prediction <- function(data) {
  dplyr::mutate(data, .pred = .data$.pred - data[which.min(data[[2]]), 1, drop = TRUE])
}

#' Estimate Dependence
#'
#' @param object An object of class `model_fit`.
#' @param data A rectangular data object, such as a data frame.
#' @param feature A feature variable.
#' @param len A length of the feature sequence if the object has mode regression.
#' @param class The class probability to predict if the object has mode classification.
#' @param center Center the depedence plot on the first feature value.
#'
#' @return
#' @export
#'
#' @examples
estimate_dependence <- function(object, data, feature, len, class, center) {
  feature_values <- sequence_feature(dplyr::pull(data, {{feature}}), len)
  dependence_data <- purrr::map(feature_values, replace_feature, data = data, feature = {{feature}}) %>%
    purrr::map(calculate_prediction, object = object, class = class) %>%
    purrr::map2_dfr(feature_values, ~ dplyr::mutate(.x, {{feature}} := .y, example = row_number()))
  if (center) {
    dependence_data <- dependence_data %>%
      tidyr::nest(-.data$example) %>%
      dplyr::mutate(data = purrr::map(data, center_prediction)) %>%
      tidyr::unnest()
  }
  dependence_data
}

#' Plot Dependence
#'
#' @param object An object of class `model_fit`.
#' @param data A rectangular data object, such as a data frame.
#' @param feature A feature variable.
#' @param len The feature sequence length if the feature variable is of class `numeric`.
#' @param class The class probability to predict if the object has mode classification.
#' @param examples Display the dependence plot of all the examples.
#' @param center Center the depedence plot on the first feature value.
#'
#' @return
#' @export
#'
#' @examples
plot_dependence <- function(object, data, feature, len = 40, class = 1, examples = FALSE, center = FALSE) {
  feature_class <- class(dplyr::pull(data, {{feature}}))
  dependence_data <- estimate_dependence(object, data, {{feature}}, len, class, center)
  p <- dependence_data %>%
    dplyr::group_by({{feature}}) %>%
    dplyr::summarise(mean_pred = mean(.pred)) %>%
    ggplot2::ggplot()
  if (feature_class == "numeric") {
    if (examples) {
      p <- p + ggplot2::geom_line(ggplot2::aes(x = {{feature}}, y = .data$.pred, group = .data$example), dependence_data, col = "grey")
    }
    p <- p + ggplot2::geom_line(ggplot2::aes(x = {{feature}}, y = .data$mean_pred), size = 1)
  } else if (feature_class == "factor") {
    p <- p + ggplot2::geom_bar(ggplot2::aes(x = {{feature}}, weight = .data$mean_pred))
  }
  p +
    ggplot2::geom_rug(ggplot2::aes(x = {{feature}}, y = 0), data = data, position = "jitter", sides = "b") +
    ggplot2::ylab(dplyr::if_else(object$spec$mode == "regression", "Predicted Target", "Predicted Probability")) +
    ggplot2::theme_grey()
}
