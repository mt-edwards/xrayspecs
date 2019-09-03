#' Feature Sequence
#'
#' @param feature feature
#'
#' @return
feature_seq <- function(feature) {
  switch(class(feature),
    numeric  = seq(min(feature), max(feature), length.out = 100),
    factor   = factor(levels(feature)),
    stop("Invalid `feature` class")
  )
}

#' Feature Replace
#'
#' @param new_data new_data
#' @param feature_name feature_name
#' @param feature_value feature_value
#'
#' @return
feature_replace <- function(new_data, feature_name, feature_value) {
  dplyr::mutate(new_data, !!ensym(feature_name) := feature_value)
}

#' Mean Predict
#'
#' @param object object
#' @param new_data new_data
#' @param class class
#'
#' @return
mean_predict <- function(object, new_data, class) {
  if (object$spec$mode == "regression") {
    parsnip::predict.model_fit(object, new_data) %>%
      dplyr::summarise(.mean_pred = mean(.pred))
  } else {
    predict(object, new_data, type = "prob") %>%
      dplyr::summarise(.mean_pred = mean(names(.)[class]))
  }
}

#' Dependence Data
#'
#' The dependence_data function generates a data frame of predictions from new_data that
#' correspond to changes in the values of feature_name.
#'
#' @param object object
#' @param new_data new_data
#' @param feature_name feature_name
#' @param class class
#'
#' @return
#' @export
#'
#' @examples
dependence_data <- function(object, new_data, feature_name, class) {
  feature_name <- ensym(feature_name)
  feature_values <- feature_seq(dplyr::pull(new_data, !!feature_name))
  purrr::map(feature_values, feature_replace, new_data = new_data, feature_name = !!feature_name) %>%
    purrr::map_dfr(mean_predict, object = object, class = class) %>%
    dplyr::bind_cols(!!feature_name := feature_values)
}

#' Dependence Plot
#'
#' The dependence_plot function generates a plot of predictions from new_data that
#' correspond to changes in the values of feature_name.
#'
#' @param object object
#' @param new_data new_data
#' @param feature_name feature_name
#' @param class class
#' @param title title
#' @param subtitle subtitle
#'
#' @return
#' @export
#'
#' @examples
dependence_plot <- function(object, new_data, feature_name, class = 1, title = "Partial Dependence Plot", subtitle = NULL) {
  feature_name <- ensym(feature_name)
  feature_class <- class(dplyr::pull(new_data, !!feature_name))
  p <- ggplot2::ggplot(dependence_data(object, new_data, !!feature_name, class))
  if (feature_class == "numeric") {
    p <- p +
      ggplot2::geom_line(ggplot2::aes(x = !!feature_name, y = .mean_pred)) +
      ggplot2::geom_rug(ggplot2::aes(x = !!feature_name), data = new_data)
  } else if (feature_class == "factor") {
    p <- p +
      ggplot2::geom_bar(ggplot2::aes(x = !!feature_name, weight = .mean_pred)) +
      ggplot2::geom_rug(ggplot2::aes(x = !!feature_name, y = 0), data = new_data, position = "jitter", sides = "b")
  }
  if (object$spec$mode == "regression") {
    p <- p +
      ggplot2::ylab("Predicted Target")
  } else {
    p <- p +
      ggplot2::ylab("Predicted Probability") +
      ggplot2::ylim(0, 1)
  }
  p + ggplot2::labs(title = title, subtitle = subtitle) +
      ggplot2::theme_grey()
}
