# ============================================================================
# orchestrator_metadata.ps1 - Orchestrate metadata sync for all languages
# ============================================================================
#
# This script orchestrates metadata sync for all three languages by calling:
# - sync_metadata_python.py (Python metadata)
# - sync_metadata_r.R (R metadata)
# - sync_metadata_stata.do (Stata metadata)
#
# Usage:
#   .\tests\orchestrator_metadata.ps1 [-Python] [-R] [-Stata] [-All] [-Verbose] [-Force]
#
# Examples:
#   .\tests\orchestrator_metadata.ps1 -All          # Sync all (prompts if files exist)
#   .\tests\orchestrator_metadata.ps1 -Python       # Python only
#   .\tests\orchestrator_metadata.ps1 -Stata        # Stata only
#   .\tests\orchestrator_metadata.ps1 -All -Force   # Overwrite without prompting
#
# Log output: tests/logs/orchestrator_metadata.log
# ============================================================================

param(
    [switch]$Python,
    [switch]$R,
    [switch]$Stata,
    [switch]$All,
    [switch]$Verbose,
    [switch]$Force
)

# Default to All if no specific language selected
if (-not $Python -and -not $R -and -not $Stata) {
    $All = $true
}

$ErrorActionPreference = "Stop"

# Dynamically locate the repository root by finding the .git folder
function Get-RepoRoot {
    $currentDir = Get-Location
    while (-Not (Test-Path "$currentDir\.git")) {
        $parentDir = $currentDir.Parent
        if (-Not $parentDir) {
            throw "Unable to locate repository root. Ensure the script is run within a Git repository."
        }
        $currentDir = $parentDir
    }
    return $currentDir
}

# Check if metadata files exist and prompt for confirmation
function Check-ExistingFiles {
    param(
        [string]$Platform,
        [string]$MetadataDir
    )
    
    if (-Not (Test-Path $MetadataDir)) {
        return $true  # Directory doesn't exist, proceed
    }
    
    $existingFiles = Get-ChildItem -Path $MetadataDir -Filter "*.yaml" -ErrorAction SilentlyContinue
    
    if ($existingFiles.Count -eq 0) {
        return $true  # No existing files, proceed
    }
    
    if ($Force) {
        Write-Host "[$Platform] Found $($existingFiles.Count) existing file(s). Overwriting (--Force specified)." -ForegroundColor Yellow
        return $true
    }
    
    Write-Host ""
    Write-Host "[$Platform] Found $($existingFiles.Count) existing metadata file(s) in:" -ForegroundColor Yellow
    Write-Host "  $MetadataDir" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  Most recent files:" -ForegroundColor Gray
    $existingFiles | Sort-Object LastWriteTime -Descending | Select-Object -First 5 | ForEach-Object {
        Write-Host "    - $($_.Name) ($(Get-Date $_.LastWriteTime -Format 'yyyy-MM-dd HH:mm:ss'))" -ForegroundColor Gray
    }
    Write-Host ""
    
    $response = Read-Host "[$Platform] Do you want to overwrite existing files? (Y/N/S=Skip)"
    
    switch ($response.ToUpper()) {
        'Y' { 
            Write-Host "[$Platform] Overwriting existing files..." -ForegroundColor Yellow
            return $true 
        }
        'N' { 
            Write-Host "[$Platform] Aborting regeneration." -ForegroundColor Red
            return $false 
        }
        'S' { 
            Write-Host "[$Platform] Skipping this platform." -ForegroundColor Cyan
            return $null  # Special value to indicate skip
        }
        default { 
            Write-Host "[$Platform] Invalid response. Skipping." -ForegroundColor Red
            return $null 
        }
    }
}

$RepoRoot = Get-RepoRoot

# Setup logging
$LogDir = Join-Path $RepoRoot "tests\logs"
if (-Not (Test-Path $LogDir)) {
    New-Item -ItemType Directory -Path $LogDir -Force | Out-Null
}
$LogFile = Join-Path $LogDir "orchestrator_metadata.log"

# Start transcript for logging
Start-Transcript -Path $LogFile -Force | Out-Null

Write-Host "============================================" -ForegroundColor Cyan
Write-Host " unicefData Metadata Regeneration Script" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "Repository: $RepoRoot"
Write-Host "Log file:   $LogFile"
if ($Force) {
    Write-Host "Mode: Force overwrite (no prompts)" -ForegroundColor Yellow
}
Write-Host ""

# ----------------------------------------------------------------------------
# Python Metadata Regeneration
# ----------------------------------------------------------------------------
function Regenerate-PythonMetadata {
    Write-Host ""
    Write-Host "[Python] Regenerating metadata..." -ForegroundColor Yellow
    Write-Host "----------------------------------------"
    
    # Check for existing files
    $PythonMetadataDir = "$RepoRoot\python\metadata\current"
    $checkResult = Check-ExistingFiles -Platform "Python" -MetadataDir $PythonMetadataDir
    if ($checkResult -eq $null) {
        return $null  # Skip
    }
    if (-Not $checkResult) {
        return $false  # Abort
    }
    
    $PythonSyncScript = "$RepoRoot\python\unicef_api\run_sync.py"
    if (-Not (Test-Path $PythonSyncScript)) {
        Write-Host "[Python] ERROR: sync script not found at $PythonSyncScript" -ForegroundColor Red
        return $false
    }
    
    try {
        # Check for virtual environment in repo or parent GitHub folder
        $VenvPython = $null
        $VenvPip = $null
        $VenvPaths = @(
            "$RepoRoot\.venv\Scripts",
            "$RepoRoot\venv\Scripts",
            "C:\GitHub\.venv\Scripts"
        )
        foreach ($venvDir in $VenvPaths) {
            $pythonPath = "$venvDir\python.exe"
            $pipPath = "$venvDir\pip.exe"
            if (Test-Path $pythonPath) {
                $VenvPython = $pythonPath
                $VenvPip = $pipPath
                Write-Host "[Python] Using virtual environment: $venvDir" -ForegroundColor Cyan
                break
            }
        }
        
        if (-Not $VenvPython) {
            $VenvPython = "python"
            $VenvPip = "pip"
            Write-Host "[Python] Using system Python" -ForegroundColor Cyan
        }
        
        # Check Python version
        Write-Host "[Python] Checking Python version..."
        & $VenvPython --version
        
        # Check and install requirements if requirements.txt exists
        $RequirementsFile = "$RepoRoot\python\requirements.txt"
        if (Test-Path $RequirementsFile) {
            Write-Host "[Python] Found requirements.txt, checking dependencies..." -ForegroundColor Cyan
            if ($Verbose) {
                Write-Host "[Python] Installing requirements from: $RequirementsFile"
                & $VenvPip install -r $RequirementsFile
            } else {
                & $VenvPip install -q -r $RequirementsFile 2>$null
            }
            if ($LASTEXITCODE -ne 0) {
                Write-Host "[Python] WARNING: Some requirements may have failed to install" -ForegroundColor Yellow
            } else {
                Write-Host "[Python] Dependencies verified" -ForegroundColor Green
            }
        } else {
            Write-Host "[Python] No requirements.txt found at $RequirementsFile" -ForegroundColor Yellow
        }
        
        # Set up environment and run sync
        Write-Host "[Python] Running schema_sync..." -ForegroundColor Cyan
        $env:PYTHONPATH = "$RepoRoot\python;$env:PYTHONPATH"
        if ($Verbose) {
            Write-Host "[Python] PYTHONPATH: $env:PYTHONPATH"
            Write-Host "[Python] Working directory: $RepoRoot\python"
        }
        
        Push-Location "$RepoRoot\python"
        if ($Verbose) {
            Write-Host "[Python] Command: $VenvPython -m unicef_api.run_sync"
        }
        
        # Track progress for visual feedback
        $startTime = Get-Date
        
        # Run with output streaming for progress visibility
        & $VenvPython -m unicef_api.run_sync 2>&1 | ForEach-Object { 
            $line = $_
            if ([string]::IsNullOrWhiteSpace($line)) {
                # Skip empty lines
            } elseif ($line -match '^\s*\[(\d+)/(\d+)\](.*)') {
                # Progress line like [1/69] Fetching...
                $current = [int]$Matches[1]
                $total = [int]$Matches[2]
                $details = $Matches[3].Trim()
                
                # Calculate progress
                $pct = [math]::Round(($current / $total) * 100)
                $elapsed = (Get-Date) - $startTime
                if ($current -gt 1) {
                    $avgTime = $elapsed.TotalSeconds / ($current - 1)
                    $remaining = [math]::Round($avgTime * ($total - $current))
                    $eta = "~$remaining`s remaining"
                } else {
                    $eta = "calculating..."
                }
                
                # Build progress bar
                $barWidth = 30
                $filled = [math]::Floor($barWidth * $current / $total)
                $empty = $barWidth - $filled
                $bar = "[" + ("=" * $filled) + (">" * [math]::Min(1, $empty)) + (" " * [math]::Max(0, $empty - 1)) + "]"
                
                Write-Host "`r  $bar $pct% ($current/$total) $eta" -ForegroundColor Cyan -NoNewline
                if ($line -match '(OK|Done|SUCCESS)') {
                    Write-Host ""
                }
            } elseif ($line -match '(Fetching|Syncing|Saved|Processing|Done|SUCCESS|OK|Found)') {
                Write-Host "  $line" -ForegroundColor Gray
            } elseif ($line -match '(ERROR|Error|error|FAILED)') {
                Write-Host ""  # Newline after progress
                Write-Host "  $line" -ForegroundColor Red
            } elseif ($line -match '(WARNING|Warning|SKIP)') {
                Write-Host "  $line" -ForegroundColor Yellow
            } else {
                Write-Host "  $line" -ForegroundColor DarkGray
            }
        }
        Write-Host ""  # Final newline
        $exitCode = $LASTEXITCODE
        Pop-Location
        
        if ($exitCode -eq 0) {
            $metadataDir = Join-Path $RepoRoot "python\metadata\current"
            $fileCount = (Get-ChildItem -Path $metadataDir -Filter "*.yaml" -ErrorAction SilentlyContinue).Count
            Write-Host "[Python] SUCCESS: Generated $fileCount metadata files" -ForegroundColor Green
            return $true
        } else {
            Write-Host "[Python] ERROR: sync failed with exit code $exitCode" -ForegroundColor Red
            return $false
        }
    }
    catch {
        Write-Host "[Python] ERROR: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

# ----------------------------------------------------------------------------
# R Metadata Regeneration
# ----------------------------------------------------------------------------
function Regenerate-RMetadata {
    Write-Host ""
    Write-Host "[R] Regenerating metadata..." -ForegroundColor Yellow
    Write-Host "----------------------------------------"
    
    # Check for existing files
    $RMetadataDir = "$RepoRoot\R\metadata\current"
    $checkResult = Check-ExistingFiles -Platform "R" -MetadataDir $RMetadataDir
    if ($checkResult -eq $null) {
        return $null  # Skip
    }
    if (-Not $checkResult) {
        return $false  # Abort
    }
    
    $RSyncScript = "$RepoRoot\R\schema_sync.R"
    if (-Not (Test-Path $RSyncScript)) {
        Write-Host "[R] ERROR: sync script not found at $RSyncScript" -ForegroundColor Red
        return $false
    }
    
    # Find Rscript executable
    $RscriptExe = $null
    
    # First check if Rscript is in PATH
    try {
        $rscriptInPath = Get-Command Rscript -ErrorAction SilentlyContinue
        if ($rscriptInPath) {
            $RscriptExe = $rscriptInPath.Source
        }
    } catch { }
    
    # If not in PATH, search common installation directories
    if (-Not $RscriptExe) {
        $RscriptPaths = @(
            "C:\Program Files\R\R-4.5.1\bin\Rscript.exe",
            "C:\Program Files\R\R-4.4.1\bin\Rscript.exe",
            "C:\Program Files\R\R-4.3.3\bin\Rscript.exe",
            "C:\Program Files\R\R-4.2.3\bin\Rscript.exe"
        )
        foreach ($path in $RscriptPaths) {
            if (Test-Path $path) {
                $RscriptExe = $path
                break
            }
        }
        
        # Last resort: search recursively
        if (-Not $RscriptExe) {
            $found = Get-ChildItem "C:\Program Files\R" -Recurse -Filter "Rscript.exe" -ErrorAction SilentlyContinue | Select-Object -First 1
            if ($found) {
                $RscriptExe = $found.FullName
            }
        }
    }
    
    if (-Not $RscriptExe) {
        Write-Host "[R] ERROR: Rscript not found. Please install R from https://cran.r-project.org/" -ForegroundColor Red
        Write-Host "[R] Tip: Add R to your PATH or install R in 'C:\Program Files\R\'"
        return $false
    }
    
    Write-Host "[R] Using Rscript: $RscriptExe" -ForegroundColor Cyan
    
    try {
        # Create temporary R script files to ensure proper output streaming
        $tempDir = [System.IO.Path]::GetTempPath()
        
        # Step 1: Run metadata_sync.R for core _unicefdata_*.yaml files
        Write-Host "[R] Running metadata_sync.R (core files)..." -ForegroundColor Cyan
        $tempMetadataScript = Join-Path $tempDir "unicef_metadata_sync_$([guid]::NewGuid().ToString('N')).R"
        $RMetadataDir = "$($RepoRoot -replace '\\', '/')/R/metadata/current"
        $rCodeMetadata = @"
setwd('$($RepoRoot -replace '\\', '/')')
source('R/metadata_sync.R')
# Set include_schemas=FALSE since we run schema_sync.R separately
sync_all_metadata(verbose = TRUE, output_dir = '$RMetadataDir', include_schemas = FALSE)
"@
        # Use ASCII encoding to avoid BOM issues with R
        [System.IO.File]::WriteAllText($tempMetadataScript, $rCodeMetadata, [System.Text.Encoding]::ASCII)
        
        # Run with output streaming
        & $RscriptExe --vanilla $tempMetadataScript 2>&1 | ForEach-Object { 
            $line = $_
            if ([string]::IsNullOrWhiteSpace($line)) {
                # Skip empty lines
            } elseif ($line -match '^\s*\[[\d/]+\]') {
                Write-Host "  $line" -ForegroundColor Gray
            } elseif ($line -match '(Fetching|Syncing|Saved|Processing|Done|Found|Mapped|Complete)') {
                Write-Host "  $line" -ForegroundColor Gray
            } elseif ($line -match '^Error:' -or $line -match 'Error in ') {
                Write-Host "  $line" -ForegroundColor Red
            } elseif ($line -match '(WARNING|Warning:)') {
                Write-Host "  $line" -ForegroundColor Yellow
            } elseif ($line -match '(masked from|Attaching package)') {
                # R package loading messages - skip or dim
                if ($Verbose) { Write-Host "  $line" -ForegroundColor DarkGray }
            } else {
                Write-Host "  $line" -ForegroundColor DarkGray
            }
        }
        $exitCode1 = $LASTEXITCODE
        Remove-Item $tempMetadataScript -ErrorAction SilentlyContinue
        
        if ($exitCode1 -ne 0) {
            Write-Host "[R] WARNING: metadata_sync.R failed with exit code $exitCode1" -ForegroundColor Yellow
        }
        
        # Step 2: Run schema_sync.R for dataflow schemas
        Write-Host ""
        Write-Host "[R] Running schema_sync.R (dataflow schemas)..." -ForegroundColor Cyan
        Write-Host "[R] Note: Fetching 69 dataflows from SDMX API - may take 5-10 minutes" -ForegroundColor DarkGray
        $tempSchemaScript = Join-Path $tempDir "unicef_schema_sync_$([guid]::NewGuid().ToString('N')).R"
        $RMetadataDir = "$($RepoRoot -replace '\\', '/')/R/metadata/current"
        $rCodeSchema = @"
setwd('$($RepoRoot -replace '\\', '/')')
source('R/schema_sync.R')
sync_dataflow_schemas(verbose = TRUE, output_dir = '$RMetadataDir')
"@
        # Use ASCII encoding to avoid BOM issues with R
        [System.IO.File]::WriteAllText($tempSchemaScript, $rCodeSchema, [System.Text.Encoding]::ASCII)
        
        # Directory to monitor for progress
        $dataflowsDir = Join-Path $RepoRoot "R\metadata\current\dataflows"
        $totalSchemas = 69
        $startTime = Get-Date
        
        # Get initial file count
        $initialCount = 0
        if (Test-Path $dataflowsDir) {
            $initialCount = (Get-ChildItem -Path $dataflowsDir -Filter "*.yaml" -ErrorAction SilentlyContinue).Count
        }
        
        # Start R process in background
        $rProcess = Start-Process -FilePath $RscriptExe -ArgumentList "--vanilla", $tempSchemaScript -PassThru -NoNewWindow -RedirectStandardOutput "$tempDir\r_stdout.txt" -RedirectStandardError "$tempDir\r_stderr.txt"
        
        # Monitor progress by counting files in dataflows directory
        Write-Host "  Syncing dataflow schemas:" -ForegroundColor Gray
        $lastCount = $initialCount
        while (-not $rProcess.HasExited) {
            Start-Sleep -Milliseconds 500
            
            if (Test-Path $dataflowsDir) {
                $currentCount = (Get-ChildItem -Path $dataflowsDir -Filter "*.yaml" -ErrorAction SilentlyContinue).Count
                $newFiles = $currentCount - $initialCount
                
                if ($newFiles -ne $lastCount - $initialCount -and $newFiles -gt 0) {
                    # Calculate progress
                    $pct = [math]::Round(($newFiles / $totalSchemas) * 100)
                    $elapsed = (Get-Date) - $startTime
                    if ($newFiles -gt 1) {
                        $avgTime = $elapsed.TotalSeconds / $newFiles
                        $remaining = [math]::Round($avgTime * ($totalSchemas - $newFiles))
                        $eta = "~$remaining`s remaining"
                    } else {
                        $eta = "calculating..."
                    }
                    
                    # Build progress bar
                    $barWidth = 30
                    $filled = [math]::Floor($barWidth * $newFiles / $totalSchemas)
                    $empty = $barWidth - $filled
                    $bar = "[" + ("=" * $filled) + (">" * [math]::Min(1, $empty)) + (" " * [math]::Max(0, $empty - 1)) + "]"
                    
                    # Write progress on same line
                    Write-Host "`r  $bar $pct% ($newFiles/$totalSchemas schemas) $eta     " -ForegroundColor Cyan -NoNewline
                    
                    $lastCount = $currentCount
                }
            }
        }
        
        # Final progress update
        Write-Host ""
        $exitCode2 = $rProcess.ExitCode
        
        # Show any errors from stderr
        $stderrFile = "$tempDir\r_stderr.txt"
        if (Test-Path $stderrFile) {
            $stderrContent = Get-Content $stderrFile -Raw
            if ($stderrContent -and $stderrContent.Trim()) {
                # Filter out package loading messages
                $stderrContent -split "`n" | ForEach-Object {
                    $line = $_
                    if ($line -match '(Error|FAILED)' -and $line -notmatch 'masked from') {
                        Write-Host "  $line" -ForegroundColor Red
                    } elseif ($line -match '(Saved|Index saved|Done|schemas)') {
                        Write-Host "  $line" -ForegroundColor Green
                    } elseif (-not ($line -match '(masked from|Attaching package|dplyr|objects are)') -and $line.Trim()) {
                        Write-Host "  $line" -ForegroundColor DarkGray
                    }
                }
            }
            Remove-Item $stderrFile -ErrorAction SilentlyContinue
        }
        Remove-Item "$tempDir\r_stdout.txt" -ErrorAction SilentlyContinue
        Remove-Item $tempSchemaScript -ErrorAction SilentlyContinue
        
        if ($exitCode2 -ne 0) {
            Write-Host "[R] WARNING: schema_sync.R failed with exit code $exitCode2" -ForegroundColor Yellow
        }
        
        # Step 3: Run indicator_registry.R for unicef_indicators_metadata.yaml
        Write-Host ""
        Write-Host "[R] Running indicator_registry.R (indicator codelist cache)..." -ForegroundColor Cyan
        $tempIndicatorScript = Join-Path $tempDir "unicef_indicator_sync_$([guid]::NewGuid().ToString('N')).R"
        $rCodeIndicator = @"
setwd('$($RepoRoot -replace '\\', '/')')
source('R/indicator_registry.R')
n <- refresh_indicator_cache()
message(sprintf('Refreshed indicator cache with %d indicators', n))
"@
        [System.IO.File]::WriteAllText($tempIndicatorScript, $rCodeIndicator, [System.Text.Encoding]::ASCII)
        
        # Run with output streaming
        & $RscriptExe --vanilla $tempIndicatorScript 2>&1 | ForEach-Object { 
            $line = $_
            if ([string]::IsNullOrWhiteSpace($line)) {
                # Skip empty lines
            } elseif ($line -match '(Saved|indicators|Refreshed|cache)') {
                Write-Host "  $line" -ForegroundColor Green
            } elseif ($line -match '(Fetching|Parsing|Processing)') {
                Write-Host "  $line" -ForegroundColor Gray
            } elseif ($line -match '^Error:' -or $line -match 'Error in ') {
                Write-Host "  $line" -ForegroundColor Red
            } elseif ($line -match '(WARNING|Warning:)') {
                Write-Host "  $line" -ForegroundColor Yellow
            } elseif ($line -match '(masked from|Attaching package)') {
                if ($Verbose) { Write-Host "  $line" -ForegroundColor DarkGray }
            } else {
                Write-Host "  $line" -ForegroundColor DarkGray
            }
        }
        $exitCode3 = $LASTEXITCODE
        Remove-Item $tempIndicatorScript -ErrorAction SilentlyContinue
        
        if ($exitCode3 -ne 0) {
            Write-Host "[R] WARNING: indicator_registry.R failed with exit code $exitCode3" -ForegroundColor Yellow
        }
        
        # Consider success if at least one script succeeded
        if ($exitCode1 -eq 0 -or $exitCode2 -eq 0 -or $exitCode3 -eq 0) {
            $metadataDir = Join-Path $RepoRoot "R\metadata\current"
            $fileCount = (Get-ChildItem -Path $metadataDir -Filter "*.yaml" -ErrorAction SilentlyContinue).Count
            $dataflowsCount = (Get-ChildItem -Path "$metadataDir\dataflows" -Filter "*.yaml" -ErrorAction SilentlyContinue).Count
            Write-Host "[R] SUCCESS: Generated $fileCount core files + $dataflowsCount dataflow schemas" -ForegroundColor Green
            return $true
        } else {
            Write-Host "[R] ERROR: All sync scripts failed" -ForegroundColor Red
            return $false
        }
    }
    catch {
        Write-Host "[R] ERROR: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

# ----------------------------------------------------------------------------
# Stata Metadata Regeneration
# ----------------------------------------------------------------------------
function Regenerate-StataMetadata {
    Write-Host ""
    Write-Host "[Stata] Regenerating metadata..." -ForegroundColor Yellow
    Write-Host "----------------------------------------"
    
    # Check for existing files
    $StataMetadataDir = "$RepoRoot\stata\metadata\current"
    $checkResult = Check-ExistingFiles -Platform "Stata" -MetadataDir $StataMetadataDir
    if ($checkResult -eq $null) {
        return $null  # Skip
    }
    if (-Not $checkResult) {
        return $false  # Abort
    }
    
    # Ensure unicefData ado files are installed
    $StataAdoPath = "$RepoRoot\stata\src\u" -replace "\\", "/"
    $StataAdoPathUnderscore = "$RepoRoot\stata\src\_" -replace "\\", "/"
    
    if (-Not (Test-Path "$RepoRoot\stata\src\u")) {
        Write-Host "[Stata] ERROR: unicefData ado files not found at $StataAdoPath" -ForegroundColor Red
        return $false
    }

    # Path to the sync script
    $StataSyncScript = "$RepoRoot\stata\src\u\unicefdata_sync.ado"
    if (-Not (Test-Path $StataSyncScript)) {
        Write-Host "[Stata] ERROR: unicefdata_sync.ado not found at $StataSyncScript" -ForegroundColor Red
        return $false
    }

    # Find Stata executable
    $StataExe = $null
    $StataPaths = @(
        "C:\Program Files\Stata18\StataMP-64.exe",
        "C:\Program Files\Stata17\StataMP-64.exe",
        "C:\Program Files\Stata16\StataMP-64.exe",
        "C:\Program Files\Stata18\StataSE-64.exe",
        "C:\Program Files\Stata17\StataSE-64.exe",
        "C:\Program Files\Stata16\StataSE-64.exe"
    )
    foreach ($path in $StataPaths) {
        if (Test-Path $path) {
            $StataExe = $path
            break
        }
    }
    
    if (-Not $StataExe) {
        Write-Host "[Stata] ERROR: Stata executable not found" -ForegroundColor Red
        return $false
    }
    
    Write-Host "[Stata] Using Stata: $StataExe"
    
    $metadataPath = "$($RepoRoot -replace '\\', '/')/stata/metadata/current"
    $pythonSuccess = $false
    $stataOnlySuccess = $false
    
    # -------------------------------------------------------------------------
    # Step 1: Run with Python helper (default, recommended)
    # -------------------------------------------------------------------------
    Write-Host ""
    Write-Host "[Stata] Step 1/2: Running with Python helper (forcepython)..." -ForegroundColor Cyan
    
    $tempDoFile = Join-Path $RepoRoot "unicefdata_sync_temp.do"
    $doFileContent = @"
// Add ado paths for unicefData
adopath ++ "$StataAdoPath"
adopath ++ "$StataAdoPathUnderscore"

// Run the sync command with Python helper (default, handles large XML)
unicefdata_sync, path("$metadataPath") verbose forcepython force

// Exit
exit, clear STATA
"@
    $doFileContent | Out-File -FilePath $tempDoFile -Encoding ASCII -Force
    
    try {
        Push-Location $RepoRoot
        Write-Host "[Stata] Executing Stata batch mode (Python helper)..." -ForegroundColor Gray
        cmd /c "`"$StataExe`" /e do `"$tempDoFile`"" 2>&1 | Out-Null
        $exitCode1 = $LASTEXITCODE
        
        # Show relevant log output
        $logFile = [System.IO.Path]::ChangeExtension($tempDoFile, ".log")
        if (Test-Path $logFile) {
            Get-Content $logFile | ForEach-Object {
                if ($_ -match '\[OK\]|SUCCESS|Generated|synced|indicators|dataflows') {
                    Write-Host "  $_" -ForegroundColor Green
                } elseif ($_ -match 'error|failed|r\(\d+\)|macro substitution') {
                    Write-Host "  $_" -ForegroundColor Red
                } elseif ($_ -match 'warning') {
                    Write-Host "  $_" -ForegroundColor Yellow
                }
            }
            Remove-Item $logFile -ErrorAction SilentlyContinue
        }
        
        Pop-Location
        Remove-Item $tempDoFile -ErrorAction SilentlyContinue
        
        if ($exitCode1 -eq 0) {
            $fileCount = (Get-ChildItem -Path $StataMetadataDir -Filter "*.yaml" -ErrorAction SilentlyContinue | Where-Object { $_.Name -notmatch '_stataonly' }).Count
            Write-Host "[Stata] Python helper: Generated $fileCount files" -ForegroundColor Green
            $pythonSuccess = $true
        } else {
            Write-Host "[Stata] Python helper: Failed with exit code $exitCode1" -ForegroundColor Yellow
        }
    }
    catch {
        Write-Host "[Stata] Python helper ERROR: $($_.Exception.Message)" -ForegroundColor Red
    }
    
    # -------------------------------------------------------------------------
    # Step 2: Run with pure Stata parser (for comparison, with _stataonly suffix)
    # -------------------------------------------------------------------------
    Write-Host ""
    Write-Host "[Stata] Step 2/2: Running with pure Stata parser (forcestata)..." -ForegroundColor Cyan
    
    $tempDoFile2 = Join-Path $RepoRoot "unicefdata_sync_stataonly_temp.do"
    $doFileContent2 = @"
// Add ado paths for unicefData
adopath ++ "$StataAdoPath"
adopath ++ "$StataAdoPathUnderscore"

// Run the sync command with pure Stata parser (for comparison)
// Uses _stataonly suffix to avoid overwriting Python-assisted files
unicefdata_sync, path("$metadataPath") verbose forcestata suffix("_stataonly") force

// Exit
exit, clear STATA
"@
    $doFileContent2 | Out-File -FilePath $tempDoFile2 -Encoding ASCII -Force
    
    try {
        Push-Location $RepoRoot
        Write-Host "[Stata] Executing Stata batch mode (pure Stata)..." -ForegroundColor Gray
        cmd /c "`"$StataExe`" /e do `"$tempDoFile2`"" 2>&1 | Out-Null
        $exitCode2 = $LASTEXITCODE
        
        # Show relevant log output
        $logFile2 = [System.IO.Path]::ChangeExtension($tempDoFile2, ".log")
        if (Test-Path $logFile2) {
            Get-Content $logFile2 | ForEach-Object {
                if ($_ -match '\[OK\]|SUCCESS|Generated|synced|indicators|dataflows') {
                    Write-Host "  $_" -ForegroundColor Green
                } elseif ($_ -match 'error|failed|r\(\d+\)|macro substitution') {
                    Write-Host "  $_" -ForegroundColor Red
                } elseif ($_ -match 'warning') {
                    Write-Host "  $_" -ForegroundColor Yellow
                }
            }
            Remove-Item $logFile2 -ErrorAction SilentlyContinue
        }
        
        Pop-Location
        Remove-Item $tempDoFile2 -ErrorAction SilentlyContinue
        
        if ($exitCode2 -eq 0) {
            $stataOnlyCount = (Get-ChildItem -Path $StataMetadataDir -Filter "*_stataonly*.yaml" -ErrorAction SilentlyContinue).Count
            Write-Host "[Stata] Pure Stata: Generated $stataOnlyCount files (with _stataonly suffix)" -ForegroundColor Green
            $stataOnlySuccess = $true
        } else {
            Write-Host "[Stata] Pure Stata: Failed with exit code $exitCode2" -ForegroundColor Yellow
        }
    }
    catch {
        Write-Host "[Stata] Pure Stata ERROR: $($_.Exception.Message)" -ForegroundColor Red
    }
    finally {
        if (Test-Path $tempDoFile2) {
            Remove-Item $tempDoFile2 -Force -ErrorAction SilentlyContinue
        }
    }
    
    # -------------------------------------------------------------------------
    # Detailed Summary
    # -------------------------------------------------------------------------
    Write-Host ""
    Write-Host "[Stata] ========================================" -ForegroundColor Cyan
    Write-Host "[Stata] RESULTS SUMMARY" -ForegroundColor Cyan
    Write-Host "[Stata] ========================================" -ForegroundColor Cyan
    
    # Get file lists
    $allFiles = Get-ChildItem -Path $StataMetadataDir -Filter "*.yaml" -ErrorAction SilentlyContinue
    $pythonFiles = $allFiles | Where-Object { $_.Name -notmatch '_stataonly' }
    $stataOnlyFiles = $allFiles | Where-Object { $_.Name -match '_stataonly' }
    
    # Core metadata files (expected from each method)
    $coreFileNames = @(
        "_unicefdata_dataflows",
        "_unicefdata_indicators", 
        "_unicefdata_codelists",
        "_unicefdata_countries",
        "_unicefdata_regions",
        "unicef_indicators_metadata",
        "dataflow_index"
    )
    
    Write-Host ""
    Write-Host "[Stata] Python Helper (forcepython):" -ForegroundColor Yellow
    if ($pythonSuccess) {
        Write-Host "  Status: " -NoNewline; Write-Host "[OK] SUCCESS" -ForegroundColor Green
        Write-Host "  Files generated: $($pythonFiles.Count)" -ForegroundColor Gray
        foreach ($coreName in $coreFileNames) {
            $exactPattern = $coreName + ".yaml"
            $prefixPattern = $coreName + "_*.yaml"
            $found = $pythonFiles | Where-Object { ($_.Name -eq $exactPattern) -or (($_.Name -like $prefixPattern) -and ($_.Name -notmatch '_stataonly')) }
            if ($found) {
                Write-Host "    [OK] $($found.Name)" -ForegroundColor Green
            } else {
                Write-Host "    [X] $exactPattern (missing)" -ForegroundColor Red
            }
        }
    } else {
        Write-Host "  Status: " -NoNewline; Write-Host "[X] FAILED" -ForegroundColor Red
    }
    
    Write-Host ""
    Write-Host "[Stata] Pure Stata Parser (forcestata):" -ForegroundColor Yellow
    if ($stataOnlySuccess) {
        Write-Host "  Status: " -NoNewline; Write-Host "[OK] SUCCESS" -ForegroundColor Green
        Write-Host "  Files generated: $($stataOnlyFiles.Count)" -ForegroundColor Gray
        foreach ($coreName in $coreFileNames) {
            $stataOnlyName = $coreName + "_stataonly.yaml"
            $found = $stataOnlyFiles | Where-Object { $_.Name -eq $stataOnlyName }
            if ($found) {
                Write-Host "    [OK] $($found.Name)" -ForegroundColor Green
            } else {
                # Check if it's the indicator metadata (expected to fail due to macro limits)
                if ($coreName -eq "unicef_indicators_metadata") {
                    Write-Host "    [X] $stataOnlyName (expected: macro limits)" -ForegroundColor Yellow
                } else {
                    Write-Host "    [X] $stataOnlyName (missing)" -ForegroundColor Red
                }
            }
        }
    } else {
        Write-Host "  Status: " -NoNewline; Write-Host "[X] FAILED" -ForegroundColor Red
    }
    
    # Count dataflow schema files
    $schemaFiles = Get-ChildItem -Path "$StataMetadataDir\dataflows" -Filter "*.yaml" -ErrorAction SilentlyContinue
    $pythonSchemas = $schemaFiles | Where-Object { $_.Name -notmatch '_stataonly' }
    $stataOnlySchemas = $schemaFiles | Where-Object { $_.Name -match '_stataonly' }
    
    Write-Host ""
    Write-Host "[Stata] Dataflow Schemas (dataflows/ folder):" -ForegroundColor Yellow
    if ($pythonSchemas.Count -gt 0) {
        Write-Host "  Python helper: $($pythonSchemas.Count) schema files" -ForegroundColor Gray
    }
    if ($stataOnlySchemas.Count -gt 0) {
        Write-Host "  Pure Stata:    $($stataOnlySchemas.Count) schema files (*_stataonly.yaml)" -ForegroundColor Gray
    }
    
    Write-Host ""
    Write-Host "[Stata] ========================================" -ForegroundColor Cyan
    $totalFiles = $allFiles.Count + $schemaFiles.Count
    Write-Host "[Stata] TOTAL: $totalFiles metadata files in stata/metadata/" -ForegroundColor Cyan
    Write-Host "[Stata] ========================================" -ForegroundColor Cyan
    
    if ($pythonSuccess -or $stataOnlySuccess) {
        return $true
    } else {
        Write-Host "[Stata] ERROR: Both sync methods failed" -ForegroundColor Red
        return $false
    }
}

# ----------------------------------------------------------------------------
# Main Execution
# ----------------------------------------------------------------------------

$results = @{
    Python = $null
    R = $null
    Stata = $null
}

if ($All -or $Python) {
    $results.Python = Regenerate-PythonMetadata
}

if ($All -or $R) {
    $results.R = Regenerate-RMetadata
}

if ($All -or $Stata) {
    $results.Stata = Regenerate-StataMetadata
}

# ----------------------------------------------------------------------------
# Summary
# ----------------------------------------------------------------------------
Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host " Summary" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan

foreach ($lang in @("Python", "R", "Stata")) {
    $status = $results[$lang]
    if ($status -eq $null) {
        Write-Host "  $lang : SKIPPED" -ForegroundColor Gray
    } elseif ($status) {
        Write-Host "  $lang : PASSED" -ForegroundColor Green
    } else {
        Write-Host "  $lang : FAILED" -ForegroundColor Red
    }
}

Write-Host ""

# Return success if all executed languages passed
$allPassed = $true
foreach ($result in $results.Values) {
    if ($result -eq $false) {
        $allPassed = $false
        break
    }
}

# Stop transcript
Stop-Transcript | Out-Null
Write-Host "Log saved to: $LogFile" -ForegroundColor Gray

if ($allPassed) {
    Write-Host "All metadata regeneration completed successfully!" -ForegroundColor Green
    exit 0
} else {
    Write-Host "Some regeneration tasks failed. Check output above." -ForegroundColor Red
    exit 1
}
