param([string]$Workdir=$env:DIGIKAT_VOICES_WORKDIR,
      [string]$Python=(Join-Path $env:USERPROFILE 'venvs/digikat-nlp/Scripts/python.exe'))
$ErrorActionPreference='Stop'
if (!$Workdir) { throw 'Supply -Workdir.' }
Set-Location (Resolve-Path (Join-Path $PSScriptRoot '../..'))
$env:DIGIKAT_VOICES_WORKDIR=$Workdir
$env:PYTHONUTF8='1'
$env:PYTHONUNBUFFERED='1'
$lock=$null
while (!$lock) {
  try { $lock=[System.IO.File]::Open((Join-Path $Workdir 'runner.lock'),'OpenOrCreate','ReadWrite','None') }
  catch [System.IO.IOException] { Start-Sleep -Seconds 30 }
}
try {
  $log=Join-Path $Workdir ('next-checks-'+(Get-Date -Format 'yyyyMMdd-HHmmss')+'.log')
  function Invoke-Stage([string]$Script,[string[]]$Extra=@()) {
    $ErrorActionPreference='Continue'
    & $Python -u (Join-Path $PSScriptRoot $Script) @Extra 2>&1 | Tee-Object -FilePath $log -Append
    $code=$LASTEXITCODE
    $ErrorActionPreference='Stop'
    if ($code -ne 0) { throw "$Script stopped (exit $code); committed results retained." }
  }
  # Get bounded semantic feedback before committing the GPU to the remaining
  # long NER run. All stages reuse their individually persisted outputs.
  Invoke-Stage '40_validate_coder.py' @('--model','qwen3:14b')
  Invoke-Stage '41_benchmark_repaired.py' @('--model','qwen3:14b')
  $synthetic=Get-Content -Encoding UTF8 (Join-Path $Workdir 'synthetic_v4_qwen3_14b_report.json') -Raw | ConvertFrom-Json
  $speed=Get-Content -Encoding UTF8 (Join-Path $Workdir 'benchmark_v4_qwen3_14b_report.json') -Raw | ConvertFrom-Json
  if (!$synthetic.synthetic_gate_passed -or !$speed.throughput_gate_passed) {
    Invoke-Stage '40_validate_coder.py' @('--model','qwen3:8b')
    Invoke-Stage '41_benchmark_repaired.py' @('--model','qwen3:8b')
  }
  Invoke-Stage '40_validate_coder.py' @('--model','gemma3:12b')
  Invoke-Stage '10_ner.py'
  Invoke-Stage '11_gazetteer_recall.py'
  Invoke-Stage '22_offices.py'
  Invoke-Stage '15_circulation.py'
  'Implemented next checks complete. Identity/speech layers and final report still pending; no main LLM run authorized.' | Tee-Object -FilePath $log -Append
} finally { $lock.Dispose() }
