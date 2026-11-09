param([string]$Workdir=$env:DIGIKAT_VOICES_WORKDIR,
      [string]$Python=(Join-Path $env:USERPROFILE 'venvs/digikat-nlp/Scripts/python.exe'),
      [string]$ReportingPython='C:/Python314/python.exe',
      [string]$Rscript='C:/Program Files/R/R-4.6.0/bin/Rscript.exe')
$ErrorActionPreference='Stop'
if (!$Workdir) { throw 'Supply -Workdir.' }
Set-Location (Resolve-Path (Join-Path $PSScriptRoot '../..'))
$env:DIGIKAT_VOICES_WORKDIR=$Workdir
$env:PYTHONUTF8='1'
$env:PYTHONUNBUFFERED='1'
$env:LC_ALL='English_United States.utf8'
$expected=(Get-Content -Encoding UTF8 (Join-Path $PSScriptRoot '../../data/digikat_corpus_manifest.json') -Raw | ConvertFrom-Json).corpus.sha256
foreach ($checkpoint in @('speech_rule_report.json','mention_network_report.json')) {
  while (!(Test-Path -LiteralPath (Join-Path $Workdir $checkpoint))) { Start-Sleep -Seconds 30 }
  $saved=Get-Content -Encoding UTF8 (Join-Path $Workdir $checkpoint) -Raw | ConvertFrom-Json
  if ($saved.corpus_sha256 -ne $expected) { throw 'Checkpoint belongs to another corpus.' }
}
$lock=$null
while (!$lock) {
  try { $lock=[System.IO.File]::Open((Join-Path $Workdir 'runner.lock'),'OpenOrCreate','ReadWrite','None') }
  catch [System.IO.IOException] { Start-Sleep -Seconds 30 }
}
try {
  $log=Join-Path $Workdir ('report-metrics-'+(Get-Date -Format 'yyyyMMdd-HHmmss')+'.log')
  foreach ($script in @('71_publication_audit.py','78_export_network_metrics.R','80_report_data.py','81_report_figures.R',
                       '82_report_narrative.py','83_public_byproducts.py','85_assemble_report.py','86_render_report.py')) {
    $ErrorActionPreference='Continue'
    if ($script.EndsWith('.R')) {
      & $Rscript --vanilla (Join-Path $PSScriptRoot $script) 2>&1 | Tee-Object -FilePath $log -Append
    } elseif ($script -eq '86_render_report.py') {
      & $ReportingPython (Join-Path $PSScriptRoot $script) (Join-Path $PSScriptRoot 'output/private/report/report_registry.json') 2>&1 | Tee-Object -FilePath $log -Append
    } elseif ($script -eq '85_assemble_report.py') {
      & $Python -u (Join-Path $PSScriptRoot $script) (Join-Path $PSScriptRoot 'output/private/report/report_registry.json') 2>&1 | Tee-Object -FilePath $log -Append
    } else {
      & $Python -u (Join-Path $PSScriptRoot $script) 2>&1 | Tee-Object -FilePath $log -Append
    }
    $code=$LASTEXITCODE
    $ErrorActionPreference='Stop'
    if ($code -ne 0) { throw "$script stopped ($code); saved results retained." }
  }
  'Report and public byproducts rendered. Mandatory visual review, disclosure scan and full completion audit remain required.' | Tee-Object -FilePath $log -Append
} finally { $lock.Dispose() }
