source("studies/demokrscanstvo-barometar/08_aggregate.R",encoding="UTF-8")
source("R/lib/barometar_page.R",encoding="UTF-8")
source("R/lib/barometar_figures.R",encoding="UTF-8")

barometar_require_fonts <- function() {
  families <- c("Source Serif 4","Source Sans 3","IBM Plex Mono")
  for(family in families)systemfonts::require_font(family)
  fonts <- systemfonts::match_fonts(families)
  if(any(stringi::stri_detect_regex(tolower(fonts$path),"arial[.]ttf$")) || any(!file.exists(fonts$path)))stop("Required Source/Plex fonts are unavailable.")
  invisible(fonts)
}

barometar_figures <- function(directory,synthetic_allowed=FALSE) {
  barometar_require_fonts()
  release <- barometar_read_release(directory,synthetic_allowed)
  knitr::opts_chunk$set(dev="svglite")
  source("R/theme_digikat.R",local=environment(),encoding="UTF-8")
  output <- file.path(directory,"figures");dir.create(output,recursive=TRUE,showWarnings=FALSE)
  for(frequency in c("monthly","weekly"))for(scope in unique(release$tables[[frequency]]$scope))for(metric in c("visibility_per_10000","breadth_pct")) {
    plot <- barometar_static_plot(release$tables[[frequency]],metric,scope,rolling=release$tables$rolling28) +
      theme_digikat() + ggplot2::theme(text=ggplot2::element_text(family="Source Sans 3"),
        plot.background=ggplot2::element_rect(fill="#f5f4f0",colour=NA),plot.caption=ggplot2::element_text(hjust=0,size=9,colour="#51575d"))
    stem <- paste(frequency,scope,metric,sep="_")
    svglite::svglite(file.path(output,paste0(stem,".svg")),width=10,height=3.8);print(plot);grDevices::dev.off()
    svg <- file.path(output,paste0(stem,".svg"))
    lines <- readLines(svg,encoding="UTF-8",warn=FALSE)
    connection <- file(svg,"wb");writeBin(charToRaw(enc2utf8(paste0(paste(lines,collapse="\n"),"\n"))),connection);close(connection)
    ragg::agg_png(file.path(output,paste0(stem,".png")),width=1440,height=548,res=144,background="#f5f4f0");print(plot);grDevices::dev.off()
  }
  # A data-free card is honest for a synthetic preview or pending validation.
  ragg::agg_png(file.path(output,"social-card.png"),width=1200,height=630,res=144)
  grid::grid.newpage();grid::grid.rect(gp=grid::gpar(fill="#0f4c5c",col=NA))
  grid::grid.text("DIGIKAT · HRVATSKO KATOLIČKO SVEUČILIŠTE",x=.08,y=.84,just="left",gp=grid::gpar(col="#f5f4f0",fontfamily="Source Sans 3",fontsize=16))
  grid::grid.text("Medijski barometar\ndemokršćanstva",x=.08,y=.56,just="left",gp=grid::gpar(col="white",fontfamily="Source Serif 4",fontsize=39,lineheight=1.2))
  grid::grid.text(if(isTRUE(release$summary$synthetic))"SINTETIČKI PRIKAZ · METODA U RAZVOJU" else
    paste("Izdanje",release$summary$release_version,"· Podaci do",release$summary$data_through),x=.08,y=.2,just="left",gp=grid::gpar(col="#f5f4f0",fontfamily="Source Sans 3",fontsize=15))
  grDevices::dev.off()
  barometar_finalize_manifest(directory,release$summary)
  invisible(output)
}
if(barometar_script_main("09_figures.R")) {
  args <- commandArgs(trailingOnly=TRUE)
  if(identical(args,"--check-fonts")){print(barometar_require_fonts());print(requireNamespace("pdftools",quietly=TRUE))}
  else if(length(args)==1L)barometar_figures(args)
  else stop("Pass a checked release directory, or --check-fonts.")
}
