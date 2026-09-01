[CmdletBinding()]
param(
    [int]$CorporatePort = 8766,
    [int]$ProductPort = 8765,
    [string]$ProductSitePath = (Join-Path $PSScriptRoot '../../hodgepodge/projects/minka/web')
)

$ErrorActionPreference = 'Stop'
$corporateRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$productRoot = (Resolve-Path $ProductSitePath).Path

$corporateProcess = Start-Process python3 -ArgumentList @('-m', 'http.server', $CorporatePort, '--bind', '127.0.0.1', '--directory', $corporateRoot) -PassThru
$productProcess = Start-Process python3 -ArgumentList @('-m', 'http.server', $ProductPort, '--bind', '127.0.0.1', '--directory', $productRoot) -PassThru

Write-Host "Corporate preview:     http://127.0.0.1:$CorporatePort/"
Write-Host "Mind the Cards preview: http://127.0.0.1:$ProductPort/"
Write-Host "Stop both previews:     Stop-Process -Id $($corporateProcess.Id),$($productProcess.Id)"
