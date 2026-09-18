# A reversible local generation swap. Every sidecar is prepared before mutation.
barometar_install_generation <- function(staged,target,sidecars,backup_root,workspace=getwd(),finalize_file=digikat_atomic_replace_file) {
  workspace <- normalizePath(workspace,winslash="/",mustWork=TRUE)
  absolute <- function(path) {
    parent <- normalizePath(dirname(path),winslash="/",mustWork=TRUE)
    paste0(parent,"/",basename(path))
  }
  target <- absolute(target);staged <- normalizePath(staged,winslash="/",mustWork=TRUE)
  backup_root <- normalizePath(backup_root,winslash="/",mustWork=TRUE)
  if(!startsWith(target,paste0(workspace,"/data/barometar/"))||
    !startsWith(staged,paste0(workspace,"/data/barometar/"))||
    !startsWith(backup_root,paste0(workspace,"/studies/demokrscanstvo-barometar/output/")))stop("Unsafe release swap paths.")
  if(is.null(names(sidecars))||any(!nzchar(names(sidecars)))||anyDuplicated(names(sidecars))||!all(file.exists(sidecars)))stop("Invalid staged sidecars.")
  # Sidecars may include the external private workdir; each exact file is named
  # by the caller. Only those files can be replaced or restored.
  destinations <- vapply(names(sidecars),absolute,character(1L))
  originals <- lapply(destinations,function(path)if(file.exists(path))readBin(path,"raw",file.info(path)$size) else NULL)
  backup <- tempfile("installed-",tmpdir=backup_root)
  had_target <- dir.exists(target);moved_old <- FALSE;moved_new <- FALSE;complete <- FALSE
  on.exit({
    if(!complete) {
      failures <- character()
      if(moved_new && !file.rename(target,staged))failures <- c(failures,"new generation could not be retained at its staged path")
      if(moved_old && !file.rename(backup,target))failures <- c(failures,paste0("prior generation remains at ",backup))
      for(i in seq_along(destinations)) {
        path <- destinations[i]
        if(is.null(originals[[i]])) {
          if(file.exists(path)&&unlink(path)!=0L)failures <- c(failures,paste0("could not remove new sidecar ",path))
        } else {
          restore <- tempfile("restore-",tmpdir=dirname(path))
          writeBin(originals[[i]],restore)
          restored <- try(digikat_atomic_replace_file(restore,path),silent=TRUE)
          if(inherits(restored,"try-error"))failures <- c(failures,paste0("could not restore sidecar ",path))
        }
      }
      if(length(failures))warning("Release rollback needs attention: ",paste(failures,collapse="; "),call.=FALSE)
    }
  },add=TRUE)
  if(had_target) {
    if(!file.rename(target,backup))stop("Could not retain the prior installed generation.")
    moved_old <- TRUE
  }
  if(!file.rename(staged,target))stop("Generation swap failed; rolling back.")
  moved_new <- TRUE
  for(i in seq_along(sidecars))finalize_file(sidecars[i],destinations[i])
  complete <- TRUE
  invisible(if(had_target)backup else NULL)
}
