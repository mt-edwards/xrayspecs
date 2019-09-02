#' Feature Sequence
#'
#' @param feature feature
#' @param len len
#'
#' @return
feature_seq <- function(feature, len = 100) {
  if (class(feature) == "numeric") {
    seq(min(feature), max(feature), length.out = len)
  } else if (class(feature) == "factor") {
    factor(levels(feature))
  }
}

#' Feature Replace
#'
#' @param data data
#' @param feature_name feature_name
#' @param feature_value feature_value
#'
#' @return
feature_replace <- function(data, feature_name, feature_value) {
  dplyr::mutate(data, !!ensym(feature_name) := feature_value)
}

#' Mean Predict
#'
#' @param object object
#' @param data data
#'
#' @return
mean_predict <- function(object, data) {
  if (object$spec$mode == "regression") {
    parsnip::predict.model_fit(object, data) %>%
      dplyr::summarise(.mean_pred = mean(.pred))
  } else if (object$spec$mode == "classification") {
    predict(object, data, type = "prob") %>%
      dplyr::summarise(.mean_pred = mean(.pred_1))
  }
}

#' Effect
#'
#' @param object object
#' @param data data
#' @param feature_name feature_name
#'
#' @return
#' @export
#'
#' @examples
effect <- function(object, data, feature_name) {
  feature_name <- ensym(feature_name)
  fseq <- feature_seq(dplyr::pull(data, !!feature_name))
  purrr::map(fseq, feature_replace, data = data, feature_name = !!feature_name) %>%
    purrr::map_dfr(mean_predict, object = object) %>%
    dplyr::bind_cols(!!feature_name := fseq)
}

#' Effect Plot
#'
#' @param object object
#' @param data data
#' @param feature_name feature_name
#'
#' @return
#' @export
#'
#' @examples
effect_plot <- function(object, data, feature_name) {
  feature_name <- ensym(feature_name)
  feature_class <- class(dplyr::pull(data, !!feature_name))
  effect_data <- effect(object, data, !!feature_name)
  if (feature_class == "numeric" & object$spec$mode == "regression") {
    ggplot2::ggplot(effect_data) +
    ggplot2::geom_line(ggplot2::aes(x = !!feature_name, y = .mean_pred)) +
    ggplot2::ylab("Prediction")
  } else if (feature_class == "numeric" & object$spec$mode == "classification") {
    ggplot2::ggplot(effect_data) +
    ggplot2::geom_line(ggplot2::aes(x = !!feature_name, y = .mean_pred)) +
    ggplot2::ylab("Prediction") +
    ggplot2::ylim(0, 1)
  } else if (feature_class == "factor" & object$spec$mode == "regression") {
    ggplot2::ggplot(effect_data) +
    ggplot2::geom_bar(ggplot2::aes(x = !!feature_name, weight = .mean_pred)) +
    ggplot2::ylab("Prediction")
  } else if (feature_class == "factor" & object$spec$mode == "classification") {
    ggplot2::ggplot(effect_data) +
    ggplot2::geom_bar(ggplot2::aes(x = !!feature_name, weight = .mean_pred)) +
    ggplot2::ylab("Prediction") +
    ggplot2::ylim(0, 1)
  }
}
