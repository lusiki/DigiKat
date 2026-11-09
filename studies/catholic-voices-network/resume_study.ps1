param([string]$Workdir=$env:DIGIKAT_VOICES_WORKDIR)
$ErrorActionPreference='Stop'
if (!$Workdir) { throw 'Supply -Workdir.' }
# Reuses committed work. Each child owns the common runner lock and stops on a
# real failure; missing stages are not treated as completed. No model main run
# is authorized by this launcher until its independent publication gates exist.
& (Join-Path $PSScriptRoot 'run_next_checks.ps1') -Workdir $Workdir
& (Join-Path $PSScriptRoot 'run_identity.ps1') -Workdir $Workdir
& (Join-Path $PSScriptRoot 'run_speech.ps1') -Workdir $Workdir
& (Join-Path $PSScriptRoot 'run_networks.ps1') -Workdir $Workdir
& (Join-Path $PSScriptRoot 'run_report_metrics.ps1') -Workdir $Workdir
Write-Output 'Implemented stages through report rendering finished. Final visual verification, disclosure scan and completion audit remain required.'
