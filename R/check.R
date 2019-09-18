check_object <- function(object) {
  stopifnot(
    "model_fit" %in% class(object),
    object$spec$mode %in% c("classification", "regression")
  )
}

check_data <- function(data) {
  stopifnot(
    "data.frame" %in% class(data),
    all(purrr::map_chr(data, class) %in% c("factor", "numeric"))
  )
}

check_feature <- function(data, feature) {
  stopifnot(
    rlang::as_string(ensym(feature)) %in% names(data)
  )
}

check_target <- function(object, data, target) {
  check_feature(data, target)
  stopifnot(
    (object$spec$mode == "classification" & class(dplyr::pull(data, {{target}})) == "factor") |
      (object$spec$mode == "regression" & class(dplyr::pull(data, {{target}})) == "numeric")
  )
}
