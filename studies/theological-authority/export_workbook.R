# Rebuild analysis separately with analyze_extended.R, then run this exporter.
# The Node dependency is supplied by the Codex runtime, never the repository.
invisible(Sys.setlocale('LC_CTYPE','English_United States.utf8'))
run <- function(command,args) {
 status <- system2(command,args)
 if(status!=0) stop('Workbook export failed: ',command)
}
run('python',c('studies/theological-authority/workbook_io.py','prepare'))
run('node',c('--max-old-space-size=12000','studies/theological-authority/build_workbook.mjs'))
run('python',c('studies/theological-authority/workbook_io.py','verify'))
