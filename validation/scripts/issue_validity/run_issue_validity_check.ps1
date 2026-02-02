#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Quick launcher for Issue Validity Checker

.DESCRIPTION
    Activates Python environment and runs the issue validity check script
    
.EXAMPLE
    .\run_issue_validity_check.ps1
    
.NOTES
    Requires Python and Stata 17 to be installed
    Results saved to: validation/results/issue_validity/TIMESTAMP/
#>

# Set error action
$ErrorActionPreference = "Stop"

# Get repo root (issue_validity -> scripts -> validation -> repo)
$repoRoot = (Get-Item $PSScriptRoot).Parent.Parent.Parent.FullName
Write-Host "Repository root: $repoRoot" -ForegroundColor Cyan

# Activate venv
$venvPath = Join-Path $repoRoot ".venv" "Scripts" "Activate.ps1"
if (-not (Test-Path $venvPath)) {
    Write-Host "ERROR: Virtual environment not found at $venvPath" -ForegroundColor Red
    exit 1
}

Write-Host "Activating Python virtual environment..." -ForegroundColor Yellow
& $venvPath

# Change to repo root
Set-Location $repoRoot

# Run the script
$scriptPath = Join-Path $PSScriptRoot "check_issues_validity.py"
if (-not (Test-Path $scriptPath)) {
    Write-Host "ERROR: Script not found at $scriptPath" -ForegroundColor Red
    exit 1
}

Write-Host "`nRunning issue validity checker..." -ForegroundColor Yellow
Write-Host "This will take approximately 10-15 minutes" -ForegroundColor Yellow
Write-Host ""

python $scriptPath

# Show results location
$resultsBase = Join-Path $repoRoot "validation" "results" "issue_validity"
if (Test-Path $resultsBase) {
    $latestResult = Get-ChildItem $resultsBase | Sort-Object LastWriteTime -Descending | Select-Object -First 1
    if ($latestResult) {
        Write-Host ""
        Write-Host "Results saved to:" -ForegroundColor Green
        Write-Host "  $($latestResult.FullName)" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "View results:" -ForegroundColor Green
        Write-Host "  Report: $(Join-Path $latestResult.FullName 'issue_validity_report.txt')" -ForegroundColor Cyan
        Write-Host "  JSON: $(Join-Path $latestResult.FullName 'issue_validity_results.json')" -ForegroundColor Cyan
    }
}
