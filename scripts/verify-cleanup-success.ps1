#!/usr/bin/env pwsh
# Verify cleanup was successful
# Usage: .\verify-cleanup-success.ps1

param(
    [switch]$SkipTests
)

$ErrorActionPreference = "Stop"

Write-Host "=== Post-Cleanup Verification ===" -ForegroundColor Cyan

$pubRoot = "C:\GitHub\myados\unicefData"
$issues = @()
$warnings = @()

# 1. Check repo size
Write-Host "`n[1/6] Checking repository size..." -ForegroundColor Yellow
$size = (Get-ChildItem $pubRoot -Recurse -File -ErrorAction SilentlyContinue | 
         Where-Object { $_.FullName -notlike "*\.git\*" } | 
         Measure-Object -Property Length -Sum).Sum / 1MB

Write-Host "  Current size: $([math]::Round($size, 2)) MB"

if ($size -gt 1000) {
    $warnings += "Repository still > 1GB ($([math]::Round($size, 2)) MB)"
    Write-Host "  ⚠️  Still above 1GB target" -ForegroundColor Yellow
} else {
    Write-Host "  ✅ Size within target" -ForegroundColor Green
}

# 2. Check for bloat artifacts
Write-Host "`n[2/6] Checking for bloat artifacts..." -ForegroundColor Yellow
$bloatPatterns = @(
    "validation/results/*.json",
    "validation/results/*.csv",
    "validation/cache/*.json",
    "*.log",
    "test_*.log"
)

$foundBloat = $false
foreach ($pattern in $bloatPatterns) {
    $files = Get-ChildItem -Path (Join-Path $pubRoot $pattern) -File -ErrorAction SilentlyContinue
    if ($files.Count -gt 0) {
        $warnings += "Found $($files.Count) files matching $pattern"
        $foundBloat = $true
    }
}

if (-not $foundBloat) {
    Write-Host "  ✅ No bloat artifacts found" -ForegroundColor Green
} else {
    Write-Host "  ⚠️  Bloat artifacts detected" -ForegroundColor Yellow
}

# 3. Verify source files intact
Write-Host "`n[3/6] Verifying source files..." -ForegroundColor Yellow
$criticalFiles = @(
    "R/unicef_core.R",
    "python/unicef_api/core.py",
    "stata/src/_/_unicef_fetch_with_fallback.ado",
    "README.md",
    "LICENSE"
)

foreach ($file in $criticalFiles) {
    if (-not (Test-Path (Join-Path $pubRoot $file))) {
        $issues += "Critical file missing: $file"
        Write-Host "  ❌ Missing: $file" -ForegroundColor Red
    }
}

if ($issues.Count -eq 0) {
    Write-Host "  ✅ All critical files present" -ForegroundColor Green
}

# 4. Check .gitignore
Write-Host "`n[4/6] Checking .gitignore..." -ForegroundColor Yellow
$gitignore = Get-Content (Join-Path $pubRoot ".gitignore") -Raw -ErrorAction SilentlyContinue

$requiredPatterns = @("validation/results/", "validation/cache/", "*.log")
$missingPatterns = @()

foreach ($pattern in $requiredPatterns) {
    if ($gitignore -notmatch [regex]::Escape($pattern)) {
        $missingPatterns += $pattern
    }
}

if ($missingPatterns.Count -gt 0) {
    $warnings += ".gitignore missing patterns: $($missingPatterns -join ', ')"
    Write-Host "  ⚠️  Missing patterns in .gitignore" -ForegroundColor Yellow
} else {
    Write-Host "  ✅ .gitignore properly configured" -ForegroundColor Green
}

# 5. Check for private content
Write-Host "`n[5/6] Scanning for private content..." -ForegroundColor Yellow
$privatePatterns = @(
    "internal/",
    "paper/",
    "drafts/",
    "eb1a/",
    "*PRIVATE*",
    "*SECRET*"
)

$foundPrivate = $false
foreach ($pattern in $privatePatterns) {
    $files = Get-ChildItem -Path $pubRoot -Recurse -Filter $pattern -ErrorAction SilentlyContinue
    if ($files.Count -gt 0) {
        $issues += "Private content found: $pattern ($($files.Count) matches)"
        $foundPrivate = $true
    }
}

if (-not $foundPrivate) {
    Write-Host "  ✅ No private content detected" -ForegroundColor Green
} else {
    Write-Host "  ❌ Private content found" -ForegroundColor Red
}

# 6. Run functional tests (optional)
if (-not $SkipTests) {
    Write-Host "`n[6/6] Running functional tests..." -ForegroundColor Yellow
    
    # R package test
    Push-Location (Join-Path $pubRoot "R")
    try {
        $rTest = Rscript -e "devtools::load_all(); print('R package loads successfully')" 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Host "  ✅ R package loads" -ForegroundColor Green
        } else {
            $warnings += "R package load failed"
            Write-Host "  ⚠️  R package load failed" -ForegroundColor Yellow
        }
    } catch {
        $warnings += "R test error: $_"
    }
    Pop-Location
    
    # Python package test
    Push-Location (Join-Path $pubRoot "python")
    try {
        python -c "import unicef_api; print('Python package imports successfully')"
        if ($LASTEXITCODE -eq 0) {
            Write-Host "  ✅ Python package imports" -ForegroundColor Green
        } else {
            $warnings += "Python package import failed"
            Write-Host "  ⚠️  Python package import failed" -ForegroundColor Yellow
        }
    } catch {
        $warnings += "Python test error: $_"
    }
    Pop-Location
} else {
    Write-Host "`n[6/6] Skipping functional tests (use -SkipTests:$false to enable)" -ForegroundColor Gray
}

# Summary
Write-Host "`n=== Verification Summary ===" -ForegroundColor Cyan
Write-Host "Issues:   $($issues.Count)" -ForegroundColor $(if ($issues.Count -eq 0) { "Green" } else { "Red" })
Write-Host "Warnings: $($warnings.Count)" -ForegroundColor $(if ($warnings.Count -eq 0) { "Green" } else { "Yellow" })

if ($issues.Count -gt 0) {
    Write-Host "`n❌ CRITICAL ISSUES FOUND:" -ForegroundColor Red
    $issues | ForEach-Object { Write-Host "  - $_" -ForegroundColor Red }
    Write-Host "`nDO NOT push to remote. Rollback required.`n" -ForegroundColor Red
    exit 1
}

if ($warnings.Count -gt 0) {
    Write-Host "`n⚠️  WARNINGS:" -ForegroundColor Yellow
    $warnings | ForEach-Object { Write-Host "  - $_" -ForegroundColor Yellow }
    Write-Host "`nReview warnings before pushing to remote.`n" -ForegroundColor Yellow
}

if ($issues.Count -eq 0 -and $warnings.Count -eq 0) {
    Write-Host "`n✅ Cleanup verification passed. Safe to push to remote.`n" -ForegroundColor Green
}

exit 0
