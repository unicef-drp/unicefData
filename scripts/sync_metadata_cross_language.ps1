# Cross-Language Metadata Sync Script
# Purpose: Copy metadata files from Stata (canonical) to Python and R implementations
# Author: João Pedro Azevedo
# Date: January 18, 2026
# Part of: Phase 7.2 - Metadata Drift Prevention

<#
.SYNOPSIS
    Synchronizes metadata files across Stata, Python, and R directories

.DESCRIPTION
    Copies YAML metadata files from the canonical Stata location to Python and R
    metadata directories, ensuring all three language implementations use identical
    metadata. Validates checksums to detect manual edits.

.PARAMETER SourceDir
    Source directory containing canonical metadata (default: stata/src/_)

.PARAMETER DryRun
    If specified, shows what would be copied without making changes

.EXAMPLE
    .\sync_metadata_cross_language.ps1

.EXAMPLE
    .\sync_metadata_cross_language.ps1 -DryRun
#>

param(
    [string]$SourceDir = "C:\GitHub\myados\unicefData-dev\stata\src\_",
    [switch]$DryRun
)

# Target directories
$pythonMetadata = "C:\GitHub\myados\unicefData-dev\python\metadata\current"
$rMetadata = "C:\GitHub\myados\unicefData-dev\R\metadata\current"

# Files to sync
$metadataFiles = @(
    "_unicefdata_dataflow_metadata.yaml",
    "_unicefdata_indicators_metadata.yaml",
    "_unicefdata_dataflows.yaml",
    "_unicefdata_countries.yaml",
    "_unicefdata_regions.yaml",
    "_unicefdata_codelists.yaml",
    "_unicefdata_indicators.yaml",
    "_unicefdata_sync_history.yaml"
)

Write-Host ""
Write-Host "=" * 80 -ForegroundColor Cyan
Write-Host "  Cross-Language Metadata Sync" -ForegroundColor Cyan
Write-Host "=" * 80 -ForegroundColor Cyan
Write-Host "  Source:  $SourceDir" -ForegroundColor White
Write-Host "  Targets: Python, R metadata directories" -ForegroundColor White
if ($DryRun) {
    Write-Host "  Mode:    DRY RUN (no changes will be made)" -ForegroundColor Yellow
}
Write-Host "=" * 80 -ForegroundColor Cyan
Write-Host ""

# Verify source directory exists
if (-not (Test-Path $SourceDir)) {
    Write-Host "❌ ERROR: Source directory not found: $SourceDir" -ForegroundColor Red
    exit 1
}

# Create target directories if they don't exist
foreach ($targetDir in @($pythonMetadata, $rMetadata)) {
    if (-not (Test-Path $targetDir)) {
        if ($DryRun) {
            Write-Host "  WOULD CREATE: $targetDir" -ForegroundColor Yellow
        } else {
            New-Item -ItemType Directory -Path $targetDir -Force | Out-Null
            Write-Host "  ✓ Created: $targetDir" -ForegroundColor Green
        }
    }
}

Write-Host ""

# Track sync results
$synced = 0
$skipped = 0
$errors = 0

foreach ($file in $metadataFiles) {
    $sourcePath = Join-Path $SourceDir $file
    
    # Check if source file exists
    if (-not (Test-Path $sourcePath)) {
        Write-Host "  ⚠ SKIP: $file (not found in source)" -ForegroundColor Yellow
        $skipped++
        continue
    }
    
    # Get source file hash
    $sourceHash = (Get-FileHash -Path $sourcePath -Algorithm SHA256).Hash.Substring(0, 16)
    
    foreach ($targetDir in @($pythonMetadata, $rMetadata)) {
        $targetPath = Join-Path $targetDir $file
        $targetName = if ($targetDir -eq $pythonMetadata) { "Python" } else { "R" }
        
        try {
            # Check if target exists and compare hashes
            if (Test-Path $targetPath) {
                $targetHash = (Get-FileHash -Path $targetPath -Algorithm SHA256).Hash.Substring(0, 16)
                
                if ($sourceHash -eq $targetHash) {
                    Write-Host "  ≡ SAME: $file → $targetName (hash: $sourceHash)" -ForegroundColor Gray
                    continue
                } else {
                    Write-Host "  ↻ UPDATE: $file → $targetName" -ForegroundColor Cyan
                    Write-Host "    Source: $sourceHash" -ForegroundColor DarkGray
                    Write-Host "    Target: $targetHash" -ForegroundColor DarkGray
                }
            } else {
                Write-Host "  + NEW: $file → $targetName" -ForegroundColor Green
            }
            
            # Copy file
            if ($DryRun) {
                Write-Host "    WOULD COPY: $sourcePath → $targetPath" -ForegroundColor Yellow
            } else {
                Copy-Item -Path $sourcePath -Destination $targetPath -Force
                Write-Host "    ✓ Copied" -ForegroundColor Green
                $synced++
            }
        }
        catch {
            Write-Host "  ❌ ERROR: Failed to copy $file to $targetName" -ForegroundColor Red
            Write-Host "    $_" -ForegroundColor DarkRed
            $errors++
        }
    }
}

Write-Host ""
Write-Host "=" * 80 -ForegroundColor Cyan
Write-Host "  Summary" -ForegroundColor Cyan
Write-Host "=" * 80 -ForegroundColor Cyan
Write-Host "  Files synced:  $synced" -ForegroundColor Green
Write-Host "  Files skipped: $skipped" -ForegroundColor Yellow
Write-Host "  Errors:        $errors" -ForegroundColor $(if ($errors -gt 0) { "Red" } else { "Green" })
Write-Host "=" * 80 -ForegroundColor Cyan

if ($DryRun) {
    Write-Host ""
    Write-Host "This was a dry run. Run without -DryRun to apply changes." -ForegroundColor Yellow
}

if ($errors -gt 0) {
    Write-Host ""
    Write-Host "⚠ Some files failed to sync. Check errors above." -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "✓ Cross-language metadata sync complete" -ForegroundColor Green
Write-Host ""

exit 0
