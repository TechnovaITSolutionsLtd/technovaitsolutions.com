[CmdletBinding()]
param(
    [string]$SitePath = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path,
    [switch]$Live,
    [string]$CorporateBaseUrl = 'http://127.0.0.1:8766'
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

foreach ($required in @(
    'index.html',
    'portfolio.css',
    'favicon.ico',
    'img/mind-the-cards-icon.png',
    'img/ultimate-code-breaker-icon.png',
    'img/narrow-the-number-icon.png',
    'img/download-on-app-store.svg',
    'img/get-it-on-google-play.png',
    'scripts/local-preview-server.py'
)) {
    Assert-SiteCondition (Test-Path (Join-Path $siteRoot $required) -PathType Leaf) "Missing required file: $required"
}

$homePageHtml = Get-Content (Join-Path $siteRoot 'index.html') -Raw
$styles = Get-Content (Join-Path $siteRoot 'portfolio.css') -Raw

Assert-SiteCondition ($homePageHtml -match '(?i)<!doctype html>') 'index.html: missing HTML5 doctype'
Assert-SiteCondition ($homePageHtml -match '<html lang="en-GB">') 'index.html: missing en-GB language'
Assert-SiteCondition ($homePageHtml -match 'name="viewport"') 'index.html: missing viewport metadata'
Assert-SiteCondition ($homePageHtml -notmatch '(?i)noindex|nofollow') 'index.html: production homepage must be indexable'
Assert-SiteCondition ($homePageHtml -match 'class="skip-link"') 'index.html: keyboard skip link is missing'
Assert-SiteCondition ($homePageHtml -match 'id="main-content"') 'index.html: skip-link target is missing'
Assert-SiteCondition ($homePageHtml -match '<h1>Small software\.<br>Properly finished\.</h1>') 'index.html: corporate proposition is missing'

$products = @(
    @{ Name = 'Mind the Cards'; Site = 'https://mindthecards\.technovaitsolutions\.com/'; Apple = 'id6746877412'; Google = 'mindthecards\.technovaitsolutions\.com/google-play' },
    @{ Name = 'Ultimate Code Breaker'; Site = 'https://codebreaker\.technovaitsolutions\.com/'; Apple = 'id6798009711'; Google = 'com\.technovaitsolutions\.cathy' },
    @{ Name = 'Narrow the Number'; Site = 'https://narrow\.technovaitsolutions\.com/'; Apple = 'id6807072615'; Google = 'com\.technovaitsolutions\.linsey' }
)

foreach ($product in $products) {
    Assert-SiteCondition ($homePageHtml -match [regex]::Escape($product.Name)) "index.html: $($product.Name) is missing"
    Assert-SiteCondition ($homePageHtml -match $product.Site) "index.html: $($product.Name) product-site link is missing"
    Assert-SiteCondition ($homePageHtml -match $product.Apple) "index.html: $($product.Name) App Store link is missing"
    Assert-SiteCondition ($homePageHtml -match $product.Google) "index.html: $($product.Name) Google Play link is missing"
}

Assert-SiteCondition ($homePageHtml -match 'apps\.microsoft\.com/detail/9NQX3VX4WKCS') 'index.html: Mind the Cards Microsoft Store link is missing'
Assert-SiteCondition ($homePageHtml -match 'get\.microsoft\.com/images/en-us%20dark\.svg') 'index.html: official Microsoft Store badge is missing'
Assert-SiteCondition ($homePageHtml -match 'iPhone · iPad · Android · Windows') 'index.html: Mind the Cards Windows availability is missing'

Assert-SiteCondition (([regex]::Matches($homePageHtml, '>Web application<')).Count -eq 2) 'index.html: two generic web-application placeholders are required'
Assert-SiteCondition ($homePageHtml -match '<!--email_off-->.*?mailto:support@technovaitsolutions\.com.*?<!--/email_off-->') 'index.html: protected public support email is missing'
Assert-SiteCondition ($homePageHtml -notmatch '(?i)Coming soon|Recall Fun|Pro Designer|In store review|In review') 'index.html: retired or pre-launch wording remains'

foreach ($match in [regex]::Matches($homePageHtml, '(?i)(?:href|src)="([^"]+)"')) {
    $reference = $match.Groups[1].Value
    if ($reference -match '^(?:https?:|mailto:|tel:|data:|#)') { continue }
    $localTarget = Get-LocalTarget -SourceFile (Join-Path $siteRoot 'index.html') -Reference $reference
    Assert-SiteCondition (Test-Path $localTarget -PathType Leaf) "index.html: broken local reference '$reference'"
}

Assert-SiteCondition ($styles -match ':focus-visible') 'portfolio.css: visible keyboard focus treatment is missing'
Assert-SiteCondition ($styles -match '@media\s*\(max-width:\s*760px\)') 'portfolio.css: phone layout is missing'
Assert-SiteCondition ($styles -match '@media\s*\(prefers-reduced-motion:\s*reduce\)') 'portfolio.css: reduced-motion treatment is missing'

if ($Live) {
    $response = Invoke-WebRequest -Uri "$($CorporateBaseUrl.TrimEnd('/'))/" -MaximumRedirection 3
    Assert-SiteCondition ($response.StatusCode -eq 200) "Corporate homepage returned $($response.StatusCode): $CorporateBaseUrl"
}

if ($failures.Count -gt 0) {
    $failures | ForEach-Object { Write-Error $_ -ErrorAction Continue }
    throw "Corporate website verification failed with $($failures.Count) issue(s)."
}

Write-Host 'Corporate website verification passed: all three apps, store links, software placeholders and responsive treatments are present.'
if ($Live) { Write-Host 'The corporate preview returned HTTP 200.' }
