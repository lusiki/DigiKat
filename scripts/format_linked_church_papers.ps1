[CmdletBinding()]
param(
  [string]$Cache = "tmp/church-papers-publication",
  [string]$Python = "python"
)
$ErrorActionPreference = "Stop"
$repoRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$cachePath = [IO.Path]::GetFullPath((Join-Path $repoRoot $Cache))
$pandoc = Join-Path (Split-Path (Get-Command quarto).Source) 'tools/pandoc.exe'
& $Python (Join-Path $PSScriptRoot 'prepare_linked_church_papers.py') --cache $cachePath
if ($LASTEXITCODE -ne 0) { throw 'Manuscript preparation failed' }
$documents = @()
foreach ($stem in @('crkva-i-dezinformacije', 'sadrzaj-ili-identitet')) {
  $docx = Join-Path $cachePath "$stem.docx"
  & $pandoc (Join-Path $cachePath "$stem.print.html") --from=html+tex_math_single_backslash --to=docx --standalone --output=$docx
  if ($LASTEXITCODE -ne 0) { throw "Pandoc failed for $stem" }
  $documents += $docx
}
& $Python (Join-Path $PSScriptRoot 'style_linked_church_papers.py') @documents
if ($LASTEXITCODE -ne 0) { throw 'Document styling failed' }
