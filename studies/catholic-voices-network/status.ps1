param([string]$Workdir = $env:DIGIKAT_VOICES_WORKDIR)
if (!$Workdir) { throw 'Supply -Workdir or set DIGIKAT_VOICES_WORKDIR.' }
$latest = Get-ChildItem -LiteralPath $Workdir -Filter '*.log' |
  Sort-Object LastWriteTime -Descending | Select-Object -First 1
if (!$latest) { Write-Output 'No run log found.'; exit 1 }
Write-Output $latest.FullName
Get-Content -LiteralPath $latest.FullName -Tail 8
# Log inspection works while DuckDB is locked by its writer; logs are not the resume ledger.
Get-Item -LiteralPath (Join-Path $Workdir 'voices.duckdb') -ErrorAction SilentlyContinue |
  Select-Object Name, Length, LastWriteTime

# Derive normalization progress from the resume baseline in the SAME run log.
# A counter from a resumed worker alone excludes forms saved by earlier runs.
$manifest=Get-Content -LiteralPath (Join-Path $PSScriptRoot '../../data/digikat_corpus_manifest.json') -Encoding UTF8 -Raw | ConvertFrom-Json
$formsReport=Join-Path $Workdir 'forms_report.json'
if (Test-Path -LiteralPath $formsReport) {
  $forms=Get-Content -LiteralPath $formsReport -Encoding UTF8 -Raw | ConvertFrom-Json
  if ($forms.corpus_sha256 -ne $manifest.corpus.sha256) { throw 'Normalization report corpus mismatch.' }
  Write-Output ('Normalization complete: {0:N0} forms (saved completion report).' -f $forms.forms)
}
$identity = Get-ChildItem -LiteralPath $Workdir -Filter 'identity-*.log' |
  Where-Object { $_.Name -match '^identity-\d{8}-\d{6}\.log$' } |
  Sort-Object Name -Descending | Select-Object -First 1
if ($identity -and !(Test-Path -LiteralPath $formsReport)) {
  $baseline = $null; $total = $null; $newlySaved = 0; $lastProgress = $null
  foreach ($line in Get-Content -LiteralPath $identity.FullName) {
    if ($line -match 'Morphology smoke passed: \d+/(\d+) forms aligned; \d+/(\d+) forms remain') {
      $baseline = [long]$Matches[1]; $total = [long]$Matches[2]; $newlySaved = 0
    } elseif ($null -ne $baseline -and $line -match 'form lemmas newly saved (\d+)') {
      $newlySaved = [long]$Matches[1]; $lastProgress = [string]$line
    }
  }
  if ($null -ne $baseline) {
    $saved = $baseline + $newlySaved
    Write-Output ('Normalization: at least {0:N0} / {1:N0} forms saved ({2:N1}%).' -f $saved,$total,(100*$saved/$total))
    Write-Output ('Source: ' + $identity.FullName)
    if ($lastProgress) { Write-Output $lastProgress }
    Write-Output 'Log-derived checkpoint count; this does not establish that a worker is currently alive.'
  }
}

# The pending denominator in each resumed resolution run excludes earlier saves.
$resolutionReport=Join-Path $Workdir 'identity_resolution_report.json'
if (Test-Path -LiteralPath $resolutionReport) {
  $resolution=Get-Content -LiteralPath $resolutionReport -Encoding UTF8 -Raw | ConvertFrom-Json
  if ($resolution.corpus_sha256 -ne $manifest.corpus.sha256) { throw 'Resolution report corpus mismatch.' }
  Write-Output ('Dated resolution complete: {0:N0} documents (saved completion report).' -f $resolution.documents)
} else {
  $speech=Get-ChildItem -LiteralPath $Workdir -Filter 'speech-*.log' |
    Where-Object { $_.Name -match '^speech-\d{8}-\d{6}\.log$' } |
    Sort-Object Name -Descending | Select-Object -First 1
  if ($speech) {
    $progress=Get-Content -LiteralPath $speech.FullName | Select-String 'dated mention resolution (\d+) / (\d+)' | Select-Object -Last 1
    if ($progress) {
      $newlySaved=[long]$progress.Matches[0].Groups[1].Value
      $pendingAtStart=[long]$progress.Matches[0].Groups[2].Value
      $totalDocuments=[long]$manifest.corpus.rows
      $saved=$totalDocuments-$pendingAtStart+$newlySaved
      Write-Output ('Dated resolution: at least {0:N0} / {1:N0} documents saved ({2:N1}%).' -f $saved,$totalDocuments,(100*$saved/$totalDocuments))
      Write-Output ('Source: '+$speech.FullName)
    }
  }
}
$candidateReport=Join-Path $Workdir 'candidate_report.json'
$candidateProfile=Join-Path $Workdir 'candidate_runtime_profile.json'
if (Test-Path -LiteralPath $candidateReport) {
  $candidate=Get-Content -LiteralPath $candidateReport -Encoding UTF8 -Raw | ConvertFrom-Json
  if ($candidate.corpus_sha256 -ne $manifest.corpus.sha256) { throw 'Candidate report corpus mismatch.' }
  if ($candidate.complete) { Write-Output ('Passage preparation complete: {0:N0} documents.' -f $manifest.corpus.rows) }
} elseif (Test-Path -LiteralPath $candidateProfile) {
  # Allow the writer to atomically replace its diagnostic while this read is open.
  $stream=[System.IO.File]::Open($candidateProfile,[System.IO.FileMode]::Open,[System.IO.FileAccess]::Read,
    ([System.IO.FileShare]::ReadWrite -bor [System.IO.FileShare]::Delete))
  $reader=[System.IO.StreamReader]::new($stream,[System.Text.Encoding]::UTF8)
  try { $profile=$reader.ReadToEnd() | ConvertFrom-Json } finally { $reader.Dispose() }
  if ($profile.corpus_sha256 -ne $manifest.corpus.sha256) { throw 'Candidate profile corpus mismatch.' }
  $retained=($profile.baseline_documents_by_platform.PSObject.Properties.Value | Measure-Object -Sum).Sum
  $commits=$profile.cumulative.sql_commit.calls
  Write-Output ('Passage preparation: at least {0:N0} / {1:N0} documents saved ({2:N0} retained + {3:N0} new commits).' -f ($retained+$commits),$manifest.corpus.rows,$retained,$commits)
  Write-Output ('Timing checkpoint: '+$profile.created_utc)
}
$ruleReport=Join-Path $Workdir 'speech_rule_report.json'
if (Test-Path -LiteralPath $ruleReport) {
  $rules=Get-Content -LiteralPath $ruleReport -Encoding UTF8 -Raw | ConvertFrom-Json
  if ($rules.corpus_sha256 -ne $manifest.corpus.sha256) { throw 'Rule report corpus mismatch.' }
  Write-Output ('Rule parsing report: {0:N0} sentences, {1:N0} parse failures, {2:N0} windows.' -f $rules.sentences,$rules.parse_failures,$rules.windows)
} else {
  $speech=Get-ChildItem -LiteralPath $Workdir -Filter 'speech-*.log' |
    Where-Object { $_.Name -match '^speech-\d{8}-\d{6}\.log$' } |
    Sort-Object Name -Descending | Select-Object -First 1
  if ($speech) {
    $ruleBaseline=$null; $ruleNew=@{standard=0L; nonstandard=0L}; $newFailures=0L; $lastRuleLine=$null
    foreach ($line in Get-Content -LiteralPath $speech.FullName -Encoding UTF8) {
      if ($line -match 'rule resume baseline (\{.*\})') {
        $ruleBaseline=$Matches[1] | ConvertFrom-Json
        $ruleNew=@{standard=0L; nonstandard=0L}; $newFailures=0L; $lastRuleLine=$line
      } elseif ($null -ne $ruleBaseline -and $line -match 'rule sentences saved (standard|nonstandard) (\d+) / \d+ failures_this_run (\d+)') {
        $ruleNew[$Matches[1]]=[long]$Matches[2]; $newFailures=[long]$Matches[3]; $lastRuleLine=$line
      }
    }
    if ($null -ne $ruleBaseline) {
      $saved=[long]$ruleBaseline.saved+$ruleNew.standard+$ruleNew.nonstandard
      $failed=[long]$ruleBaseline.failed+$newFailures
      Write-Output ('Rule parsing checkpoint: {0:N0} / {1:N0} attempted sentences saved; {2:N0} recorded failures at this checkpoint.' -f $saved,$ruleBaseline.needed,$failed)
      Write-Output ('Source: '+$speech.FullName)
      Write-Output $lastRuleLine
    }
  }
}
Write-Output 'Saved reports and log-derived counts do not establish current process liveness.'
