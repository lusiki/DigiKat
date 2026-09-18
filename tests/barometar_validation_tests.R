source("R/lib/barometar_validation.R",encoding="UTF-8")
local({
  population <- data.frame(item_id=sprintf("synthetic-%04d",1:600),development=seq_len(600)%%10L<3L,
    route_set=rep(c("A1","A1;B","B;C","C","A2","A?","A1;D",""),75L),
    source_batch=rep(c("luka_opce","mediaspace_full"),each=300L),near_miss=FALSE,recall_probe=FALSE)
  population$near_miss[population$route_set==""] <- TRUE
  population$recall_probe[population$route_set==""] <- TRUE
  draw <- barometar_validation_draw(population)
  again <- barometar_validation_draw(population)
  stopifnot(identical(draw,again),!any(draw$assignments$development),!anyDuplicated(draw$assignments$item_id),
    all(draw$assignments$selection_probability>0 & draw$assignments$selection_probability<=1),
    sum(draw$assignments$double_code)>=80L,all(draw$membership$item_id %in% draw$assignments$item_id))
  for(id in draw$assignments$item_id) {
    # Marginal selections can overlap, but every item has exactly one coding record.
    stopifnot(sum(draw$assignments$item_id==id)==1L)
  }
  stopifnot(abs(barometar_wilson(8,10)[["precision"]]-.8)<1e-10,
    is.na(barometar_wilson(0,0)[["precision"]]),barometar_wilson(0,10)[["hi"]]>0,
    barometar_kappa(c("yes","no","yes","no"),c("yes","no","yes","no"))[["kappa"]]==1)
  fails <- function(expr)inherits(tryCatch({force(expr);NULL},error=identity),"error")
  stopifnot(fails(barometar_validate_coding(data.frame(),draw$assignments$item_id,"human_PI")))
  cat("Barometer validation: blind split, reproducible overlapping draws, probabilities, human-label guards and interval checks passed.\n")
})
