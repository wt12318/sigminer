## Other implementation: https://github.com/kgori/sigfit/blob/209776ee1d2193ad4b682b2e2472f848bd7c67a6/R/sigfit_plotting.R#L688-L949

#' Show Signature Profile
#'
#' Who don't like to show a barplot for signature profile? This is for it.
#'
#' @inheritParams sig_extract
#' @inheritParams show_cn_distribution
#' @param Signature a `Signature` object obtained either from [sig_extract] or [sig_auto_extract],
#' or just a raw signature matrix with row representing components (motifs) and column
#' representing signatures (column names must start with 'Sig').
#' @param mode signature type for plotting, now supports 'copynumber' or 'SBS'.
#' @param method method for copy number feature classfication in [sig_tally],
#' can be one of "Macintyre" ("M") and "Wang" ("W").
#' @param normalize one of 'row', 'column', 'raw' and "feature", for row normalization (signature),
#' column normalization (component), raw data, row normalization by feature, respectively.
#' Of note, 'feature' only works when the mode is 'copynumber'.
#' @param filters a pattern used to select components to plot.
#' @param style plot style, one of 'default' and 'cosmic', works when
#' parameter `set_gradient_color` is `FALSE`.
#' @param palette palette used to plot when `set_gradient_color` is `FALSE`,
#' default use a built-in palette according to parameter `style`.
#' @param set_gradient_color default is `FALSE`, if `TRUE`, use gradient colors
#' to fill bars.
#' **This is very useful when signatures are extracted from "Macintyre" method and `normalize` is 'column'.**
#' @param free_space default is 'free_x'. If "fixed", all panels have the same size.
#' If "free_y" their height will be proportional to the length of the y scale;
#' if "free_x" their width will be proportional to the length of the x scale;
#' or if "free" both height and width will vary.
#' This setting has no effect unless the appropriate scales also vary.
#' @param rm_panel_border default is `TRUE` for style 'cosmic',
#' remove panel border to keep plot tight.
#' @param rm_grid_line default is `FALSE`, if `TRUE`, remove grid lines of plot.
#' @param bar_border_color the color of bar border.
#' @param bar_width bar width. By default, set to 70% of the resolution of the
#' data.
#' @param paint_axis_text if `TRUE`, color on text of x axis.
#' @param x_label_angle font angle for x label.
#' @param x_label_vjust font vjust for x label.
#' @param x_label_hjust font hjust for x label.
#' @param x_lab x axis lab.
#' @param y_lab y axis lab.
#' @param params params `data.frame` of components, obtained from [sig_tally].
#' @param show_cv default is `FALSE`, if `TRUE`, show coefficient of variation when
#' `params` is not `NULL`.
#' @param params_label_size font size for params label.
#' @param params_label_angle font angle for params label.
#' @param y_expand y expand height for plotting params of copy number signatures.
#' @param digits digits for plotting params of copy number signatures.
#' @param font_scale a number used to set font scale.
#' @param sig_names set name of signatures, can be a character vector.
#' Default is `NULL`, prefix 'Sig_' plus number is used.
#' @param sig_orders set order of signatures, can be a character vector.
#' Default is `NULL`, the signatures are ordered by alphabetical order.
#' @param check_sig_names if `TRUE`, check signature names when input is
#' a matrix, i.e., all signatures (colnames) must start with 'Sig'.
#' @author Shixiang Wang
#' @inheritParams sig_tally
#' @return a `ggplot` object
#' @export
#' @examples
#' # Load SBS signature
#' load(system.file("extdata", "toy_mutational_signature.RData",
#'   package = "sigminer", mustWork = TRUE
#' ))
#' # Show signature profile
#' p1 <- show_sig_profile(sig2, mode = "SBS")
#' p1
#'
#' # Load copy number signature from method "W"
#' load(system.file("extdata", "toy_copynumber_signature_by_W.RData",
#'   package = "sigminer", mustWork = TRUE
#' ))
#' # Show signature profile
#' p2 <- show_sig_profile(sig,
#'   style = "cosmic",
#'   mode = "copynumber",
#'   method = "W",
#'   normalize = "feature"
#' )
#' p2
#'
#' # Load copy number signature from method "M"
#' load(system.file("extdata", "toy_copynumber_signature_by_M.RData",
#'   package = "sigminer", mustWork = TRUE
#' ))
#' # Show signature profile
#' # The 'column' normalization is consistent with
#' # original paper
#' p3 <- show_sig_profile(sig,
#'   paint_axis_text = FALSE,
#'   mode = "copynumber",
#'   method = "M", normalize = "column"
#' )
#' p3
#'
#' # Add params label
#' # =================
#' # Load copy number prepare object
#' load(system.file("extdata", "toy_copynumber_tally_M.RData",
#'   package = "sigminer", mustWork = TRUE
#' ))
#' params <- get_tidy_parameter(cn_tally_M$components)
#' p4 <- show_sig_profile(sig,
#'   mode = "copynumber",
#'   method = "M", normalize = "column",
#'   params = params, y_expand = 2
#' )
#' p4
#' @testexamples
#' expect_s3_class(p1, "ggplot")
#' expect_s3_class(p2, "ggplot")
#' expect_s3_class(p3, "ggplot")
#' expect_s3_class(p4, "ggplot")
show_sig_profile <- function(Signature, mode = c("SBS", "copynumber"),
                             method = "Wang",
                             normalize = c("row", "column", "raw", "feature"),
                             filters = NULL,
                             feature_setting = sigminer::CN.features,
                             style = c("default", "cosmic"),
                             palette = use_color_style(style),
                             set_gradient_color = FALSE,
                             free_space = "free_x",
                             rm_panel_border = style == "cosmic",
                             rm_grid_line = FALSE,
                             bar_border_color = ifelse(style == "default", "grey50", "white"),
                             bar_width = 0.7,
                             paint_axis_text = TRUE,
                             x_label_angle = 60,
                             x_label_vjust = 1,
                             x_label_hjust = 1,
                             x_lab = "Components",
                             y_lab = "auto",
                             params = NULL, show_cv = FALSE,
                             params_label_size = 3,
                             params_label_angle = 60, y_expand = 1,
                             digits = 2, base_size = 12, font_scale = 1,
                             sig_names = NULL, sig_orders = NULL,
                             check_sig_names = TRUE) {
  stopifnot(all(!is.na(sig_names)), is.character(x_lab), is.character(y_lab))

  if (inherits(Signature, "Signature")) {
    Sig <- Signature$Signature
  } else if (is.matrix(Signature)) {
    if (check_sig_names) {
      if (!all(startsWith(colnames(Signature), "Sig"))) {
        stop("If Signature is a matrix, column names must start with 'Sig'!", call. = FALSE)
      }
    }
    Sig <- Signature
  } else {
    stop("Invalid input for 'Signature'", call. = FALSE)
  }

  mode <- match.arg(mode)
  method <- match.arg(method, choices = c("Macintyre", "M", "Wang", "W"))
  normalize <- match.arg(normalize)
  style <- match.arg(style)

  if (normalize == "row") {
    Sig <- apply(Sig, 2, function(x) x / sum(x))
  } else if (normalize == "column") {
    Sig <- t(apply(Sig, 1, function(x) x / sum(x)))
  }

  if (!is.null(filters)) {
    Sig <- Sig[sapply(rownames(Sig), function(x) {
      any(sapply(filters, function(y) {
        grepl(y, x)
      }))
    }), ]
  }

  # >>>>>>>>>>>>>>>>> identify mode and do data transformation
  mat <- as.data.frame(Sig)
  mat$context <- rownames(mat)

  if (mode == "copynumber") {
    if (startsWith(method, "M")) {
      mat$base <- sub("\\d+$", "", mat$context)
      mat <- tidyr::gather(mat, class, signature, -c("context", "base"))

      mat <- mat %>%
        dplyr::mutate(
          base = factor(.data$base, levels = c(
            "bp10MB", "bpchrarm",
            "copynumber", "changepoint",
            "osCN", "segsize"
          ))
        ) %>%
        dplyr::arrange(.data$base)

      mat <- dplyr::mutate(mat,
        context = factor(.data$context,
          levels = unique(mat[["context"]])
        ),
        class = factor(class)
      )
    } else {
      mat$base <- sub("\\[.*\\]$", "", mat$context)
      mat <- tidyr::gather(mat, class, signature, -c("context", "base"))

      if (!inherits(feature_setting, "sigminer.features")) {
        feature_setting <- get_feature_components(feature_setting)
      }
      avail_features <- unique(feature_setting$feature)

      # Make sure
      f_orders <- avail_features[avail_features %in% mat$base]
      comp_orders <- feature_setting$component[feature_setting$feature %in% f_orders]

      mat <- dplyr::mutate(mat,
        context = factor(.data$context,
          levels = comp_orders
        ),
        base = factor(.data$base, levels = f_orders),
        class = factor(class)
      )
    }
  } else {
    mat$base <- sub("[ACGT]\\[(.*)\\][ACGT]", "\\1", mat$context)
    mat$context <- sub("(\\[.*\\])", "\\-", mat$context)

    mat <- tidyr::gather(mat, class, signature, -c("context", "base"))
    mat <- dplyr::mutate(mat,
      context = factor(.data$context),
      base = factor(.data$base, levels = c(
        "C>A", "C>G",
        "C>T", "T>A",
        "T>C", "T>G"
      )),
      class = factor(class)
    )
  }

  if (normalize == "feature") {
    if (mode != "copynumber") {
      message("normalize='feature' only supports when the argument mode is 'copynumber'. Please use another value!")
      return(invisible())
    } else {
      mat <- mat %>%
        dplyr::group_by(.data$base, .data$class) %>%
        tidyr::nest() %>%
        dplyr::mutate(
          context = purrr::map(.data$data, ~ .$context),
          signature = purrr::map(.data$data, ~ .$signature / sum(.$signature))
        ) %>%
        dplyr::select(-"data") %>%
        tidyr::unnest(cols = c("context", "signature")) %>%
        dplyr::ungroup()
    }
  }

  # >>>>>>> Set signature name and order
  if (!is.null(sig_names)) {
    if (length(sig_names) != length(unique(mat[["class"]]))) {
      stop("The length of input signature names is not equal to signature number")
    }
    names(sig_names) <- paste0("Sig_", seq_along(sig_names))
    mat[["class"]] <- sig_names[mat[["class"]]]
  }

  if (!is.null(sig_orders)) {
    mat[["class"]] <- factor(mat[["class"]], levels = sig_orders)
  } else {
    mat[["class"]] <- factor(mat[["class"]])
  }
  # >>>>>>>>>>>>>>>>>>>>>>> Plot

  if (set_gradient_color) {
    if (mode == "SBS") {
      message("Gradient colors are not supported for mutational signatures!")
      message("Please set it to FALSE and re-run.")
      return(invisible())
    }

    col_df <- mat %>%
      dplyr::filter(.data$class == .data$class[1]) %>%
      dplyr::group_by(.data$base) %>%
      dplyr::summarise(N = dplyr::n())

    p <- ggplot(mat) +
      geom_bar(aes_string(x = "context", y = "signature", fill = "context"),
        stat = "identity", position = "identity",
        colour = bar_border_color, width = bar_width
      ) +
      scale_fill_manual(values = helper_create_colormap(col_df$base, col_df$N))
  } else {
    p <- ggplot(mat) +
      geom_bar(aes_string(x = "context", y = "signature", fill = "base"),
        stat = "identity", position = "identity",
        colour = bar_border_color, width = bar_width
      ) +
      scale_fill_manual(values = palette)
  }


  if (mode == "copynumber" & startsWith(method, "M")) {
    if (!is.null(params)) {
      params$class <- factor(levels(mat[["class"]])[1], levels = levels(mat[["class"]]))
      p <- p + geom_text(aes(
        x = .data$components, y = Inf,
        label = ifelse(.data$dist == "norm",
          paste0(
            " \u03BC=", signif(.data$mean, digits),
            ifelse(rep(show_cv, length(.data$cv)), paste0("; cv=", signif(.data$cv, digits)), "")
          ),
          paste0(
            " \u03BB=", signif(.data$mean, digits),
            ifelse(rep(show_cv, length(.data$cv)), paste0("; cv=", signif(.data$cv, digits)), "")
          )
        )
      ),
      data = params,
      size = params_label_size,
      angle = params_label_angle,
      hjust = 0, vjust = 0.5
      ) +
        coord_cartesian(clip = "off")
    }
    p <- p + facet_grid(class ~ ., scales = "free", space = free_space)
  } else {
    p <- p + facet_grid(class ~ base, scales = "free", space = free_space)
  }

  # Remove prefix to keep space
  if (startsWith(method, "W")) {
    p <- p + scale_x_discrete(
      breaks = mat$context,
      labels = sub(".*(\\[.*\\])$", "\\1", mat$context)
    )
  }


  # >>>>>>>>>>>>>>>>> Setting theme
  scale <- font_scale

  .theme_ss <- theme_bw(
    base_size = base_size,
    base_family = "sans"
  ) +
    theme(
      axis.text.x = element_text(
        angle = x_label_angle, vjust = x_label_vjust,
        hjust = x_label_hjust, size = (base_size - 4) * scale,
        color = "black",
        face = "bold",
        family = "mono"
      ),
      axis.text.y = element_text(
        hjust = 0.5,
        size = base_size * scale,
        color = "black"
      ),
      strip.text.x = element_text(face = "bold"),
      strip.text.y = element_text(face = "bold")
    )

  if (style == "cosmic") {
    .theme_ss <- .theme_ss + theme(
      panel.spacing.x = unit(0, "line"),
      strip.background.x = element_rect(color = "white"),
      strip.background.y = element_blank(),
      strip.text.x = element_text(
        color = "white",
        face = "bold"
      ),
      strip.text.y = element_text(
        size = 12,
        vjust = 1,
        color = "black",
        face = "bold",
        angle = 0
      )
    )
  }

  if (rm_panel_border) {
    .theme_ss <- .theme_ss + theme(
      panel.border = element_blank()
    )
  }

  if (rm_grid_line) {
    .theme_ss <- .theme_ss + theme(
      panel.grid.major = element_blank(),
      panel.grid.minor = element_blank()
    )
  }
  # <<<<<<<<<<<<<<<<< Setting theme

  p <- p +
    guides(fill = FALSE) + .theme_ss

  if (all(mode == "copynumber", !is.null(params))) {
    p <- p + theme(plot.margin = margin(30 * y_expand, 2, 2, 2, unit = "pt")) # Add regions
  }

  p <- p + xlab(x_lab)

  if (y_lab == "auto") {
    if (normalize == "column") {
      p <- p + ylab("Weights")
    } else if (normalize == "row" | normalize == "feature") {
      p <- p + ylab("Contributions")
    } else {
      p <- p + ylab("Estimated counts")
    }
  } else {
    p <- p + ylab(y_lab)
  }

  if (style != "default" | paint_axis_text) {
    g <- ggplot_gtable(ggplot_build(p))

    if (style != "default") {
      ## It is hard to use geom_label/text
      ## to add annotation for facet plot

      # https://github.com/tidyverse/ggplot2/issues/2096#issuecomment-389825118
      strip_t <- which(grepl("strip-t", g$layout$name))
      k <- 1
      for (i in strip_t) {
        j <- which(grepl("rect", g$grobs[[i]]$grobs[[1]]$childrenOrder))
        g$grobs[[i]]$grobs[[1]]$children[[j]]$gp$fill <- palette[k]
        k <- k + 1
      }
    }

    if (paint_axis_text) {
      axis_b <- which(grepl("axis-b", g$layout$name))
      k <- 1
      for (i in axis_b) {
        g$grobs[[i]]$children[[2]]$grobs[[2]]$children[[1]]$gp$col <- palette[k]
        k <- k + 1
      }
    }
    # grid::grid.draw(g)
    p <- ggplotify::as.ggplot(g)
  }

  return(p)
}
