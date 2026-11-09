param([string]$Workdir=$env:DIGIKAT_VOICES_WORKDIR,
      [string]$Python=(Join-Path $env:USERPROFILE 'venvs/digikat-nlp/Scripts/python.exe'))
$ErrorActionPreference='Stop'
if (!$Workdir) { throw 'Supply -Workdir or set DIGIKAT_VOICES_WORKDIR.' }
Set-Location (Resolve-Path (Join-Path $PSScriptRoot '../..'))
$env:DIGIKAT_VOICES_WORKDIR=$Workdir
$env:PYTHONUTF8='1'
$env:PYTHONUNBUFFERED='1'
$lock=[System.IO.File]::Open((Join-Path $Workdir 'runner.lock'),'OpenOrCreate','ReadWrite','None')
try {
  $log=Join-Path $Workdir ('remaining-'+(Get-Date -Format 'yyyyMMdd-HHmmss')+'.log')
  foreach ($stage in @('02_prepare_remaining.py','02_pilot_parse.py','04_minhash.py','03_pilot_llm.py','05_s0_summary.py')) {
    Write-Output ("Starting $stage")
    $ErrorActionPreference='Continue'
    & $Python -u (Join-Path $PSScriptRoot $stage) 2>&1 | Tee-Object -FilePath $log -Append
    $code=$LASTEXITCODE
    $ErrorActionPreference='Stop'
    if ($code -ne 0) { throw "$stage stopped with exit $code. Checkpoints retained; see $log" }
  }
} finally { $lock.Dispose() }
