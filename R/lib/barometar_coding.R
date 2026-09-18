# Private human contexts use their OWN unmasked normalized coordinate system.
# No classifier labels or highlights enter the returned material.
barometar_coding_context <- function(title,full_text,definition,boilerplate_keys=character()) {
  prepared <- barometar_prepare_text(title,full_text)
  fields <- list(title=if(is.na(title))"" else title,body=prepared$body)
  pieces <- character()
  for(field in names(fields)) {
    evidence <- barometar_field_evidence(fields[[field]],definition,field)
    hits <- evidence$hits
    anchors <- hits$family %in% c("cd_label","grounding","church_speaker","actor_church") |
      hits$source_group %in% c("doctrinal_anchors.yaml","concept_families.yaml")
    if(!any(anchors))next
    txt <- evidence$txt
    if(field=="title") {
      # Qualifying title content is itself evidence; do not hide it from humans.
      pieces <- c(pieces,txt)
      body <- barometar_normalize_text(prepared$body)
      pieces <- c(pieces,stringi::stri_split_regex(body,"\\n+",omit_empty=TRUE)[[1L]][1L])
      next
    }
    boundaries <- stringi::stri_locate_all_regex(txt,"\\n+",omit_no_match=TRUE)[[1L]]
    starts <- c(1L,if(nrow(boundaries))boundaries[,2L]+1L else integer())
    ends <- c(if(nrow(boundaries))boundaries[,1L]-1L else integer(),stringi::stri_length(txt))
    which_paragraph <- findInterval(hits$start[anchors],starts)
    # One paragraph on either side preserves context; no arbitrary character cut.
    keep <- sort(unique(pmax(1L,pmin(length(starts),c(which_paragraph-1L,which_paragraph,which_paragraph+1L)))))
    pieces <- c(pieces,stringi::stri_sub(txt,starts[keep],ends[keep]))
  }
  if(!length(pieces))pieces <- barometar_normalize_text(prepared$body)
  segments <- barometar_boilerplate_segments(prepared$body)[[1L]]
  keys <- vapply(barometar_boilerplate_key_text(segments),digest::digest,character(1L),algo="md5",serialize=FALSE)
  mask_audit <- unique(segments[keys %in% boilerplate_keys])
  list(passage=paste(unique(pieces[!is.na(pieces)&nzchar(pieces)]),collapse="\n\n[… odvojeni odlomak …]\n\n"),
    mask_audit=paste(mask_audit,collapse="\n\n[… odvojeni odlomak …]\n\n"))
}
