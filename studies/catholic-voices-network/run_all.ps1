param([string]$CorpusPath = $env:DIGIKAT_CORPUS_PATH,
      [string]$Workdir = $env:DIGIKAT_VOICES_WORKDIR,
      [string]$Rscript = 'C:\Program Files\R\R-4.6.0\bin\Rscript.exe')
$ErrorActionPreference = 'Stop'
if (!$CorpusPath -or !$Workdir) { throw 'Supply -CorpusPath and -Workdir (or set DIGIKAT_CORPUS_PATH and DIGIKAT_VOICES_WORKDIR).' }
Set-Location (Resolve-Path (Join-Path $PSScriptRoot '../..'))
$env:DIGIKAT_CORPUS_PATH = $CorpusPath
$env:DIGIKAT_VOICES_WORKDIR = $Workdir
$env:LC_ALL = 'English_United States.utf8'
New-Item -ItemType Directory -Force -Path $Workdir | Out-Null
# OS-owned lock is automatically released on process termination or reboot.
$lock = [System.IO.File]::Open((Join-Path $Workdir 'runner.lock'), 'OpenOrCreate', 'ReadWrite', 'None')
try {
  $log = Join-Path $Workdir ('export-' + (Get-Date -Format 'yyyyMMdd-HHmmss') + '.log')
  $ErrorActionPreference = 'Continue'
  & $Rscript --vanilla (Join-Path $PSScriptRoot '01_export_docs.R') 2>&1 | Tee-Object -FilePath $log
  $code = $LASTEXITCODE
  $ErrorActionPreference = 'Stop'
  if ($code -ne 0) { throw "Export failed; saved batches retained. See $log" }
  & $Rscript --vanilla (Join-Path $PSScriptRoot 'verify_export.R')
  if ($LASTEXITCODE -ne 0) { throw 'Export validation failed; do not proceed to model pilots.' }
  Write-Output 'S0 export complete. Next: Python 3.11 environment, MinHash, NER and LLM pilots. These stages are not implemented yet.'
} finally { $lock.Dispose() }
