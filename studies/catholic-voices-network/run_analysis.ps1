param([string]$Workdir = $env:DIGIKAT_VOICES_WORKDIR,
      [string]$Python = (Join-Path $env:USERPROFILE 'venvs/digikat-nlp/Scripts/python.exe'),
      [switch]$Smoke, [int]$Limit = 0)
$ErrorActionPreference = 'Stop'
if (!$Workdir) { throw 'Supply -Workdir or set DIGIKAT_VOICES_WORKDIR.' }
Set-Location (Resolve-Path (Join-Path $PSScriptRoot '../..'))
$env:DIGIKAT_VOICES_WORKDIR = $Workdir
$env:PYTHONUTF8 = '1'
$env:PYTHONUNBUFFERED = '1'
$lock = [System.IO.File]::Open((Join-Path $Workdir 'runner.lock'), 'OpenOrCreate', 'ReadWrite', 'None')
try {
  $log = Join-Path $Workdir ('analysis-' + (Get-Date -Format 'yyyyMMdd-HHmmss') + '.log')
  $arguments = @('-u', (Join-Path $PSScriptRoot '02_pilot_ner.py'))
  if ($Smoke) { $arguments += '--smoke' }
  if ($Limit -gt 0) { $arguments += @('--limit', "$Limit") }
  $ErrorActionPreference = 'Continue'
  & $Python @arguments 2>&1 | Tee-Object -FilePath $log
  $code = $LASTEXITCODE
  $ErrorActionPreference = 'Stop'
  if ($code -ne 0) { throw "Analysis stopped (exit $code). Saved documents retained. See $log" }
  if (!$Smoke -and $Limit -eq 0) {
    & $Python (Join-Path $PSScriptRoot 'verify_pilot.py')
    if ($LASTEXITCODE -ne 0) { throw 'Completed pilot verification failed.' }
  }
  Write-Output 'NER pilot finished. See pilot_report.json; dependency/inflection and LLM pilots remain pending.'
} finally { $lock.Dispose() }
