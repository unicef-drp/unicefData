#!/usr/bin/env pwsh
# Verify unicefData-dev contains all content from unicefData public repo
# Usage: .\verify-content-sync.ps1

param(
    [switch]$Detailed
)

$ErrorActionPreference = "Stop"

Write-Host "=== Content Sync Verification ===" -ForegroundColor Cyan
Write-Host "Comparing unicefData-dev (private) vs unicefData (public)" -ForegroundColor Yellow
Write-Host ""

$devRoot = "C:\GitHub\myados\unicefData-dev"
$pubRoot = "C:\GitHub\myados\unicefData"

# Critical paths to verify
$criticalPaths = @(
    "R/*.R",
    "R/DESCRIPTION",
    "R/NAMESPACE",
    "python/unicef_api/*.py",
    "python/setup.py",
    "stata/src/**/*.ado",
    "stata/src/**/*.sthlp",
    "stata/stata.toc",
    "README.md",
    "LICENSE",
    "CITATION.cff"
)

$missingFiles = @()
$extraFiles = @()
$verified = 0

Write-Host "Checking critical files..." -ForegroundColor Cyan

foreach ($pattern in $criticalPaths) {
    $pubFiles = Get-ChildItem -Path (Join-Path $pubRoot $pattern) -File -ErrorAction SilentlyContinue
    
    foreach ($pubFile in $pubFiles) {
        $relativePath = $pubFile.FullName.Replace($pubRoot, "").TrimStart('\')
        $devFile = Join-Path $devRoot $relativePath
        
        if (-not (Test-Path $devFile)) {
            $missingFiles += $relativePath
            Write-Host "  X MISSING: $relativePath" -ForegroundColor Red
        } else {
            $verified++
            if ($Detailed) {
                Write-Host "  OK $relativePath" -ForegroundColor Green
            }
        }
    }
}

Write-Host ""
Write-Host "=== Summary ===" -ForegroundColor Cyan
Write-Host "Verified files:  $verified" -ForegroundColor Green
Write-Host "Missing files:   $($missingFiles.Count)" -ForegroundColor $(if ($missingFiles.Count -eq 0) { "Green" } else { "Red" })

if ($missingFiles.Count -gt 0) {
    Write-Host ""
    Write-Host "WARNING: Missing files detected in private repo!" -ForegroundColor Yellow
    Write-Host "DO NOT proceed with public repo cleanup until these are resolved." -ForegroundColor Red
    Write-Host ""
    
    Write-Host "Missing files:" -ForegroundColor Yellow
    $missingFiles | ForEach-Object { Write-Host "  - $_" }
    
    exit 1
} else {
    Write-Host ""
    Write-Host "All critical files verified in private repo." -ForegroundColor Green
    Write-Host "Safe to proceed with public repo cleanup." -ForegroundColor Green
    exit 0
}
