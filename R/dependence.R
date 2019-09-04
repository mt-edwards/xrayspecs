#' Feature Sequence
#'
#' @param feature A feature vector of class numeric or factor.
#' @param feature_len A length of the feature sequence if the object has mode regression.
#'
#' @return
feature_seq <- function(feature, feature_len) {
  switch(class(feature),
    numeric  = seq(min(feature), max(feature), length.out = feature_len),
    factor   = factor(levels(feature)),
    stop("Invalid `feature` class")
  )
}

#' Feature Replace
#'
#' @param new_data A rectangular data object, such as a data frame.
#' @param feature_name A feature name.
#' @param feature_value A feature value of class numeric or factor.
#'
#' @return
feature_replace <- function(new_data, feature_name, feature_value) {
  dplyr::mutate(new_data, !!ensym(feature_name) := feature_value)
}

#' Mean Predict
#'
#' @param object An object of class model_fit with mode regression or classification.
#' @param new_data A rectangular data object, such as a data frame.
#' @param class A class probability to predict if the object has mode classification.
#'
#' @return
mean_predict <- function(object, new_data, class) {
  if (object$spec$mode == "regression") {
    parsnip::predict.model_fit(object, new_data) %>%
      dplyr::summarise(.mean_pred = mean(.pred))
  } else if (object$spec$mode == "classificatoin") {
    parsnip::predict.model_fit(object, new_data, type = "prob") %>%
      dplyr::summarise(.mean_pred = mean(names(.)[class]))
  } else {
    stop("Invalid `object` mode")
  }
}

#' Dependence Data
#'
#' The dependence_data function generates a data frame of predictions from new_data that
#' correspond to changes in the values of feature_name.
#'
#' @param object An object of class model_fit.
#' @param new_data A rectangular data object, such as a data frame.
#' @param feature_name A feature name.
#' @param feature_len A length of the feature sequence if the object has mode regression.
#' @param class A class probability to predict if the object has mode classification.
#'
#' @return
#' @export
#'
#' @examples
dependence_data <- function(object, new_data, feature_name, feature_len, class) {
  feature_name <- ensym(feature_name)
  feature_values <- feature_seq(dplyr::pull(new_data, !!feature_name), feature_len)
  purrr::map(feature_values, feature_replace, new_data = new_data, feature_name = !!feature_name) %>%
    purrr::map_dfr(mean_predict, object = object, class = class) %>%
    dplyr::bind_cols(!!feature_name := feature_values)
}

#' Dependence Plot
#'
#' The dependence_plot function generates a plot of predictions from new_data that
#' correspond to changes in the values of feature_name.
#'
#' @param object An object of class model_fit.
#' @param new_data A rectangular data object, such as a data frame.
#' @param feature_name A feature name.
#' @param feature_len A length of the feature sequence if the object has mode regression.
#' @param class A class probability to predict if the object has mode classification.
#' @param title A character string for the title.
#'
#' @return
#' @export
#'
#' @examples
dependence_plot <- function(object, new_data, feature_name, feature_len = 40, class = 1, title = "Partial Dependence Plot") {
  feature_name <- ensym(feature_name)
  feature_class <- class(dplyr::pull(new_data, !!feature_name))
  p <- ggplot2::ggplot(dependence_data(object, new_data, !!feature_name, feature_len, class))
  if (feature_class == "numeric") {
    p <- p +
      ggplot2::geom_line(ggplot2::aes(x = !!feature_name, y = .mean_pred)) +
      ggplot2::geom_rug(ggplot2::aes(x = !!feature_name), data = new_data)
  } else if (feature_class == "factor") {
    p <- p +
      ggplot2::geom_bar(ggplot2::aes(x = !!feature_name, weight = .mean_pred)) +
      ggplot2::geom_rug(ggplot2::aes(x = !!feature_name, y = 0), data = new_data, position = "jitter", sides = "b")
  }
  p + ggplot2::ylab(dplyr::if_else(object$spec$mode == "regression", "Predicted Target", "Predicted Probability")) +
      ggplot2::labs(title = title) +
      ggplot2::theme_grey()
}
