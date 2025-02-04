#' Get Signature Exposure from 'Signature' Object
#'
#' @param Signature a `Signature` object obtained either from [sig_extract] or [sig_auto_extract],
#' or just a raw exposure matrix with column representing samples (patients) and row
#' representing signatures.
#' @param type 'absolute' for signature exposure and 'relative' for signature relative exposure.
#' @param rel_threshold used when type is 'relative', relative exposure less
#' than this value will be set to 0 and the remaining signature exposure will be scaled
#' to make sum as 1 accordingly. Of note, this is a little different from the
#' same parameter in [sig_fit].
#' @return a `data.table`
#' @author Shixiang Wang <w_shixiang@163.com>
#' @export
#'
#' @examples
#' # Load mutational signature
#' load(system.file("extdata", "toy_mutational_signature.RData",
#'   package = "sigminer", mustWork = TRUE
#' ))
#' # Get signature exposure
#' expo1 <- get_sig_exposure(sig2)
#' expo1
#' expo2 <- get_sig_exposure(sig2, type = "relative")
#' expo2
#' @testexamples
#' expect_equal(nrow(expo1), 188L)
#' expect_equal(nrow(expo2), 186L)
get_sig_exposure <- function(Signature,
                             type = c("absolute", "relative"),
                             rel_threshold = 0.01) {
  if (class(Signature) == "Signature") {
    h <- Signature$Exposure
  } else if (is.matrix(Signature)) {
    if (!all(startsWith(rownames(Signature), "Sig"))) {
      stop("If Signature is a matrix, row names must start with 'Sig'!", call. = FALSE)
    }
    h <- Signature
  } else {
    stop("Invalid input for 'Signature'", call. = FALSE)
  }

  if (is.null(rownames(h)) | is.null(colnames(h))) {
    stop("Rownames or Colnames cannot be NULL!")
  }

  type <- match.arg(type)

  if (type == "absolute") {
    h <- t(h) %>%
      as.data.frame() %>%
      tibble::rownames_to_column(var = "sample") %>%
      data.table::as.data.table()
    return(h)
  } else {
    h.norm <- apply(h, 2, function(x) x / sum(x))
    h.norm <- t(h.norm) %>%
      as.data.frame() %>%
      tibble::rownames_to_column(var = "sample") %>%
      dplyr::mutate_at(
        dplyr::vars(dplyr::starts_with("Sig")),
        ~ ifelse(. < rel_threshold, 0, .)
      ) %>%
      dplyr::mutate(sum = rowSums(.[-1])) %>%
      dplyr::mutate_at(
        dplyr::vars(dplyr::starts_with("Sig")),
        ~ . / .data$sum
      ) %>%
      dplyr::select(-.data$sum)

    na_data <- h.norm %>%
      dplyr::filter(is.na(.data$Sig1))

    if (nrow(na_data) > 0) {
      message("Filtering the samples with no signature exposure:")
      message(paste(na_data$sample, collapse = " "))
    }

    h.norm <- h.norm %>%
      dplyr::filter(!is.na(.data$Sig1)) %>%
      data.table::as.data.table()

    return(h.norm)
  }
}
