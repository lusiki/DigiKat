# Paired outlet-cluster bootstrap. No source rows or article identifiers here.
barometar_bridge_estimate <- function(counts,panel_ids,seed=20260918L,repetitions=2000L) {
  required <- c("outlet_id","batch","scope","N","D")
  if(!all(required %in% names(counts)) || anyNA(counts[required]) ||
     any(!counts$outlet_id %in% panel_ids) || any(!counts$batch %in% c("old","new")) ||
     any(!counts$scope %in% c("siri","uze")) || any(!is.finite(counts$N) | !is.finite(counts$D)) ||
     any(counts$N!=floor(counts$N) | counts$D!=floor(counts$D)) || any(counts$D<0 | counts$N<counts$D) ||
     anyDuplicated(counts[c("outlet_id","batch","scope")]) || anyDuplicated(panel_ids) || anyNA(panel_ids) || any(!nzchar(panel_ids)))stop("Invalid paired bridge counts.")
  denominators <- split(counts$N,paste(counts$outlet_id,counts$batch,sep="|"))
  if(any(vapply(denominators,function(x)length(x)!=2L || length(unique(x))!=1L,logical(1L))))stop("Bridge scopes must share each denominator.")
  panel_ids <- sort(panel_ids,method="radix")
  P <- length(panel_ids);if(!P || length(repetitions)!=1L || is.na(repetitions) || !is.finite(repetitions) || repetitions<2L || repetitions!=floor(repetitions))stop("Empty bridge panel or invalid bootstrap repetitions.")
  previous_rng <- RNGkind();previous_seed <- if(exists(".Random.seed",.GlobalEnv,inherits=FALSE))get(".Random.seed",.GlobalEnv) else NULL
  on.exit({do.call(RNGkind,as.list(previous_rng));if(is.null(previous_seed)){if(exists(".Random.seed",.GlobalEnv,inherits=FALSE))rm(".Random.seed",envir=.GlobalEnv)}else assign(".Random.seed",previous_seed,.GlobalEnv)},add=TRUE)
  RNGkind("Mersenne-Twister","Inversion","Rejection");set.seed(seed)
  draws <- matrix(replicate(repetitions,sample.int(P,P,replace=TRUE)),nrow=P,ncol=repetitions)
  rows <- lapply(c("siri","uze"),function(scope) {
    get <- function(batch,field) {
      subset <- counts[counts$scope==scope & counts$batch==batch,,drop=FALSE]
      values <- subset[[field]][match(panel_ids,subset$outlet_id)];values[is.na(values)] <- 0;values
    }
    no <- get("old","N");nn <- get("new","N");do <- get("old","D");dn <- get("new","D")
    calculate <- function(i) {
      old <- if(sum(no[i]))sum(do[i])/sum(no[i]) else NA_real_
      new <- if(sum(nn[i]))sum(dn[i])/sum(nn[i]) else NA_real_
      c(ratio=if(is.finite(old) && old>0)new/old else NA_real_,breadth=100*sum((dn[i]>0)-(do[i]>0))/P)
    }
    point <- calculate(seq_len(P));replicates <- apply(draws,2L,calculate)
    finite <- all(is.finite(replicates["ratio",])) && is.finite(point[["ratio"]])
    ratio_ci <- if(finite)stats::quantile(replicates["ratio",],c(.025,.975),names=FALSE,type=7) else c(NA_real_,NA_real_)
    breadth_ci <- stats::quantile(replicates["breadth",],c(.025,.975),names=FALSE,type=7)
    data.frame(scope=scope,panel_outlets=P,N_old=sum(no),N_new=sum(nn),D_old=sum(do),D_new=sum(dn),
      M_old=sum(do>0),M_new=sum(dn>0),active_old=sum(no>=5),active_new=sum(nn>=5),
      visibility_old=if(sum(no))1e4*sum(do)/sum(no) else NA_real_,visibility_new=if(sum(nn))1e4*sum(dn)/sum(nn) else NA_real_,
      ratio=point[["ratio"]],ratio_lo=ratio_ci[1L],ratio_hi=ratio_ci[2L],breadth_difference_pp=point[["breadth"]],
      breadth_lo=breadth_ci[1L],breadth_hi=breadth_ci[2L],bootstrap_repetitions=repetitions,bootstrap_undefined=sum(!is.finite(replicates["ratio",])),
      seed=seed,gate_pass=finite && ratio_ci[1L]>=.9 && ratio_ci[2L]<=1.1 && abs(point[["breadth"]])<=2 &&
        sum(no>=5)/P>=.9 && sum(nn>=5)/P>=.9,stringsAsFactors=FALSE)
  })
  do.call(rbind,rows)
}
