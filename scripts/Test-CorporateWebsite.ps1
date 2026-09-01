[CmdletBinding()]
param(
    [string]$SitePath = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path,
    [switch]$Live,
    [string]$CorporateBaseUrl = 'http://127.0.0.1:8766',
    [string]$ProductBaseUrl = 'http://127.0.0.1:8765'
)

$ErrorActionPreference = 'Stop'
$siteRoot = (Resolve-Path $SitePath).Path
$failures = [System.Collections.Generic.List[string]]::new()

function Assert-SiteCondition {
    param([bool]$Condition, [string]$Message)
    if (-not $Condition) { $script:failures.Add($Message) }
}

function Get-LocalTarget {
    param([string]$SourceFile, [string]$Reference)
    $referencePath = ($Reference -split '[?#]', 2)[0]
    if ([string]::IsNullOrWhiteSpace($referencePath)) { return $SourceFile }
    if ($referencePath.StartsWith('/')) {
        $relative = $referencePath.TrimStart('/')
        if ([string]::IsNullOrWhiteSpace($relative)) { $relative = 'index.html' }
        return Join-Path $siteRoot $relative
    }
    return Join-Path (Split-Path $SourceFile -Parent) $referencePath
}

foreach ($required in @('index.html', 'portfolio.css', 'local-preview.js', 'favicon.ico')) {
    Assert-SiteCondition (Test-Path (Join-Path $siteRoot $required) -PathType Leaf) "Missing required file: $required"
}

$homePageHtml = Get-Content (Join-Path $siteRoot 'index.html') -Raw
$styles = Get-Content (Join-Path $siteRoot 'portfolio.css') -Raw
$localPreview = Get-Content (Join-Path $siteRoot 'local-preview.js') -Raw

Assert-SiteCondition ($homePageHtml -match '(?i)<!doctype html>') 'index.html: missing HTML5 doctype'
Assert-SiteCondition ($homePageHtml -match '<html lang="en-GB">') 'index.html: missing en-GB language'
Assert-SiteCondition ($homePageHtml -match 'name="viewport"') 'index.html: missing viewport metadata'
Assert-SiteCondition ($homePageHtml -match 'name="robots" content="noindex, nofollow"') 'index.html: local-only noindex guard is missing'
Assert-SiteCondition ($homePageHtml -match 'class="skip-link"') 'index.html: keyboard skip link is missing'
Assert-SiteCondition ($homePageHtml -match 'id="main-content"') 'index.html: skip-link target is missing'
Assert-SiteCondition ($homePageHtml -match '<h1>Small software\.<br>Properly finished\.</h1>') 'index.html: corporate proposition is missing'
Assert-SiteCondition ($homePageHtml -match 'https://mindthecards\.technovaitsolutions\.com/') 'index.html: future standalone product link is missing'
Assert-SiteCondition ($homePageHtml -match 'Watch\. Remember\. Rebuild\.') 'index.html: Mind the Cards proposition is missing'
Assert-SiteCondition ($homePageHtml -match '21 themed games') 'index.html: full game collection is not explained'
Assert-SiteCondition ($homePageHtml -match 'Game Designer') 'index.html: Game Designer is not explained'
Assert-SiteCondition ($homePageHtml -match '3–100 cards') 'index.html: Designer sequence range is missing'
Assert-SiteCondition ($homePageHtml -match '0\.1–10 seconds') 'index.html: Designer timing range is missing'
Assert-SiteCondition ($homePageHtml -match 'No subscriptions and no adverts') 'index.html: permanent, advert-free product model is missing'
Assert-SiteCondition (([regex]::Matches($homePageHtml, 'Coming soon')).Count -ge 4) 'index.html: future products are not represented by Coming soon placeholders'
Assert-SiteCondition ($homePageHtml -match '<!--email_off-->.*?mailto:support@technovaitsolutions\.com.*?<!--/email_off-->') 'index.html: protected public support email is missing'

foreach ($forbidden in @('Recall Fun', 'Ultimate Code Breaker', 'Narrow the Number', 'PATHFINDER', 'Dominate Domains', 'In store review', 'In review')) {
    Assert-SiteCondition ($homePageHtml -notmatch [regex]::Escape($forbidden)) "index.html: forbidden pre-launch reference remains: $forbidden"
}

Assert-SiteCondition ($homePageHtml -notmatch 'src="https://mindthecards\.technovaitsolutions\.com') 'index.html: corporate site must not depend on product-site imagery'
Assert-SiteCondition ($homePageHtml -notmatch 'data-product-asset') 'index.html: local preview must not rewrite cross-site image assets'
Assert-SiteCondition ($homePageHtml -notmatch 'href="(?:about-us|contact-us)\.html') 'index.html: legacy page link remains on the modern homepage'

foreach ($match in [regex]::Matches($homePageHtml, '(?i)(?:href|src)="([^"]+)"')) {
    $reference = $match.Groups[1].Value
    if ($reference -match '^(?:https?:|mailto:|tel:|data:|#)') { continue }
    $localTarget = Get-LocalTarget -SourceFile (Join-Path $siteRoot 'index.html') -Reference $reference
    Assert-SiteCondition (Test-Path $localTarget -PathType Leaf) "index.html: broken local reference '$reference'"
}

Assert-SiteCondition ($styles -match ':focus-visible') 'portfolio.css: visible keyboard focus treatment is missing'
Assert-SiteCondition ($styles -match '@media\s*\(max-width:\s*760px\)') 'portfolio.css: phone layout is missing'
Assert-SiteCondition ($styles -match '@media\s*\(prefers-color-scheme:\s*dark\)') 'portfolio.css: dark appearance is missing'
Assert-SiteCondition ($styles -match '@media\s*\(prefers-reduced-motion:\s*reduce\)') 'portfolio.css: reduced-motion treatment is missing'

Assert-SiteCondition ($localPreview -match 'window\.location\.hostname === "127\.0\.0\.1"') 'local-preview.js: loopback guard is missing'
Assert-SiteCondition ($localPreview -match 'http://127\.0\.0\.1:8765') 'local-preview.js: local Mind the Cards URL is missing'
Assert-SiteCondition ($localPreview -match '\[data-product-link\]') 'local-preview.js: product-link rewrite is missing'
Assert-SiteCondition ($localPreview -notmatch 'fetch\(|XMLHttpRequest|sendBeacon') 'local-preview.js: unexpected network request code is present'

if ($Live) {
    foreach ($entry in @(
        @{ Name = 'Corporate homepage'; Url = "$($CorporateBaseUrl.TrimEnd('/'))/" },
        @{ Name = 'Mind the Cards homepage'; Url = "$($ProductBaseUrl.TrimEnd('/'))/" }
    )) {
        $response = Invoke-WebRequest -Uri $entry.Url -MaximumRedirection 3
        Assert-SiteCondition ($response.StatusCode -eq 200) "$($entry.Name) returned $($response.StatusCode): $($entry.Url)"
    }
}

if ($failures.Count -gt 0) {
    $failures | ForEach-Object { Write-Error $_ -ErrorAction Continue }
    throw "Corporate website verification failed with $($failures.Count) issue(s)."
}

Write-Host 'Corporate website verification passed: local-only guard, product content, placeholders, links and responsive treatments are present.'
if ($Live) { Write-Host 'Both local websites returned HTTP 200.' }
