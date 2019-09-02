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
#'
#' @return
mean_predict <- function(object, new_data) {
  if (object$spec$mode == "regression") {
    parsnip::predict.model_fit(object, new_data) %>%
      dplyr::summarise(.mean_pred = mean(.pred))
  } else if (object$spec$mode == "classification") {
    predict(object, new_data, type = "prob") %>%
      dplyr::summarise(.mean_pred = mean(.pred_1))
  }
}

#' Effect Data
#'
#' The effect_data function generates a data frame of prediction effects from new_data that
#' correspond to changes in the values of feature_name.
#'
#' @param object object
#' @param new_data new_data
#' @param feature_name feature_name
#'
#' @return
#' @export
#'
#' @examples
effect_data <- function(object, new_data, feature_name) {
  feature_name <- ensym(feature_name)
  fseq <- feature_seq(dplyr::pull(new_data, !!feature_name))
  purrr::map(fseq, feature_replace, new_data = new_data, feature_name = !!feature_name) %>%
    purrr::map_dfr(mean_predict, object = object) %>%
    dplyr::bind_cols(!!feature_name := fseq)
}

#' Effect Plot
#'
#' The effect_plot function generates a plot of prediction effects from new_data that
#' correspond to changes in the values of feature_name.
#'
#' @param object object
#' @param new_data new_data
#' @param feature_name feature_name
#'
#' @return
#' @export
#'
#' @examples
effect_plot <- function(object, new_data, feature_name) {
  feature_name <- ensym(feature_name)
  feature_class <- class(dplyr::pull(new_data, !!feature_name))
  effect_tbl <- effect_data(object, new_data, !!feature_name)
  if (feature_class == "numeric" & object$spec$mode == "regression") {
    ggplot2::ggplot(effect_tbl) +
    ggplot2::geom_line(ggplot2::aes(x = !!feature_name, y = .mean_pred)) +
    ggplot2::ylab("Prediction")
  } else if (feature_class == "numeric" & object$spec$mode == "classification") {
    ggplot2::ggplot(effect_tbl) +
    ggplot2::geom_line(ggplot2::aes(x = !!feature_name, y = .mean_pred)) +
    ggplot2::ylab("Prediction") +
    ggplot2::ylim(0, 1)
  } else if (feature_class == "factor" & object$spec$mode == "regression") {
    ggplot2::ggplot(effect_tbl) +
    ggplot2::geom_bar(ggplot2::aes(x = !!feature_name, weight = .mean_pred)) +
    ggplot2::ylab("Prediction")
  } else if (feature_class == "factor" & object$spec$mode == "classification") {
    ggplot2::ggplot(effect_tbl) +
    ggplot2::geom_bar(ggplot2::aes(x = !!feature_name, weight = .mean_pred)) +
    ggplot2::ylab("Prediction") +
    ggplot2::ylim(0, 1)
  }
}
