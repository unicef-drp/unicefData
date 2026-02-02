#!/usr/bin/env pwsh
# Analyze directory sizes to find bloat
param(
    [string]$RepoPath = "C:\GitHub\myados\unicefData",
    [int]$MinSizeMB = 10
)

Write-Host "=== Directory Size Analysis ===" -ForegroundColor Cyan
Write-Host "Repository: $RepoPath"
Write-Host "Minimum size: $MinSizeMB MB"
Write-Host ""

$results = @()

Get-ChildItem -Path $RepoPath -Directory -Recurse -ErrorAction SilentlyContinue | ForEach-Object {
    $dir = $_
    $size = (Get-ChildItem $dir.FullName -Recurse -File -ErrorAction SilentlyContinue | 
             Measure-Object -Property Length -Sum).Sum / 1MB
    
    if ($size -ge $MinSizeMB) {
        $relativePath = $dir.FullName.Replace($RepoPath, "").TrimStart('\')
        $results += [PSCustomObject]@{
            Path = $relativePath
            SizeMB = [math]::Round($size, 2)
        }
    }
}

$results | Sort-Object -Property SizeMB -Descending | Format-Table -AutoSize

Write-Host ""
Write-Host "Total directories > ${MinSizeMB}MB: $($results.Count)" -ForegroundColor Yellow
