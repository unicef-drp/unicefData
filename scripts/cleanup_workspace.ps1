<#
.SYNOPSIS
    Workspace cleanup script for unicefData-dev
    
.DESCRIPTION
    This script cleans up temporary files, empty folders, and consolidates
    scattered archive content. Run with -WhatIf first to preview changes.
    
.EXAMPLE
    .\cleanup_workspace.ps1 -WhatIf    # Preview only
    .\cleanup_workspace.ps1            # Execute cleanup
    
.NOTES
    Created: 2026-01-31
    Author: Copilot cleanup review
#>

param(
    [switch]$WhatIf,
    [switch]$SkipArchiveConsolidation,
    [switch]$Verbose
)

$ErrorActionPreference = "Stop"
$root = Split-Path $PSScriptRoot -Parent

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "unicefData-dev Workspace Cleanup" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Root: $root"
if ($WhatIf) {
    Write-Host "[PREVIEW MODE - No changes will be made]" -ForegroundColor Yellow
}
Write-Host ""

# ============================================================================
# PHASE 1: Delete empty folders and temp files
# ============================================================================
Write-Host "PHASE 1: Remove empty folders and temp files" -ForegroundColor Green

$emptyFolders = @(
    "python\archive",
    "stata\ssc",
    "validation\docs_archive"
)

foreach ($folder in $emptyFolders) {
    $path = Join-Path $root $folder
    if (Test-Path $path) {
        $items = Get-ChildItem $path -Force
        if ($items.Count -eq 0) {
            Write-Host "  DELETE empty folder: $folder" -ForegroundColor Red
            if (-not $WhatIf) {
                Remove-Item $path -Force
            }
        } else {
            Write-Host "  SKIP (not empty): $folder" -ForegroundColor Yellow
        }
    }
}

# Temp log files at root
$tempFiles = @(
    "validation_output.log",
    "validation_stderr.log",
    "validation_stdout.log"
)

foreach ($file in $tempFiles) {
    $path = Join-Path $root $file
    if (Test-Path $path) {
        Write-Host "  DELETE temp file: $file" -ForegroundColor Red
        if (-not $WhatIf) {
            Remove-Item $path -Force
        }
    }
}

# Build artifacts (should be gitignored)
$buildArtifacts = @(
    "python\unicef_api.egg-info"
)

foreach ($folder in $buildArtifacts) {
    $path = Join-Path $root $folder
    if (Test-Path $path) {
        Write-Host "  DELETE build artifact: $folder" -ForegroundColor Red
        if (-not $WhatIf) {
            Remove-Item $path -Recurse -Force
        }
    }
}

Write-Host ""

# ============================================================================
# PHASE 2: Consolidate archives to internal/_archive/
# ============================================================================
if (-not $SkipArchiveConsolidation) {
    Write-Host "PHASE 2: Consolidate scattered archives" -ForegroundColor Green
    
    $centralArchive = Join-Path $root "internal\_archive"
    if (-not (Test-Path $centralArchive) -and -not $WhatIf) {
        New-Item -ItemType Directory -Path $centralArchive -Force | Out-Null
    }
    
    $archiveSources = @(
        @{ Source = "archive"; Dest = "root" },
        @{ Source = "validation\_archive"; Dest = "validation" },
        @{ Source = "validation\legacy"; Dest = "validation-legacy" },
        @{ Source = "stata\qa\archive"; Dest = "stata-qa" },
        @{ Source = "doc\_archive"; Dest = "doc" }
    )
    
    foreach ($item in $archiveSources) {
        $srcPath = Join-Path $root $item.Source
        $destPath = Join-Path $centralArchive $item.Dest
        
        if (Test-Path $srcPath) {
            $files = Get-ChildItem $srcPath -Force
            if ($files.Count -gt 0) {
                Write-Host "  MOVE $($item.Source) -> internal\_archive\$($item.Dest)" -ForegroundColor Yellow
                if (-not $WhatIf) {
                    if (-not (Test-Path $destPath)) {
                        New-Item -ItemType Directory -Path $destPath -Force | Out-Null
                    }
                    Move-Item "$srcPath\*" $destPath -Force
                    Remove-Item $srcPath -Force
                }
            }
        }
    }
}

Write-Host ""

# ============================================================================
# PHASE 3: Fix file locations
# ============================================================================
Write-Host "PHASE 3: Fix misplaced files" -ForegroundColor Green

# Python test files in wrong location
$pythonTestFiles = @(
    "test_download.py",
    "test_fallback_fix.py"
)

foreach ($file in $pythonTestFiles) {
    $src = Join-Path $root "python\$file"
    $dest = Join-Path $root "python\tests\$file"
    if (Test-Path $src) {
        Write-Host "  MOVE python\$file -> python\tests\$file" -ForegroundColor Yellow
        if (-not $WhatIf) {
            Move-Item $src $dest -Force
        }
    }
}

# Stata validation files -> tests
$stataValidationFiles = Get-ChildItem (Join-Path $root "stata\validation") -Filter "*.do" -ErrorAction SilentlyContinue
foreach ($file in $stataValidationFiles) {
    $dest = Join-Path $root "stata\tests\$($file.Name)"
    Write-Host "  MOVE stata\validation\$($file.Name) -> stata\tests\" -ForegroundColor Yellow
    if (-not $WhatIf) {
        Move-Item $file.FullName $dest -Force
    }
}

# Move run_validation.bat to scripts
$batFile = Join-Path $root "run_validation.bat"
if (Test-Path $batFile) {
    Write-Host "  MOVE run_validation.bat -> scripts\" -ForegroundColor Yellow
    if (-not $WhatIf) {
        Move-Item $batFile (Join-Path $root "scripts\run_validation.bat") -Force
    }
}

Write-Host ""

# ============================================================================
# PHASE 4: Prune old dated logs (keep last 3)
# ============================================================================
Write-Host "PHASE 4: Prune old dated log folders" -ForegroundColor Green

$logsDir = Join-Path $root "logs"
$datedFolders = Get-ChildItem $logsDir -Directory | 
    Where-Object { $_.Name -match '^\d{8}$' } | 
    Sort-Object Name -Descending

$keepCount = 3
$toDelete = $datedFolders | Select-Object -Skip $keepCount

foreach ($folder in $toDelete) {
    Write-Host "  DELETE old logs: logs\$($folder.Name)" -ForegroundColor Red
    if (-not $WhatIf) {
        Remove-Item $folder.FullName -Recurse -Force
    }
}

if ($toDelete.Count -eq 0) {
    Write-Host "  No old log folders to prune (keeping last $keepCount)" -ForegroundColor Gray
}

Write-Host ""

# ============================================================================
# PHASE 5: Remove misc temp files from logs/
# ============================================================================
Write-Host "PHASE 5: Clean misc files from logs/" -ForegroundColor Green

$logsCleanup = @(
    "logs\show_commented.py",
    "logs\stata_deps.dot",
    "logs\stata_deps.json",
    "logs\stata_deps.png",
    "logs\stata_deps_all.json",
    "logs\stata_deps_filtered.dot",
    "logs\stata_deps_filtered.json",
    "logs\stata_deps_filtered.png"
)

foreach ($file in $logsCleanup) {
    $path = Join-Path $root $file
    if (Test-Path $path) {
        Write-Host "  DELETE misc file: $file" -ForegroundColor Red
        if (-not $WhatIf) {
            Remove-Item $path -Force
        }
    }
}

Write-Host ""

# ============================================================================
# Summary
# ============================================================================
Write-Host "========================================" -ForegroundColor Cyan
if ($WhatIf) {
    Write-Host "PREVIEW COMPLETE - Run without -WhatIf to execute" -ForegroundColor Yellow
} else {
    Write-Host "CLEANUP COMPLETE" -ForegroundColor Green
    Write-Host "Run 'git status' to review changes before committing" -ForegroundColor Cyan
}
Write-Host "========================================" -ForegroundColor Cyan
