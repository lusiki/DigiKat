# Sampling/scoring is independent of the classifier. Only supplied human labels
# may enter reported validation. Development cases are never eligible.
barometar_draw_identity <- function(draw) {
  frame <- draw$frame[order(draw$frame$item_id,method="radix"),,drop=FALSE]
  digikat_hash_object(list(assignments=draw$assignments,membership=draw$membership,
    frame_hash=digikat_hash_object(frame),design=draw$design,seed=draw$seed,
    exclusions=draw$exclusion_hashes,definition_version=draw$definition_version,input_identity=draw$input_identity))
}

barometar_wilson <- function(k, n) {
  if (n == 0L) return(c(precision=NA_real_,lo=NA_real_,hi=NA_real_))
  z <- stats::qnorm(.975); p <- k/n; denominator <- 1+z*z/n
  centre <- (p+z*z/(2*n))/denominator
  delta <- z*sqrt(p*(1-p)/n+z*z/(4*n*n))/denominator
  c(precision=p,lo=max(0,centre-delta),hi=min(1,centre+delta))
}

barometar_kappa <- function(left,right) {
  if (length(left)!=length(right) || !length(left) || anyNA(left) || anyNA(right)) stop("Incomplete paired human labels.")
  categories <- union(left,right)
  observed <- mean(left==right)
  chance <- sum(vapply(categories,function(v)mean(left==v)*mean(right==v),numeric(1L)))
  c(agreement=observed,kappa=if(chance==1)NA_real_ else (observed-chance)/(1-chance))
}

barometar_validation_draw <- function(population,seed=20260918L) {
  if(anyDuplicated(population$item_id) || anyNA(population$item_id)) stop("Population item_id must be unique.")
  if(!all(c("development","route_set","source_batch","near_miss","recall_probe") %in% names(population))) stop("Incomplete validation frame.")
  pop <- population[!population$development,,drop=FALSE]
  if(!nrow(pop)) stop("No held-out evaluation frame.")
  old <- if(exists(".Random.seed",.GlobalEnv,inherits=FALSE)) get(".Random.seed",.GlobalEnv) else NULL
  on.exit(if(!is.null(old))assign(".Random.seed",old,.GlobalEnv),add=TRUE)
  set.seed(seed)
  route <- function(code) vapply(stringi::stri_split_fixed(pop$route_set,";"),function(x)code %in% x,logical(1L))
  frames <- list()
  quotas <- c(A1=60L,B=60L,C=60L,D=30L,A2=30L,`A?`=30L,near_miss=60L,recall_probe=100L)
  for(name in names(quotas)) {
    eligible <- if(name %in% c("near_miss","recall_probe")) pop[[name]] else route(name)
    # Batch strata preserve the prescribed pre/post allocation without mixing
    # development items. Census a short stratum, record its actual probability.
    batches <- if(name %in% c("A1","B","C")) sort(unique(pop$source_batch[eligible])) else "all"
    allocation <- rep(quotas[[name]] %/% max(1L,length(batches)),length(batches))
    if(length(allocation))allocation[1L] <- allocation[1L]+quotas[[name]]-sum(allocation)
    available <- vapply(batches,function(batch)sum(eligible & (batch=="all" | pop$source_batch==batch)),integer(1L))
    allocation <- pmin(allocation,available)
    remaining <- min(quotas[[name]],sum(available))-sum(allocation)
    while(remaining>0L) {
      j <- which.max(available-allocation)
      allocation[j] <- allocation[j]+1L
      remaining <- remaining-1L
    }
    for(j in seq_along(batches)) {
      indices <- which(eligible & (batches[j]=="all" | pop$source_batch==batches[j]))
      N <- length(indices); n <- min(allocation[j],N)
      selected <- if(n)indices[sample.int(N,n)] else integer()
      frames[[paste(name,batches[j],sep=":")]] <- list(stratum=name,batch=batches[j],
        ids=pop$item_id[indices],selected=pop$item_id[selected],N=N,n=n)
    }
  }
  ids <- sort(unique(unlist(lapply(frames,`[[`,"selected"))))
  assignments <- pop[match(ids,pop$item_id),,drop=FALSE]
  assignments$selection_probability <- vapply(ids,function(id) {
    relevant <- Filter(function(frame)id %in% frame$ids,frames)
    1-prod(vapply(relevant,function(frame)1-frame$n/frame$N,numeric(1L)))
  },numeric(1L))
  assignments$double_code <- FALSE
  n_second <- min(nrow(assignments),max(80L,ceiling(.25*nrow(assignments))))
  if(n_second)assignments$double_code[sample.int(nrow(assignments),n_second)] <- TRUE
  membership <- do.call(rbind,lapply(frames,function(frame) data.frame(item_id=frame$selected,
    stratum=rep(frame$stratum,frame$n),batch=rep(frame$batch,frame$n),n=rep(frame$n,frame$n),N=rep(frame$N,frame$n))))
  design <- do.call(rbind,lapply(frames,function(frame)data.frame(stratum=frame$stratum,batch=frame$batch,n=frame$n,N=frame$N)))
  list(assignments=assignments,membership=membership,design=design,frame=pop,seed=seed)
}

barometar_validate_coding <- function(coding,ids,coder_type) {
  fields <- c("item_id","coder_type","qualifies","construct","speaker_type","geography","register","themes","axis1","axis2","axis3","axis4","masked_evidence")
  if(!all(fields %in% names(coding)) || anyDuplicated(coding$item_id) ||
      !setequal(coding$item_id,ids)) stop("Human coding sheet has missing/duplicate/foreign item IDs or columns.")
  if(!all(coding$coder_type==coder_type) || !coder_type %in% c("human_PI","human_second","human_PI_adjudicated")) stop("Only identified human coders may supply reported labels.")
  if(anyNA(coding[fields]) || any(vapply(coding[fields],function(x)any(!nzchar(as.character(x))),logical(1L)))) stop("Human coding is incomplete; unfilled labels cannot be scored.")
  if(any(!coding$qualifies %in% c("da","ne","nesigurno"))) stop("Invalid qualification label.")
  choices <- list(construct=c("A1","A2","B","C","D","ništa"),
    speaker_type=c("crkveni govornik","demokršćanski akter","drugi politički akter","ostalo / nepripisano"),
    geography=c("domaće","inozemno","EU","mješovito","neodređeno"),register=c("supstancijski","identitarni","oba","ništa"),
    themes=c("family","work","economy","politics","europe","environment","unclassified"),
    axis1=c("genuine","incidental","not_applicable"),axis2=c("domestic","foreign","mixed","not_applicable"),
    axis3=c("actor","commentator","both","not_applicable"),
    axis4=c("justice","charity","devotional","object_institution","object_cost_relig_life","other","not_applicable"),
    masked_evidence=c("da","ne","not_applicable"))
  for(field in names(choices)) {
    values <- if(field %in% c("construct","themes"))unlist(stringi::stri_split_fixed(coding[[field]],";")) else coding[[field]]
    if(any(!values %in% choices[[field]]))stop("Invalid human label: ",field)
  }
  if(any(vapply(stringi::stri_split_fixed(coding$construct,";"),function(x)"ništa" %in% x && length(x)>1L,logical(1L))))stop("Nothing cannot accompany a construct label.")
  coding[match(ids,coding$item_id),,drop=FALSE]
}

barometar_score_validation <- function(draw,pi,second,adjudicated,definition_version) {
  ids <- draw$assignments$item_id
  pi <- barometar_validate_coding(pi,ids,"human_PI")
  second_ids <- ids[draw$assignments$double_code]
  second <- barometar_validate_coding(second,second_ids,"human_second")
  adjudicated <- barometar_validate_coding(adjudicated,ids,"human_PI_adjudicated")
  left <- pi[match(second_ids,pi$item_id),,drop=FALSE]
  agreement <- barometar_kappa(ifelse(left$qualifies=="da","da","ne"),ifelse(second$qualifies=="da","da","ne"))
  construct_set <- function(x) vapply(stringi::stri_split_fixed(x,";"),function(set) {
    priority <- c("A1","B","C","A2","D","ništa")
    matched <- priority[priority %in% set]
    if(!length(matched) || any(!set %in% priority) || ("ništa" %in% matched && length(matched)>1L))stop("Invalid human construct.")
    paste(matched,collapse=";")
  },character(1L))
  construct_agreement <- barometar_kappa(construct_set(left$construct),construct_set(second$construct))
  invisible(construct_set(adjudicated$construct))
  estimates <- lapply(c("A1","B","C","D","A2"),function(route) {
    sampled <- unique(draw$membership$item_id[draw$membership$stratum==route])
    labels <- adjudicated[match(sampled,adjudicated$item_id),,drop=FALSE]
    correct <- (route=="A2" | labels$qualifies=="da") & vapply(stringi::stri_split_fixed(labels$construct,";"),function(x)route %in% x,logical(1L))
    marginal <- draw$membership[draw$membership$stratum==route,,drop=FALSE]
    marginal <- marginal[match(sampled,marginal$item_id),,drop=FALSE]
    weights <- marginal$N/marginal$n
    k <- sum(correct); n <- length(correct)
    precision <- if(n)sum(weights*correct)/sum(weights) else NA_real_
    n_eff <- if(n)sum(weights)^2/sum(weights^2) else 0
    ci <- barometar_wilson(precision*n_eff,n_eff)
    data.frame(route=route,stratum=route,n=n,k=k,precision=precision,lo=ci[["lo"]],hi=ci[["hi"]],n_eff=n_eff,
      interval_method="Wilson_Kish",kappa=agreement[["kappa"]],gate=if(!n)"unvalidated" else if(route %in% c("A2","D"))"diagnostic" else if(precision>=.8)"accepted" else if(precision>=.6)"experimental" else "dropped",
      definition_version=definition_version,coder_type="human_PI_adjudicated",stringsAsFactors=FALSE)
  })
  table <- do.call(rbind,estimates)
  diagnostic_ids <- draw$membership$item_id[draw$membership$stratum=="A?"]
  unresolved <- adjudicated[match(diagnostic_ids,adjudicated$item_id),c("qualifies","construct"),drop=FALSE]
  unresolved_resolution <- if(nrow(unresolved))as.data.frame(table(unresolved$qualifies,unresolved$construct),stringsAsFactors=FALSE) else data.frame()
  # Route-set post-stratification: population shares come from frozen frame;
  # unequal inclusion probabilities weight human outcomes within each cell.
  accepted <- table$route[table$gate=="accepted" & table$route %in% c("A1","B","C")]
  normalize <- function(x) paste(intersect(accepted,stringi::stri_split_fixed(x,";")[[1L]]),collapse=";")
  pop_sets <- vapply(draw$frame$route_set,normalize,character(1L))
  sample_sets <- vapply(draw$assignments$route_set,normalize,character(1L))
  cells <- sort(unique(pop_sets[nzchar(pop_sets)]))
  weights <- vapply(cells,function(cell)sum(pop_sets==cell)/sum(nzchar(pop_sets)),numeric(1L))
  human_accepted <- adjudicated$qualifies=="da" & vapply(stringi::stri_split_fixed(adjudicated$construct,";"),function(x)any(x %in% accepted),logical(1L))
  cell_precision <- vapply(cells,function(cell) {
    i <- which(sample_sets==cell)
    if(!length(i))return(NA_real_)
    w <- 1/draw$assignments$selection_probability[i]
    sum(w*human_accepted[i])/sum(w)
  },numeric(1L))
  broad <- sum(weights*cell_precision)
  mask_losses <- sum(adjudicated$masked_evidence=="da")
  broad_pass <- length(accepted)>0L && is.finite(broad) && broad>=.8 && is.finite(agreement[["kappa"]]) && agreement[["kappa"]]>=.7 && mask_losses==0L
  narrow_pass <- "A1" %in% accepted && mask_losses==0L
  per_batch <- do.call(rbind,lapply(c("A1","B","C"),function(route) {
    marginal <- draw$membership[draw$membership$stratum==route,,drop=FALSE]
    do.call(rbind,lapply(sort(unique(marginal$batch)),function(batch) {
      ids <- marginal$item_id[marginal$batch==batch];labels <- adjudicated[match(ids,adjudicated$item_id),,drop=FALSE]
      correct <- labels$qualifies=="da" & vapply(stringi::stri_split_fixed(labels$construct,";"),function(x)route %in% x,logical(1L))
      ci <- barometar_wilson(sum(correct),length(correct))
      data.frame(route=route,source_batch=batch,n=length(correct),k=sum(correct),precision=ci[1L],lo=ci[2L],hi=ci[3L])
    }))
  }))
  theme_precision <- do.call(rbind,lapply(c("family","work","economy","politics","europe","environment","unclassified"),function(theme) {
    i <- which(nzchar(sample_sets) & vapply(stringi::stri_split_fixed(draw$assignments$themes,";"),function(x)theme %in% x,logical(1L)))
    truth <- human_accepted[i] & vapply(stringi::stri_split_fixed(adjudicated$themes[i],";"),function(x)theme %in% x,logical(1L))
    w <- 1/draw$assignments$selection_probability[i]
    estimate <- if(length(i))sum(w*truth)/sum(w) else NA_real_
    data.frame(theme_id=theme,n=length(i),k=sum(truth),precision=estimate,
      theme_status=if(!is.finite(estimate)||estimate<.7)"unconfirmed" else "confirmed")
  }))
  misses <- do.call(rbind,lapply(c("near_miss","recall_probe"),function(stratum) {
    ids <- draw$membership$item_id[draw$membership$stratum==stratum]
    truth <- adjudicated$qualifies[match(ids,adjudicated$item_id)]=="da"
    ci <- barometar_wilson(sum(truth),length(truth))
    data.frame(stratum=stratum,n=length(truth),misses=sum(truth),fraction=ci[1L],lo=ci[2L],hi=ci[3L])
  }))
  list(validation=table,agreement=agreement,construct_agreement=construct_agreement,
    broad_precision=broad,broad_publishable=broad_pass,route_set_precision=data.frame(route_set=cells,population_share=weights,precision=cell_precision),
    unresolved_resolution=unresolved_resolution,second_coder_n=length(second_ids),per_batch=per_batch,
    theme_precision=theme_precision,miss_diagnostics=misses,masked_evidence_losses=mask_losses,
    accepted_routes=accepted,narrow_publishable=narrow_pass,
    release_scope=if(broad_pass)"siri" else if(narrow_pass)"uze" else "none")
}
