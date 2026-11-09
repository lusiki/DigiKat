param([string]$Workdir=$env:DIGIKAT_VOICES_WORKDIR,
      [string]$Python=(Join-Path $env:USERPROFILE 'venvs/digikat-nlp/Scripts/python.exe'),
      [switch]$WaitForNetworkInputs)
$ErrorActionPreference='Stop'
if (!$Workdir) { throw 'Supply -Workdir.' }
Set-Location (Resolve-Path (Join-Path $PSScriptRoot '../..'))
$env:DIGIKAT_VOICES_WORKDIR=$Workdir
$env:PYTHONUTF8='1'
$env:PYTHONUNBUFFERED='1'
$expected=(Get-Content -Encoding UTF8 (Join-Path $PSScriptRoot '../../data/digikat_corpus_manifest.json') -Raw | ConvertFrom-Json).corpus.sha256
while ($true) {
  $ready=Join-Path $Workdir 'wikidata_link_report.json'
  if (Test-Path -LiteralPath $ready) {
    $saved=Get-Content -Encoding UTF8 $ready -Raw | ConvertFrom-Json
    if ($saved.corpus_sha256 -ne $expected) { throw 'Identity checkpoint belongs to another corpus.' }
    break
  }
  Start-Sleep -Seconds 30
}
if ($WaitForNetworkInputs) {
  $ready=Join-Path $Workdir 'network_inputs_report.json'
  while (!(Test-Path -LiteralPath $ready)) { Start-Sleep -Seconds 30 }
  $saved=Get-Content -Encoding UTF8 $ready -Raw | ConvertFrom-Json
  if ($saved.corpus_sha256 -ne $expected) { throw 'Network input checkpoint belongs to another corpus.' }
}
$lock=$null
while (!$lock) {
  try { $lock=[System.IO.File]::Open((Join-Path $Workdir 'runner.lock'),'OpenOrCreate','ReadWrite','None') }
  catch [System.IO.IOException] { Start-Sleep -Seconds 30 }
}
try {
  $log=Join-Path $Workdir ('speech-'+(Get-Date -Format 'yyyyMMdd-HHmmss')+'.log')
  function Invoke-Stage([string]$Script,[string[]]$Extra=@()) {
    $ErrorActionPreference='Continue'
    & $Python -u (Join-Path $PSScriptRoot $Script) @Extra 2>&1 | Tee-Object -FilePath $log -Append
    $code=$LASTEXITCODE
    $ErrorActionPreference='Stop'
    if ($code -ne 0) { throw "$Script stopped (exit $code); saved results retained." }
  }
  Invoke-Stage '24_resolve_mentions.py'
  Invoke-Stage '25_prepare_candidates.py'
  if (!(Test-Path -LiteralPath (Join-Path $Workdir 'rule_smoke_report.json'))) {
    Invoke-Stage '30_quote_rules.py' @('--limit','100')
  }
  Invoke-Stage 'verify_rule_smoke.py'
  Invoke-Stage '30_quote_rules.py'
  'Rule tier complete. Actual-passage agreement, determinism, main coding, networks and report remain gated.' | Tee-Object -FilePath $log -Append
} finally { $lock.Dispose() }
