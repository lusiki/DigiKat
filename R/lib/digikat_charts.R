# Shared presentation helpers for DigiKat analytical charts.

digikat_map_setup <- function() {
  knitr::opts_chunk$set(
    echo = FALSE,
    message = FALSE,
    warning = FALSE,
    fig.width = 10,
    fig.height = 7,
    dev = "ragg_png",
    dpi = 144,
    fig.retina = 1,
    out.width = "1440px",
    dev.args = list(bg = "#F5F4F0")
  )

  invisible(NULL)
}

.digikat_raise_mobile_layer_text <- function(plot, minimum_size = 4.2) {
  if (!is.null(plot$patches$plots)) {
    plot$patches$plots <- lapply(
      plot$patches$plots,
      .digikat_raise_mobile_layer_text,
      minimum_size = minimum_size
    )
  }

  for (index in seq_along(plot$layers)) {
    layer <- plot$layers[[index]]
    is_text <- inherits(layer$geom, "GeomText") ||
      inherits(layer$geom, "GeomLabel")
    size <- layer$aes_params$size
    if (is_text && is.numeric(size) && length(size) == 1L && size < minimum_size) {
      plot$layers[[index]]$aes_params$size <- minimum_size
    }
  }

  plot
}

digikat_mobile_readable <- function(plot) {
  plot <- .digikat_raise_mobile_layer_text(plot)
  wrap_label <- function(value, width) {
    if (!is.character(value) || length(value) != 1L || !nzchar(value)) return(value)
    paste(strwrap(value, width = width), collapse = "\n")
  }
  wrap_plot_labels <- function(item) {
    item$labels$title <- wrap_label(item$labels$title, 28)
    item$labels$subtitle <- wrap_label(item$labels$subtitle, 44)
    item$labels$caption <- wrap_label(item$labels$caption, 54)
    item$labels$x <- wrap_label(item$labels$x, 30)
    item$labels$y <- wrap_label(item$labels$y, 30)
    item
  }

  if (!is.null(plot$patches$plots)) {
    plot$patches$plots <- lapply(plot$patches$plots, wrap_plot_labels)
  }
  plot <- wrap_plot_labels(plot)
  if (!is.null(plot$patches$annotation)) {
    plot$patches$annotation$title <- wrap_label(plot$patches$annotation$title, 28)
    plot$patches$annotation$subtitle <- wrap_label(plot$patches$annotation$subtitle, 44)
    plot$patches$annotation$caption <- wrap_label(plot$patches$annotation$caption, 54)
  }

  axis_text <- if (inherits(plot$theme$axis.text, "element_blank")) {
    ggplot2::element_blank()
  } else {
    ggplot2::element_text(size = 12.5)
  }
  axis_title <- if (inherits(plot$theme$axis.title, "element_blank")) {
    ggplot2::element_blank()
  } else {
    ggplot2::element_text(size = 14)
  }

  mobile_type <- ggplot2::theme(
    axis.text = axis_text,
    axis.title = axis_title,
    strip.text = ggplot2::element_text(size = 14),
    legend.text = ggplot2::element_text(size = 12.5),
    legend.title = ggplot2::element_text(size = 13),
    plot.title = ggplot2::element_text(size = 20),
    plot.subtitle = ggplot2::element_text(size = 14),
    plot.caption = ggplot2::element_text(size = 11.5)
  )

  if (inherits(plot, "patchwork")) {
    plot & mobile_type
  } else {
    plot + mobile_type
  }
}

digikat_save_mobile_plot <- function(plot, width = 5, height = 7, label = NULL) {
  if (is.null(label)) label <- knitr::opts_current$get("label")
  if (is.null(label) || !nzchar(label)) {
    stop("A labelled knitr chunk is required for a mobile chart export.", call. = FALSE)
  }

  output_dir <- file.path("..", "..", "assets", "images", "maps", "mobile")
  dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)

  ggplot2::ggsave(
    filename = file.path(output_dir, paste0(label, ".png")),
    plot = digikat_mobile_readable(plot),
    device = ragg::agg_png,
    width = width,
    height = height,
    units = "in",
    dpi = 144,
    bg = "#F5F4F0"
  )

  invisible(plot)
}

digikat_render_map_plot <- function(plot, mobile_plot = plot,
                                    mobile_width = 5, mobile_height = 7) {
  digikat_save_mobile_plot(
    mobile_plot,
    width = mobile_width,
    height = mobile_height
  )
  print(plot)
  invisible(NULL)
}

.digikat_html_escape <- function(x) {
  x <- gsub("&", "&amp;", as.character(x), fixed = TRUE)
  x <- gsub("<", "&lt;", x, fixed = TRUE)
  x <- gsub(">", "&gt;", x, fixed = TRUE)
  x <- gsub('"', "&quot;", x, fixed = TRUE)
  x
}

digikat_chart_evidence <- function(slug, summary, ...) {
  summary <- .digikat_html_escape(summary)
  knitr::asis_output(paste0(
    '<div class="chart-evidence">',
    '<p class="chart-accessible-summary"><strong>Sažetak grafikona.</strong> ', summary, '</p>',
    '</div>'
  ))
}
