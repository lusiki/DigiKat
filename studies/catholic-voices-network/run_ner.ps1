param([string]$Workdir=$env:DIGIKAT_VOICES_WORKDIR,
      [string]$Python=(Join-Path $env:USERPROFILE 'venvs/digikat-nlp/Scripts/python.exe'))
$ErrorActionPreference='Stop'
if (!$Workdir) { throw 'Supply -Workdir.' }
Set-Location (Resolve-Path (Join-Path $PSScriptRoot '../..'))
$env:DIGIKAT_VOICES_WORKDIR=$Workdir
$env:PYTHONUTF8='1'
$env:PYTHONUNBUFFERED='1'
$lock=[System.IO.File]::Open((Join-Path $Workdir 'runner.lock'),'OpenOrCreate','ReadWrite','None')
try {
  $log=Join-Path $Workdir ('full-ner-'+(Get-Date -Format 'yyyyMMdd-HHmmss')+'.log')
  $ErrorActionPreference='Continue'
  & $Python -u (Join-Path $PSScriptRoot '10_ner.py') 2>&1 | Tee-Object -FilePath $log
  $code=$LASTEXITCODE
  $ErrorActionPreference='Stop'
  if ($code -ne 0) { throw "Full NER stopped (exit $code); saved progress retained." }
} finally { $lock.Dispose() }
