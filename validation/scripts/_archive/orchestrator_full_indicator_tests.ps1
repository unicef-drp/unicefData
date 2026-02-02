# orchestrator_full_indicator_tests.ps1
# Version 1.0.0  10Jan2026
#
# Full orchestrator for comprehensive cross-platform indicator testing
#
# This script:
# 1. Runs Python comprehensive test suite
# 2. Runs R indicator test suite
# 3. Runs Stata indicator test suite
# 4. Compiles cross-language comparison report
# 5. Generates summary report
#
# Usage:
#   .\validation\orchestrator_full_indicator_tests.ps1
#   .\validation\orchestrator_full_indicator_tests.ps1 -Limit 5
#   .\validation\orchestrator_full_indicator_tests.ps1 -OnlyPython
#   .\validation\orchestrator_full_indicator_tests.ps1 -OnlyR
#   .\validation\orchestrator_full_indicator_tests.ps1 -OnlyStata

param(
    [int]$Limit = $null,
    [string[]]$Indicators = $null,
    [string[]]$Languages = $null,
    [string[]]$Countries = @("USA", "BRA", "IND", "KEN", "CHN"),
    [string]$Year = "2020",
    [string]$OutputDir = $null,
    [switch]$OnlyPython,
    [switch]$OnlyR,
    [switch]$OnlyStata,
    [switch]$NoReport,
    [switch]$Verbose
)

$ErrorActionPreference = "Stop"
$VerbosePreference = if ($Verbose) { "Continue" } else { "SilentlyContinue" }

# =============================================================================
# Setup
# =============================================================================

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot = Split-Path -Parent $scriptDir
$pythonScript = Join-Path $scriptDir "test_all_indicators_comprehensive.py"
$rScript = Join-Path $scriptDir "test_indicator_suite.R"
$stataScript = Join-Path $scriptDir "test_indicator_suite.do"

$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$resultsBase = Join-Path $scriptDir "results"
$resultsDir = Join-Path $resultsBase "full_validation_$timestamp"
$logFile = Join-Path $resultsDir "orchestrator_log.txt"

New-Item -ItemType Directory -Path $resultsDir -Force | Out-Null

function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] [$Level] $Message"
    Write-Host $logMessage
    Add-Content -Path $logFile -Value $logMessage
}

Write-Log "========================================================================="
Write-Log "UNICEF Indicator Validation - Full Cross-Platform Suite"
Write-Log "========================================================================="
Write-Log "Results directory: $resultsDir"
Write-Log "Log file: $logFile"
Write-Log ""

# Determine which languages to test
$testLanguages = @()
if ($OnlyPython) {
    $testLanguages = @("python")
}
elseif ($OnlyR) {
    $testLanguages = @("r")
}
elseif ($OnlyStata) {
    $testLanguages = @("stata")
}
elseif ($Languages) {
    $testLanguages = $Languages
}
else {
    $testLanguages = @("python", "r", "stata")
}

Write-Log "Languages to test: $($testLanguages -join ', ')"
Write-Log "Countries: $($Countries -join ', ')"
Write-Log "Year: $Year"
Write-Log ""

# =============================================================================
# Python Test
# =============================================================================

if ($testLanguages -contains "python") {
    Write-Log "Starting Python comprehensive indicator test..."
    
    try {
        $pythonArgs = @(
            $pythonScript,
            "--languages", "python",
            "--countries", $Countries,
            "--year", $Year,
            "--output-dir", $resultsBase
        )
        
        if ($Limit) {
            $pythonArgs += "--limit", $Limit
        }
        
        if ($Indicators) {
            $pythonArgs += "--indicators", $Indicators
        }
        
        Write-Log "Running: python $($pythonArgs -join ' ')"
        $startTime = Get-Date
        
        & python @pythonArgs 2>&1 | Tee-Object -FilePath (Join-Path $resultsDir "python_test.log")
        
        $duration = (Get-Date) - $startTime
        Write-Log "✓ Python test completed in $($duration.TotalSeconds)s"
    }
    catch {
        Write-Log "✗ Python test failed: $_" "ERROR"
    }
}

# =============================================================================
# R Test
# =============================================================================

if ($testLanguages -contains "r") {
    Write-Log ""
    Write-Log "Starting R indicator test suite..."
    
    try {
        $rArgs = $rScript
        Write-Log "Running: Rscript $rArgs"
        $startTime = Get-Date
        
        & Rscript $rArgs 2>&1 | Tee-Object -FilePath (Join-Path $resultsDir "r_test.log")
        
        $duration = (Get-Date) - $startTime
        Write-Log "✓ R test completed in $($duration.TotalSeconds)s"
    }
    catch {
        Write-Log "✗ R test failed: $_" "ERROR"
    }
}

# =============================================================================
# Stata Test
# =============================================================================

if ($testLanguages -contains "stata") {
    Write-Log ""
    Write-Log "Starting Stata indicator test suite..."
    
    try {
        $stataArgs = @(
            "/e", "do", "$stataScript"
        )
        
        Write-Log "Running: stata-cli do $stataScript"
        $startTime = Get-Date
        
        & stata-cli do $stataScript 2>&1 | Tee-Object -FilePath (Join-Path $resultsDir "stata_test.log")
        
        $duration = (Get-Date) - $startTime
        Write-Log "✓ Stata test completed in $($duration.TotalSeconds)s"
    }
    catch {
        Write-Log "✗ Stata test failed: $_" "ERROR"
    }
}

# =============================================================================
# Report Generation
# =============================================================================

if (-not $NoReport) {
    Write-Log ""
    Write-Log "Generating cross-language comparison report..."
    
    try {
        $comparisonScript = Join-Path $scriptDir "validate_cross_language.py"
        if (Test-Path $comparisonScript) {
            Write-Log "Running: python $comparisonScript --report $resultsDir/CROSS_LANGUAGE_REPORT.md"
            & python $comparisonScript --report (Join-Path $resultsDir "CROSS_LANGUAGE_REPORT.md") 2>&1 | `
                Tee-Object -FilePath (Join-Path $resultsDir "comparison.log")
        }
    }
    catch {
        Write-Log "⚠ Comparison report generation failed (non-critical): $_" "WARN"
    }
}

# =============================================================================
# Summary
# =============================================================================

Write-Log ""
Write-Log "========================================================================="
Write-Log "VALIDATION COMPLETE"
Write-Log "========================================================================="
Write-Log ""
Write-Log "Results saved to:"
Write-Log "  Results directory: $resultsDir"
Write-Log "  Log file: $logFile"
Write-Log ""

# List generated files
Write-Log "Generated files:"
Get-ChildItem -Path $resultsDir -Recurse -File | ForEach-Object {
    $relPath = $_.FullName.Replace("$resultsDir\", "")
    Write-Log "  $relPath ($([Math]::Round($_.Length / 1KB, 2)) KB)"
}

Write-Log ""
Write-Log "========================================================================="
Write-Log "Summary:"
Write-Log "  Check CSV results in: $resultsDir\python\success\, $resultsDir\r\success\, $resultsDir\stata\success\"
Write-Log "  Check errors in: $resultsDir\*\failed\"
Write-Log "  Full logs: $resultsDir\*.log"
Write-Log "========================================================================="
