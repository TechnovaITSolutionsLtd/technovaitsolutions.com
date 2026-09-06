[CmdletBinding()]
param(
    [int]$CorporatePort = 8766,
    [int]$ProductPort = 8765,
    [int]$LinseyPort = 8767,
    [int]$CathyPort = 8768,
    [string]$ProductSitePath = (Join-Path $PSScriptRoot '../../hodgepodge/projects/minka/web'),
    [string]$LinseySitePath = (Join-Path $PSScriptRoot '../../hodgepodge/projects/linsey/web'),
    [string]$CathySitePath = (Join-Path $PSScriptRoot '../../hodgepodge/projects/cathy/web')
)

$ErrorActionPreference = 'Stop'
$corporateRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$productRoot = (Resolve-Path $ProductSitePath).Path
$linseyRoot = (Resolve-Path $LinseySitePath).Path
$cathyRoot = (Resolve-Path $CathySitePath).Path
$previewServer = (Resolve-Path (Join-Path $PSScriptRoot 'local-preview-server.py')).Path

$corporateProcess = Start-Process python3 -ArgumentList @($previewServer, '--port', $CorporatePort, '--directory', $corporateRoot) -PassThru
$productProcess = Start-Process python3 -ArgumentList @($previewServer, '--port', $ProductPort, '--directory', $productRoot) -PassThru
$linseyProcess = Start-Process python3 -ArgumentList @($previewServer, '--port', $LinseyPort, '--directory', $linseyRoot) -PassThru
$cathyProcess = Start-Process python3 -ArgumentList @($previewServer, '--port', $CathyPort, '--directory', $cathyRoot) -PassThru

Write-Host "Corporate preview:     http://127.0.0.1:$CorporatePort/"
Write-Host "Mind the Cards preview: http://127.0.0.1:$ProductPort/"
Write-Host "Narrow the Number:      http://127.0.0.1:$LinseyPort/"
Write-Host "Ultimate Code Breaker:  http://127.0.0.1:$CathyPort/"
Write-Host "Stop all previews:      Stop-Process -Id $($corporateProcess.Id),$($productProcess.Id),$($linseyProcess.Id),$($cathyProcess.Id)"
