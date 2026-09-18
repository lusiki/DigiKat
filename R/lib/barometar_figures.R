# Plot an already screened aggregate. No source database or aggregation here.
barometar_static_plot <- function(series,metric,scope="siri",mobile=FALSE,rolling=NULL) {
  d <- series[series$scope==scope,,drop=FALSE]
  d <- d[order(d$period_start),]
  d$date <- as.Date(d$period_start);d$end <- as.Date(d$period_end)
  d$value <- d[[metric]]
  d$status <- d[[if(metric=="breadth_pct")"breadth_status" else "visibility_status"]]
  seam <- as.Date("2024-04-01")
  breaks <- c(TRUE,head(d$status,-1L)!="published" | tail(d$status,-1L)!="published" |
    (head(d$end,-1L)<seam & tail(d$end,-1L)>=seam))
  d$segment <- cumsum(breaks)
  missing <- d[d$status=="unavailable",,drop=FALSE]
  number <- function(x)vapply(x,function(value)if(is.na(value))"—" else if(value==0)"0" else if(value>0&&value<.05)"< 0,1" else formatC(value,format="f",digits=1,big.mark=".",decimal.mark=","),character(1L))
  weekly <- identical(unique(d$frequency),"weekly")
  legend <- if(mobile)"Crta: promjena prikupljanja 1. 4. 2024.\nPrazne točke: djelomično. Sivo: nedostupno." else "Isprekidana crta: promjena prikupljanja 1. travnja 2024.\nPrazne točke: djelomična razdoblja. Sivo: podaci nisu dostupni."
  if(weekly)legend <- paste0("Stupci: zasebni tjedni. Puna crta: zadnjih 28 dana.\n",legend)
  line <- if(weekly)NULL else ggplot2::geom_line(data=d[d$status=="published",],ggplot2::aes(group=segment),colour="#0f4c5c",linewidth=.6,na.rm=TRUE)
  bars <- if(weekly)ggplot2::geom_col(data=d[d$status=="published",],fill="#5a949f",width=4,na.rm=TRUE) else NULL
  roll_line <- NULL
  if(weekly && !is.null(rolling)) {
    r <- rolling[rolling$scope==scope & rolling$period_end %in% d$period_end,,drop=FALSE]
    r$date <- as.Date(r$period_end)-6L;r$value <- r[[metric]]
    r$status <- r[[if(metric=="breadth_pct")"breadth_status" else "visibility_status"]]
    r$segment <- cumsum(c(TRUE,head(r$status,-1L)!="published" | tail(r$status,-1L)!="published" |
      (head(as.Date(r$period_end),-1L)<seam & tail(as.Date(r$period_end),-1L)>=seam)))
    roll_line <- ggplot2::geom_line(data=r[r$status=="published",],ggplot2::aes(group=segment),colour="#0f4c5c",linewidth=.7,na.rm=TRUE)
  }
  ggplot2::ggplot(d,ggplot2::aes(x=date,y=value)) +
    ggplot2::geom_rect(data=missing,ggplot2::aes(xmin=date,xmax=end+1,ymin=-Inf,ymax=Inf),inherit.aes=FALSE,fill="#e4e2da",alpha=.65) +
    bars + line + roll_line +
    ggplot2::geom_point(ggplot2::aes(shape=status),colour="#0f4c5c",size=1.5,na.rm=TRUE) +
    ggplot2::scale_shape_manual(values=c(published=16,partial=1,unavailable=NA),guide="none") +
    ggplot2::geom_vline(xintercept=seam,linetype="dashed",colour="#51575d") +
    ggplot2::scale_x_date(date_breaks=if(mobile)"2 years" else "1 year",date_labels="%Y") +
    ggplot2::scale_y_continuous(labels=number,limits=if(metric=="breadth_pct")c(0,100) else c(0,NA),expand=ggplot2::expansion(mult=c(.02,.08))) +
    ggplot2::labs(x=NULL,y=if(metric=="breadth_pct")"% praćenih medija" else "Na 10.000 analiziranih članaka",
      caption=legend) +
    ggplot2::theme_minimal(base_family="Source Sans 3",base_size=11) +
    ggplot2::theme(panel.grid.minor=ggplot2::element_blank(),panel.grid.major=ggplot2::element_line(colour="#e2ddd0"),
      plot.background=ggplot2::element_rect(fill="#ffffff",colour=NA),plot.caption=ggplot2::element_text(hjust=0,size=9),
      axis.title.y=ggplot2::element_text(size=10),axis.text=ggplot2::element_text(colour="#51575d"))
}
