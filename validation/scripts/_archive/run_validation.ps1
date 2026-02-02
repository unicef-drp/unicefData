#!/usr/bin/env pwsh
# Validation Runner with Centralized Logging
# Usage: .\scripts\run_validation.ps1 -Indicators @("CME_MRY15T24", ...) -Seed 50 -Languages @("python", "r", "stata")

param(
    [Parameter(Mandatory = $true)]
    [string[]]$Indicators,
    
    [int]$Seed = 42,
    
    [string[]]$Languages = @("python"),
    
    [switch]$Background,
    
    [switch]$Verbose
)

# ─────────────────────────────────────────────────────────────────────
# Setup
# ─────────────────────────────────────────────────────────────────────

$PROJECT_ROOT = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
$SCRIPTS_DIR = "$PROJECT_ROOT\validation\scripts"
$LOGS_DIR = "$PROJECT_ROOT\logs\validation"

Write-Host ""
Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "UNICEF Validation Runner with Centralized Logging" -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""

# Ensure log directories exist
New-Item -ItemType Directory -Path "$PROJECT_ROOT\logs\tests" -Force | Out-Null
New-Item -ItemType Directory -Path "$PROJECT_ROOT\logs\validation" -Force | Out-Null
Write-Host "✓ Project Root: $PROJECT_ROOT" -ForegroundColor Green
Write-Host "✓ Scripts Dir:  $SCRIPTS_DIR" -ForegroundColor Green
Write-Host "✓ Logs Dir:     $LOGS_DIR" -ForegroundColor Green
Write-Host ""

# ─────────────────────────────────────────────────────────────────────
# Generate Log File Path
# ─────────────────────────────────────────────────────────────────────

$timestamp = Get-Date -Format 'yyyyMMdd_HHmmss'
$LOG_FILE = "$LOGS_DIR\validation_run_$timestamp.log"

Write-Host "📋 Validation Configuration:" -ForegroundColor Cyan
Write-Host "   Indicators: $($Indicators.Count) indicators"
Write-Host "   Seed:       $Seed"
Write-Host "   Languages:  $($Languages -join ', ')"
Write-Host "   Log File:   $LOG_FILE"
Write-Host ""

# ─────────────────────────────────────────────────────────────────────
# Build Command Arguments
# ─────────────────────────────────────────────────────────────────────

$args_list = @("--indicators") + $Indicators
$args_list += @("--seed", $Seed)
foreach ($lang in $Languages) {
    $args_list += @("--languages", $lang)
}

if ($Verbose) {
    Write-Host "Command: python test_all_indicators_comprehensive.py $($args_list -join ' ')" -ForegroundColor Yellow
    Write-Host ""
}

# ─────────────────────────────────────────────────────────────────────
# Run Validation
# ─────────────────────────────────────────────────────────────────────

if ($Background) {
    Write-Host "🚀 Starting validation in background..." -ForegroundColor Cyan
    Write-Host ""
    
    $scriptBlock = {
        param($dir, $args, $log)
        cd $dir
        python test_all_indicators_comprehensive.py @args 2>&1 | Tee-Object -FilePath $log
    }
    
    $job = Start-Job -ScriptBlock $scriptBlock -ArgumentList $SCRIPTS_DIR, $args_list, $LOG_FILE
    
    Write-Host "✓ Job ID:     $($job.Id)" -ForegroundColor Green
    Write-Host "✓ Log File:   $LOG_FILE" -ForegroundColor Green
    Write-Host ""
    Write-Host "To check progress:" -ForegroundColor Yellow
    Write-Host "  Get-Content '$LOG_FILE' -Wait" -ForegroundColor White
    Write-Host ""
    Write-Host "To cancel:" -ForegroundColor Yellow
    Write-Host "  Stop-Job -Id $($job.Id)" -ForegroundColor White
    Write-Host ""
    
} else {
    Write-Host "🚀 Starting validation..." -ForegroundColor Cyan
    Write-Host ""
    
    cd $SCRIPTS_DIR
    python test_all_indicators_comprehensive.py @args_list 2>&1 | Tee-Object -FilePath $LOG_FILE
    
    $exit_code = $LASTEXITCODE
    
    Write-Host ""
    Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host "✓ Validation Complete" -ForegroundColor Green
    Write-Host "✓ Log saved to: $LOG_FILE" -ForegroundColor Green
    Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host ""
    
    exit $exit_code
}
