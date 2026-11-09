param([string]$Workdir=$env:DIGIKAT_VOICES_WORKDIR,
      [string]$Python=(Join-Path $env:USERPROFILE 'venvs/digikat-nlp/Scripts/python.exe'),
      [string]$Rscript='C:/Program Files/R/R-4.6.0/bin/Rscript.exe',
      [ValidateSet('all','prepare','compute')][string]$Mode='all')
$ErrorActionPreference='Stop'
if (!$Workdir) { throw 'Supply -Workdir.' }
Set-Location (Resolve-Path (Join-Path $PSScriptRoot '../..'))
$env:DIGIKAT_VOICES_WORKDIR=$Workdir
$env:PYTHONUTF8='1'
$env:PYTHONUNBUFFERED='1'
$env:LC_ALL='English_United States.utf8'
$expected=(Get-Content -Encoding UTF8 (Join-Path $PSScriptRoot '../../data/digikat_corpus_manifest.json') -Raw | ConvertFrom-Json).corpus.sha256
$checkpoints=if ($Mode -eq 'compute') { @('network_inputs_report.json') } else { @('identity_resolution_report.json','circulation_report.json') }
foreach ($checkpoint in $checkpoints) {
  while (!(Test-Path -LiteralPath (Join-Path $Workdir $checkpoint))) { Start-Sleep -Seconds 30 }
  $saved=Get-Content -Encoding UTF8 (Join-Path $Workdir $checkpoint) -Raw | ConvertFrom-Json
  if ($saved.corpus_sha256 -ne $expected) { throw 'Checkpoint belongs to another corpus.' }
}
$lock=$null; $computeLock=$null
if ($Mode -ne 'compute') {
  while (!$lock) {
    try { $lock=[System.IO.File]::Open((Join-Path $Workdir 'runner.lock'),'OpenOrCreate','ReadWrite','None') }
    catch [System.IO.IOException] { Start-Sleep -Seconds 30 }
  }
}
try {
  $log=Join-Path $Workdir ('networks-'+$Mode+'-'+(Get-Date -Format 'yyyyMMdd-HHmmss')+'.log')
  if ($Mode -ne 'compute') {
    $ErrorActionPreference='Continue'
    & $Python -u (Join-Path $PSScriptRoot '69_prepare_networks.py') 2>&1 | Tee-Object -FilePath $log -Append
    $code=$LASTEXITCODE
    $ErrorActionPreference='Stop'
    if ($code -ne 0) { throw "Mention inputs stopped ($code); saved results retained." }
  }
  if ($Mode -ne 'prepare') {
    # R reads only frozen CSV inputs and writes network RDS/JSON artifacts.
    # Its separate lock permits speech DB writes while preventing duplicate R runs.
    while (!$computeLock) {
      try { $computeLock=[System.IO.File]::Open((Join-Path $Workdir 'network-compute.lock'),'OpenOrCreate','ReadWrite','None') }
      catch [System.IO.IOException] { Start-Sleep -Seconds 30 }
    }
    $ErrorActionPreference='Continue'
    & $Rscript --vanilla (Join-Path $PSScriptRoot '70_networks.R') 2>&1 | Tee-Object -FilePath $log -Append
    $code=$LASTEXITCODE
    $ErrorActionPreference='Stop'
    if ($code -ne 0) { throw "Mention networks stopped ($code); saved results retained." }
    'Level-A mention networks complete. Speech/relation validation, robustness and final reporting remain separate.' | Tee-Object -FilePath $log -Append
  } else {
    'Network inputs frozen. Compute mode can now run alongside the speech pipeline.' | Tee-Object -FilePath $log -Append
  }
} finally {
  if ($computeLock) { $computeLock.Dispose() }
  if ($lock) { $lock.Dispose() }
}
