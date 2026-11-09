param([string]$Workdir=$env:DIGIKAT_VOICES_WORKDIR,
      [string]$Python=(Join-Path $env:USERPROFILE 'venvs/digikat-nlp/Scripts/python.exe'))
$ErrorActionPreference='Stop'
if (!$Workdir) { throw 'Supply -Workdir.' }
Set-Location (Resolve-Path (Join-Path $PSScriptRoot '../..'))
$env:DIGIKAT_VOICES_WORKDIR=$Workdir
$env:PYTHONUTF8='1'
$env:PYTHONUNBUFFERED='1'
# A complete circulation report is written atomically only at the end of the
# preceding runner. A stale report from another corpus must not satisfy this.
$expected=(Get-Content -Encoding UTF8 (Join-Path $PSScriptRoot '../../data/digikat_corpus_manifest.json') -Raw | ConvertFrom-Json).corpus.sha256
while ($true) {
  $ready=Join-Path $Workdir 'circulation_report.json'
  if (Test-Path -LiteralPath $ready) {
    $saved=Get-Content -Encoding UTF8 $ready -Raw | ConvertFrom-Json
    if ($saved.corpus_sha256 -ne $expected) { throw 'Preceding stage belongs to another corpus.' }
    break
  }
  Start-Sleep -Seconds 30
}
$lock=$null
while (!$lock) {
  try { $lock=[System.IO.File]::Open((Join-Path $Workdir 'runner.lock'),'OpenOrCreate','ReadWrite','None') }
  catch [System.IO.IOException] { Start-Sleep -Seconds 30 }
}
try {
  $log=Join-Path $Workdir ('identity-'+(Get-Date -Format 'yyyyMMdd-HHmmss')+'.log')
  function Invoke-Stage([string]$Script,[string[]]$Extra=@()) {
    $ErrorActionPreference='Continue'
    & $Python -u (Join-Path $PSScriptRoot $Script) @Extra 2>&1 | Tee-Object -FilePath $log -Append
    $code=$LASTEXITCODE
    $ErrorActionPreference='Stop'
    if ($code -ne 0) { throw "$Script stopped (exit $code); saved results retained." }
  }
  if (!(Test-Path -LiteralPath (Join-Path $Workdir 'forms_smoke_report.json'))) {
    Invoke-Stage '20_forms.py' @('--limit','100')
  }
  Invoke-Stage 'verify_forms_smoke.py'
  Invoke-Stage '20_forms.py'
  Invoke-Stage '21_cluster.py'
  Invoke-Stage '23_wikidata_link.py'
  'Forms, clusters and public-name linking complete. Dated title-only resolution, speech, agreement and report remain pending.' | Tee-Object -FilePath $log -Append
} finally { $lock.Dispose() }
