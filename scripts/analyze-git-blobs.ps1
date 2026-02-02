#!/usr/bin/env pwsh
# Find large blobs in git history
param(
    [string]$RepoPath = "C:\GitHub\myados\unicefData",
    [int]$TopCount = 30
)

Write-Host "=== Git History Large Blobs ===" -ForegroundColor Cyan
Write-Host "Analyzing repository: $RepoPath"
Write-Host "Showing top $TopCount largest blobs"
Write-Host ""

Push-Location $RepoPath

# Get all blob objects with sizes
$output = git rev-list --objects --all | git cat-file --batch-check='%(objecttype) %(objectname) %(objectsize) %(rest)'

$blobs = @()
$output | ForEach-Object {
    if ($_ -match '^blob (\S+) (\d+) (.*)$') {
        $blobs += [PSCustomObject]@{
            Hash = $Matches[1]
            SizeMB = [math]::Round([int]$Matches[2] / 1MB, 2)
            SizeKB = [math]::Round([int]$Matches[2] / 1KB, 0)
            Path = $Matches[3]
        }
    }
}

Pop-Location

# Show large blobs
$blobs | Where-Object { $_.SizeMB -gt 0.1 } | 
         Sort-Object -Property SizeMB -Descending | 
         Select-Object -First $TopCount |
         Format-Table -Property SizeMB, SizeKB, Path -AutoSize

Write-Host ""
Write-Host "Total blobs > 100KB: $(($blobs | Where-Object { $_.SizeMB -gt 0.1 }).Count)" -ForegroundColor Yellow
Write-Host "Total blobs analyzed: $($blobs.Count)" -ForegroundColor Cyan
