#' Feature Sequence
#'
#' @param feature A feature variable.
#' @param len The feature sequence length if the feature variable is of class `numeric`.
#'
#' @return
sequence_feature <- function(feature, len) {
  switch(class(feature),
    numeric  = seq(min(feature), max(feature), length.out = len),
    factor   = factor(levels(feature)),
    stop("Invalid `feature` class")
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
  dplyr::mutate(data, {{ feature }} := feature_value)
}

#' Mean Predict
#'
#' @param object An object of class `model_fit`.
#' @param data A rectangular data object, such as a data frame.
#' @param class The class probability to predict if the object has mode classification.
#'
#' @return
calculate_mean_prediction <- function(object, data, class) {
  if (object$spec$mode == "regression") {
    parsnip::predict.model_fit(object, data) %>%
      dplyr::summarise(.mean_pred = mean(.pred))
  } else if (object$spec$mode == "classificatoin") {
    parsnip::predict.model_fit(object, data, type = "prob") %>%
      dplyr::summarise(.mean_pred = mean(names(.)[class]))
  } else {
    stop("Invalid `object` mode")
  }
}

#' Dependence Data
#'
#' @param object An object of class `model_fit`.
#' @param data A rectangular data object, such as a data frame.
#' @param feature A feature variable.
#' @param feature_len A length of the feature sequence if the object has mode regression.
#' @param class The class probability to predict if the object has mode classification.
#'
#' @return
#' @export
#'
#' @examples
estimate_dependence <- function(object, data, feature, len, class) {
  feature_values <- sequence_feature(dplyr::pull(data, {{ feature }}), len)
  purrr::map(feature_values, replace_feature, data = data, feature = {{ feature }}) %>%
    purrr::map_dfr(calculate_mean_prediction, object = object, class = class) %>%
    dplyr::bind_cols({{ feature }} := feature_values)
}

#' Plot Dependence
#'
#' @param object An object of class `model_fit`.
#' @param data A rectangular data object, such as a data frame.
#' @param feature A feature variable.
#' @param len The feature sequence length if the feature variable is of class `numeric`.
#' @param class The class probability to predict if the object has mode classification.
#' @param title A character string for the title.
#'
#' @return
#' @export
#'
#' @examples
plot_dependence <- function(object, data, feature, len = 40, class_prob = 1, title = "Partial Dependence Plot") {
  feature_class <- class(dplyr::pull(data, {{ feature }}))
  p <- ggplot2::ggplot(estimate_dependence(object, data, {{ feature }}, len, class))
  if (feature_class == "numeric") {
    p <- p +
      ggplot2::geom_line(ggplot2::aes(x = {{ feature }}, y = .mean_pred)) +
      ggplot2::geom_rug(ggplot2::aes(x = {{ feature }}), data = data)
  } else if (feature_class == "factor") {
    p <- p +
      ggplot2::geom_bar(ggplot2::aes(x = {{ feature }}, weight = .mean_pred)) +
      ggplot2::geom_rug(ggplot2::aes(x = {{ feature }}, y = 0), data = data, position = "jitter", sides = "b")
  }
  p + ggplot2::ylab(dplyr::if_else(object$spec$mode == "regression", "Predicted Target", "Predicted Probability")) +
      ggplot2::labs(title = title) +
      ggplot2::theme_grey()
}
