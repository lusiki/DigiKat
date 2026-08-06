[CmdletBinding()]
param(
  [string[]]$Only,
  [switch]$SkipPdf
)

$ErrorActionPreference = "Stop"
$repoRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot ".."))
$paperDir = Join-Path $repoRoot "assets\papers"
$utf8NoBom = New-Object Text.UTF8Encoding($false)

$profiles = @{
  "trzista-paznje" = "trzista-paznje"
  "memorijalni-okvir" = "hodocasnicki-turizam"
  "katolicki-influenceri" = "katolicki-influenceri"
  "redovnicke-zajednice" = "redovnicke-zajednice"
  "crkva-i-dezinformacije" = "crkva-i-dezinformacije"
  "inflation-information-delayed-repricing" = "inflacija-i-religija"
  "socijalni-nauk-i-gospodarstvo" = "socijalni-nauk-i-gospodarstvo"
}

$papers = @(
  [pscustomobject]@{
    Stem = "trzista-paznje"
    SourceHtml = "https://raw.githubusercontent.com/lusiki/Mapping-Catholic-Digital-Media-Space/2deb813e3c31f22e762ec7dfb01ae4157155f6ce/paper/hr/drafts/attention_markets_paper_hr_v7.html"
    SourceDocx = $null
    Authors = @(
      [pscustomobject]@{ Name = "Luka Šikić"; Url = "https://www.lukasikic.info/" },
      [pscustomobject]@{ Name = "Petra Palić"; Url = "https://www.unicath.hr/odjeli-i-fakultet/nastavnici/petra-palic" },
      [pscustomobject]@{ Name = "Siniša Kovačić"; Url = "https://vijesti.hrt.hr/hrvatska/sinisa-kovacic-izabran-za-novog-ravnatelja-hine-12346782" }
    )
    InjectByline = $false
    Affiliation = ""
  },
  [pscustomobject]@{
    Stem = "memorijalni-okvir"
    SourceHtml = "https://raw.githubusercontent.com/lusiki/Memorijalni-okvir/78ccc07da5665aecaf1577ef53c09e8eff87302d/manuscript/manuscript_one.html"
    SourceDocx = "https://raw.githubusercontent.com/lusiki/Memorijalni-okvir/78ccc07da5665aecaf1577ef53c09e8eff87302d/manuscript/manuscript_one.docx"
    Authors = @(
      [pscustomobject]@{ Name = "Matea Topić Crnoja"; Url = "https://www.unicath.hr/odjeli-i-fakultet/nastavnici/matea-topic-crnoja" },
      [pscustomobject]@{ Name = "Petra Palić"; Url = "https://www.unicath.hr/odjeli-i-fakultet/nastavnici/petra-palic" },
      [pscustomobject]@{ Name = "Luka Šikić"; Url = "https://www.lukasikic.info/" }
    )
    InjectByline = $false
    Affiliation = ""
  },
  [pscustomobject]@{
    Stem = "katolicki-influenceri"
    SourceHtml = "https://raw.githubusercontent.com/lusiki/Katolicki_Influenceri/fa34ff5ae1c8027c355f2523d404c8febf03a24a/code/analysis_hr.html"
    SourceDocx = $null
    Authors = @(
      [pscustomobject]@{ Name = "DigiKat Projekt"; Url = "https://lusiki.github.io/DigiKat/" }
    )
    InjectByline = $false
    Affiliation = "Hrvatsko katoličko sveučilište"
  },
  [pscustomobject]@{
    Stem = "redovnicke-zajednice"
    SourceHtml = "https://raw.githubusercontent.com/lusiki/Redovnicke-zajednice/74f1a1a8877f4cbe06af4fb1fcdc7ca2c8eb57d1/R/analysis_v3.html"
    SourceDocx = $null
    Authors = @(
      [pscustomobject]@{ Name = "DigiKat Project"; Url = "https://lusiki.github.io/DigiKat/" }
    )
    InjectByline = $false
    Affiliation = "Hrvatsko katoličko sveučilište"
  },
  [pscustomobject]@{
    Stem = "crkva-i-dezinformacije"
    SourceHtml = "https://raw.githubusercontent.com/lusiki/Church-and-dezinfo/6dffe79e33f1ad2e139c19a2b93b3135946abcf2/papers/03_framing_paper_2.html"
    SourceDocx = $null
    Authors = @()
    InjectByline = $false
    Affiliation = ""
  },
  [pscustomobject]@{
    Stem = "inflation-information-delayed-repricing"
    SourceHtml = Join-Path $repoRoot "studies\inflation-salience\output\paper\PAPER_EMIP_v2_full.html"
    SourceDocx = Join-Path $repoRoot "studies\inflation-salience\output\paper\PAPER_EMIP_v2_full.docx"
    Authors = @(
      [pscustomobject]@{ Name = "Luka Šikić"; Url = "https://www.lukasikic.info/" },
      [pscustomobject]@{ Name = "Petra Palić"; Url = "https://www.unicath.hr/odjeli-i-fakultet/nastavnici/petra-palic" }
    )
    InjectByline = $false
    Affiliation = "Hrvatsko katoličko sveučilište"
  },
  [pscustomobject]@{
    Stem = "socijalni-nauk-i-gospodarstvo"
    SourceHtml = Join-Path $repoRoot "studies\moral-economy\output\paper\PAPER_RSP_v2.html"
    SourceDocx = $null
    Authors = @(
      [pscustomobject]@{ Name = "Luka Šikić"; Url = "https://www.lukasikic.info/" }
    )
    InjectByline = $true
    Affiliation = "Hrvatsko katoličko sveučilište"
  }
)

function Get-RemoteBytes([string]$Url) {
  $client = New-Object Net.WebClient
  try {
    $client.Headers.Add("User-Agent", "DigiKat thematic-paper publisher")
    return $client.DownloadData($Url)
  }
  finally {
    $client.Dispose()
  }
}

function Read-HtmlSource([string]$Source) {
  if ($Source -match '^https://') {
    return [Text.Encoding]::UTF8.GetString((Get-RemoteBytes $Source))
  }
  if (-not (Test-Path -LiteralPath $Source)) { throw "Missing HTML source: $Source" }
  return [IO.File]::ReadAllText($Source, [Text.Encoding]::UTF8)
}

function Copy-DocumentSource([string]$Source, [string]$Target) {
  if (-not $Source) { return }
  if ($Source -match '^https://') {
    [IO.File]::WriteAllBytes($Target, (Get-RemoteBytes $Source))
  }
  else {
    if (-not (Test-Path -LiteralPath $Source)) { throw "Missing document source: $Source" }
    Copy-Item -LiteralPath $Source -Destination $Target -Force
  }
}

function Html-Encode([string]$Value) {
  return [Net.WebUtility]::HtmlEncode($Value)
}

function Remove-PreviousChrome([string]$Html) {
  $Html = [regex]::Replace($Html, '(?is)<!-- digikat-paper:head:start -->.*?<!-- digikat-paper:head:end -->', '')
  $Html = [regex]::Replace($Html, '(?is)<!-- digikat-paper:bar:start -->.*?<!-- digikat-paper:bar:end -->', '')
  $Html = [regex]::Replace($Html, '(?is)<!-- digikat-paper:footer:start -->.*?<!-- digikat-paper:footer:end -->', '')
  $Html = [regex]::Replace($Html, '(?is)(?:<!-- Site header.*?-->\s*)?<div class="dk-topbar">.*?</nav>\s*</div>\s*</div>', '')
  $Html = [regex]::Replace($Html, '(?is)<footer class="dk-footer">.*?</footer>', '')
  return $Html
}

function Link-TitleAuthors([string]$Html, $Authors, [bool]$InjectByline, [string]$Affiliation) {
  $titleMatch = [regex]::Match($Html, '(?is)<header\b[^>]*id="title-block-header"[^>]*>.*?</header>')
  if (-not $titleMatch.Success) { throw "Could not locate #title-block-header" }

  $header = $titleMatch.Value
  foreach ($author in $Authors) {
    Write-Verbose ("Linking title author: " + $author.Name)
    $escapedName = [regex]::Escape($author.Name)
    if ($header -match ('class="digikat-author-link"[^>]*>\s*' + $escapedName)) { continue }
    $anchor = '<a class="digikat-author-link" rel="author" href="' + (Html-Encode $author.Url) + '">' + (Html-Encode $author.Name) + '</a>'
    $header = $header.Replace($author.Name, $anchor)
  }

  if ($InjectByline) {
    $links = @($Authors | ForEach-Object {
      '<a class="digikat-author-link" rel="author" href="' + (Html-Encode $_.Url) + '">' + (Html-Encode $_.Name) + '</a>'
    }) -join ', '
    $label = if (@($Authors).Count -gt 1) { 'Autori' } else { 'Autor' }
    $byline = '<div class="digikat-paper-byline"><div class="digikat-paper-byline__label">' + $label + '</div><p class="digikat-paper-byline__names">' + $links + '</p>'
    if ($Affiliation) {
      $byline += '<p class="digikat-paper-byline__affiliation">' + (Html-Encode $Affiliation) + '</p>'
    }
    $byline += '</div>'
    $header = $header -replace '(?is)</header>\s*$', ($byline + '</header>')
  }

  return $Html.Substring(0, $titleMatch.Index) + $header + $Html.Substring($titleMatch.Index + $titleMatch.Length)
}

function Update-EmbeddedFormatLinks([string]$Html, [string]$Stem, [bool]$HasWord) {
  $anchorPattern = '(?is)<a\b(?<attrs>[^>]*?)href=(?<quote>["''])(?<href>.*?)(\k<quote>)(?<tail>[^>]*)>(?<label>.*?)</a>'
  return [regex]::Replace($Html, $anchorPattern, [Text.RegularExpressions.MatchEvaluator]{
    param($match)
    $href = $match.Groups['href'].Value
    if ($href -match '(?i)\.pdf(?:[?#].*)?$') {
      return '<a' + $match.Groups['attrs'].Value + 'href="' + $Stem + '.pdf"' + $match.Groups['tail'].Value + '>' + $match.Groups['label'].Value + '</a>'
    }
    if ($href -match '(?i)\.docx(?:[?#].*)?$') {
      if ($HasWord) {
        return '<a' + $match.Groups['attrs'].Value + 'href="' + $Stem + '.docx"' + $match.Groups['tail'].Value + '>' + $match.Groups['label'].Value + '</a>'
      }
      return '<span class="paper-format-unavailable" title="Word izdanje nije objavljeno">' + $match.Groups['label'].Value + '</span>'
    }
    return $match.Value
  })
}

function Get-PaperBar([string]$Stem, [string]$ProfileSlug, [bool]$HasWord) {
  $formatLinks = @(
    '<a data-format="html" aria-current="page" href="' + $Stem + '.html">HTML</a>',
    '<a data-format="pdf" href="' + $Stem + '.pdf">PDF</a>'
  )
  if ($HasWord) { $formatLinks += '<a data-format="docx" href="' + $Stem + '.docx">Word</a>' }

  return @"
<!-- digikat-paper:bar:start -->
<div class="digikat-paper-nav" role="navigation" aria-label="Navigacija rada">
  <div class="digikat-paper-nav__inner">
    <a class="digikat-paper-nav__brand" href="https://lusiki.github.io/DigiKat/">DigiKat</a>
    <span class="digikat-paper-nav__context">Tematsko istraživanje</span>
    <nav class="digikat-paper-nav__links" aria-label="Rad i dostupni formati">
      <a href="https://lusiki.github.io/DigiKat/pages/studije/$ProfileSlug.html">Profil rada</a>
      $($formatLinks -join "`n      ")
    </nav>
  </div>
</div>
<!-- digikat-paper:bar:end -->
"@
}

function Get-PaperFooter {
  return @"
<!-- digikat-paper:footer:start -->
<footer class="digikat-paper-footer">
  <div class="digikat-paper-footer__inner">
    <span><strong>DigiKat</strong> · Hrvatsko katoličko sveučilište</span>
    <a href="https://lusiki.github.io/DigiKat/pages/baza.html">Baza podataka</a>
    <a href="https://github.com/lusiki/DigiKat">GitHub</a>
    <span class="digikat-paper-footer__license">CC BY 4.0 · © 2021.–2026. DigiKat</span>
  </div>
</footer>
<!-- digikat-paper:footer:end -->
"@
}

$chromeCandidates = @(
  "C:\Program Files\Google\Chrome\Application\chrome.exe",
  "C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe",
  "C:\Program Files\Microsoft\Edge\Application\msedge.exe"
)
$chrome = $chromeCandidates | Where-Object { Test-Path -LiteralPath $_ } | Select-Object -First 1
if (-not $SkipPdf -and -not $chrome) { throw "Chrome or Edge is required to create the uniform PDFs." }

foreach ($paper in $papers) {
  if ($Only -and $paper.Stem -notin $Only) { continue }

  Write-Host "[paper] $($paper.Stem)"
  $html = Read-HtmlSource $paper.SourceHtml
  $html = Remove-PreviousChrome $html
  $html = Link-TitleAuthors -Html $html -Authors @($paper.Authors) -InjectByline $paper.InjectByline -Affiliation $paper.Affiliation
  $hasWord = [bool]$paper.SourceDocx
  $html = Update-EmbeddedFormatLinks $html $paper.Stem $hasWord

  $head = @"
<!-- digikat-paper:head:start -->
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link href="https://fonts.googleapis.com/css2?family=Source+Serif+4:opsz,wght@8..60,400;8..60,500;8..60,600;8..60,700&amp;family=Source+Sans+3:wght@400;500;600;700&amp;family=IBM+Plex+Mono:wght@400;500;600&amp;display=swap" rel="stylesheet">
<link href="digikat-paper.css" rel="stylesheet">
<!-- digikat-paper:head:end -->
"@
  if ($html -notmatch '(?is)</head>') { throw "Could not locate </head> in $($paper.Stem)" }
  $html = [regex]::Replace($html, '(?is)</head>', ($head + "`n</head>"), 1)

  $bar = Get-PaperBar $paper.Stem $profiles[$paper.Stem] $hasWord
  if ($html -notmatch '(?is)<body\b[^>]*>') { throw "Could not locate <body> in $($paper.Stem)" }
  $html = [regex]::Replace($html, '(?is)(<body\b[^>]*>)', ('$1' + "`n" + $bar), 1)

  $footer = Get-PaperFooter
  if ($html -notmatch '(?is)</body>') { throw "Could not locate </body> in $($paper.Stem)" }
  $html = [regex]::Replace($html, '(?is)</body>', ($footer + "`n</body>"), 1)

  $htmlTarget = Join-Path $paperDir ($paper.Stem + '.html')
  [IO.File]::WriteAllText($htmlTarget, $html, $utf8NoBom)
  Write-Host ("  html  {0:N0} KB" -f ((Get-Item -LiteralPath $htmlTarget).Length / 1KB))

  if ($hasWord) {
    $docxTarget = Join-Path $paperDir ($paper.Stem + '.docx')
    Copy-DocumentSource $paper.SourceDocx $docxTarget
    Write-Host ("  docx  {0:N0} KB" -f ((Get-Item -LiteralPath $docxTarget).Length / 1KB))
  }

  if (-not $SkipPdf) {
    $pdfTarget = Join-Path $paperDir ($paper.Stem + '.pdf')
    if (Test-Path -LiteralPath $pdfTarget) { Remove-Item -LiteralPath $pdfTarget -Force }
    $htmlUri = ([Uri](Get-Item -LiteralPath $htmlTarget).FullName).AbsoluteUri
    $args = @(
      '--headless=new',
      '--disable-gpu',
      '--no-pdf-header-footer',
      '--run-all-compositor-stages-before-draw',
      '--virtual-time-budget=5000',
      ('--print-to-pdf=' + $pdfTarget),
      $htmlUri
    )
    & $chrome @args | Out-Host
    if (-not (Test-Path -LiteralPath $pdfTarget)) { throw "PDF generation failed for $($paper.Stem)" }
    Write-Host ("  pdf   {0:N0} KB" -f ((Get-Item -LiteralPath $pdfTarget).Length / 1KB))
  }
}

Write-Host "[done] Thematic papers published to assets/papers/."
