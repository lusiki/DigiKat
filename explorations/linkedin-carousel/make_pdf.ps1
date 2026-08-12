# Render the LinkedIn carousel to a square, multi-page PDF and to per-slide PNGs.
# Read-only with respect to data/, pages/, docs/ and studies/ (exploration protocol rule 1).
#
#   pwsh explorations/linkedin-carousel/make_pdf.ps1

$ErrorActionPreference = 'Stop'

$here    = Split-Path -Parent $MyInvocation.MyCommand.Path
$source  = Join-Path $here 'carousel.html'
$outDir  = Join-Path $here 'output'
$pdfPath = Join-Path $outDir 'digikat-karusel-objaviti-ne-znaci-biti-cut.pdf'

if (-not (Test-Path $source)) { throw "Missing source: $source" }
New-Item -ItemType Directory -Force -Path $outDir | Out-Null

$chrome = @(
  'C:\Program Files\Google\Chrome\Application\chrome.exe',
  'C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe'
) | Where-Object { Test-Path $_ } | Select-Object -First 1
if (-not $chrome) { throw 'Neither Chrome nor Edge was found; both can print this page.' }

$uri = ([Uri]$source).AbsoluteUri

# Headless Chrome returns before its output file is flushed, so every call polls for the
# file and then for a stable size. Start-Process is deliberately NOT used: it joins
# -ArgumentList without quoting, which breaks on the spaces in this repository's path.
function Invoke-Chrome ([string[]] $Arguments, [string] $Expect) {
  if (Test-Path $Expect) { Remove-Item $Expect -Force }
  # Chrome reports success on stderr, which ErrorActionPreference='Stop' would turn fatal.
  $prev = $ErrorActionPreference
  $ErrorActionPreference = 'Continue'
  try { & $chrome @Arguments 2>&1 | Out-Null } finally { $ErrorActionPreference = $prev }
  $size = -1
  for ($i = 0; $i -lt 80; $i++) {
    Start-Sleep -Milliseconds 250
    if (Test-Path $Expect) {
      $now = (Get-Item $Expect).Length
      if ($now -gt 0 -and $now -eq $size) { return }
      $size = $now
    }
  }
}

Invoke-Chrome @(
  '--headless=new', '--disable-gpu', '--no-sandbox',
  '--no-pdf-header-footer', '--virtual-time-budget=5000',
  "--print-to-pdf=$pdfPath", $uri
) $pdfPath

if (-not (Test-Path $pdfPath)) { throw 'Chrome reported no error but wrote no PDF.' }

# One 1080 x 1080 PNG per slide, for a single-image post or a slide deck.
$shot = Join-Path $env:TEMP 'digikat_carousel_shot.html'
$js = @'
<script>
  var n = new URLSearchParams(location.search).get('s');
  if (n) { document.querySelectorAll('.slide').forEach(function (el, i) { if (i != (n - 1)) el.remove(); }); }
</script>
'@
(Get-Content $source -Raw -Encoding UTF8) + $js | Set-Content $shot -Encoding UTF8
$shotUri = ([Uri]$shot).AbsoluteUri

1..5 | ForEach-Object {
  $png = Join-Path $outDir "slide$_.png"
  Invoke-Chrome @(
    '--headless=new', '--disable-gpu', '--no-sandbox', '--hide-scrollbars',
    '--window-size=1080,1080', '--virtual-time-budget=3000',
    "--screenshot=$png", "$shotUri`?s=$_"
  ) $png
  if (-not (Test-Path $png)) { throw "Screenshot of slide $_ was not written." }
}
Remove-Item $shot -ErrorAction SilentlyContinue

# ISO-8859-1 by code page: [Text.Encoding]::Latin1 exists only on .NET Core, not on
# Windows PowerShell 5.1. Byte-preserving either way, which is what the scan needs.
$pages = ([regex]::Matches(
  [IO.File]::ReadAllText($pdfPath, [Text.Encoding]::GetEncoding(28591)), '/Type\s*/Page[^s]')).Count
Write-Host ''
Write-Host "PDF:    $pdfPath"
Write-Host "Pages:  $pages (expected 5)"
Write-Host "PNGs:   $outDir\slide1..5.png"
if ($pages -ne 5) { throw "Expected 5 pages, produced $pages. Check the page-break CSS." }
