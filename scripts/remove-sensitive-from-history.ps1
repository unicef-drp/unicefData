#!/usr/bin/env pwsh
# Remove sensitive folders from git history using BFG Repo-Cleaner
# WARNING: This rewrites git history - requires force push

param(
    [string]$RepoPath = "C:\GitHub\myados\unicefData",
    [switch]$DryRun
)

$ErrorActionPreference = "Stop"

Write-Host "=== Sensitive Content Removal from Git History ===" -ForegroundColor Red
Write-Host ""

# Check for BFG
$bfgPath = "C:\Tools\bfg.jar"
if (-not (Test-Path $bfgPath)) {
    Write-Host "ERROR: BFG Repo-Cleaner not found at $bfgPath" -ForegroundColor Red
    Write-Host "Download from: https://rtyley.github.io/bfg-repo-cleaner/" -ForegroundColor Yellow
    Write-Host "Save as: $bfgPath" -ForegroundColor Yellow
    exit 1
}

# Folders to remove from history
$sensitiveFolders = @(
    "paper",
    "internal",
    "drafts",
    "benchmarks",
    "eb1a",
    "_drafts"
)

Write-Host "Sensitive folders to remove from history:" -ForegroundColor Yellow
$sensitiveFolders | ForEach-Object { Write-Host "  - $_/" -ForegroundColor Red }
Write-Host ""

# Verify current folder presence in history
Write-Host "Checking current presence in git history..." -ForegroundColor Cyan
Push-Location $RepoPath

$foundFolders = @()
foreach ($folder in $sensitiveFolders) {
    $files = git log --all --pretty=format: --name-only --diff-filter=A | 
             Where-Object { $_ -match "^$folder/" } | 
             Select-Object -First 1
    
    if ($files) {
        $foundFolders += $folder
        Write-Host "  ✗ FOUND: $folder/ (in history)" -ForegroundColor Red
    } else {
        Write-Host "  ✓ Clean: $folder/ (not in history)" -ForegroundColor Green
    }
}

Pop-Location
Write-Host ""

if ($foundFolders.Count -eq 0) {
    Write-Host "✅ No sensitive folders found in git history. Nothing to clean." -ForegroundColor Green
    exit 0
}

if ($DryRun) {
    Write-Host "DRY RUN: Would remove these folders from history:" -ForegroundColor Yellow
    $foundFolders | ForEach-Object { Write-Host "  - $_/" }
    Write-Host ""
    Write-Host "Run without -DryRun to execute cleanup." -ForegroundColor Yellow
    exit 0
}

# Confirmation prompt
Write-Host "⚠️  WARNING: This will REWRITE GIT HISTORY!" -ForegroundColor Red
Write-Host "This operation is DESTRUCTIVE and requires force-push to all remotes." -ForegroundColor Red
Write-Host ""
Write-Host "Safety checklist:" -ForegroundColor Yellow
Write-Host "  - Pre-cleanup tags created? (pre-cleanup-public-20260113)" -ForegroundColor Yellow
Write-Host "  - Full backup exists? (backups\unicefData-backup-20260113.zip)" -ForegroundColor Yellow
Write-Host "  - Private repo verified? (verify-content-sync.ps1 passed)" -ForegroundColor Yellow
Write-Host ""
$confirm = Read-Host "Type 'DELETE HISTORY' to proceed (case-sensitive)"

if ($confirm -ne "DELETE HISTORY") {
    Write-Host "Aborted." -ForegroundColor Yellow
    exit 1
}

# Create mirror clone
Write-Host ""
Write-Host "Creating mirror clone..." -ForegroundColor Cyan
$mirrorPath = "$RepoPath-mirror.git"
if (Test-Path $mirrorPath) {
    Remove-Item -Recurse -Force $mirrorPath
}

Push-Location (Split-Path $RepoPath -Parent)
git clone --mirror $RepoPath "$mirrorPath"
Pop-Location

# Run BFG for each folder
Write-Host ""
Write-Host "Running BFG to remove sensitive folders..." -ForegroundColor Cyan
foreach ($folder in $foundFolders) {
    Write-Host "  Removing: $folder/" -ForegroundColor Yellow
    java -jar $bfgPath --delete-folders $folder --no-blob-protection $mirrorPath
}

# Cleanup
Write-Host ""
Write-Host "Cleaning up repository..." -ForegroundColor Cyan
Push-Location $mirrorPath
git reflog expire --expire=now --all
git gc --prune=now --aggressive
Pop-Location

# Update main repo
Write-Host ""
Write-Host "Updating main repository..." -ForegroundColor Cyan
Push-Location $RepoPath
git fetch --all
git reset --hard origin/main
Pop-Location

# Summary
Write-Host ""
Write-Host "=== Cleanup Complete ===" -ForegroundColor Green
Write-Host ""
Write-Host "⚠️  NEXT STEPS (CRITICAL):" -ForegroundColor Red
Write-Host "1. Verify cleanup:" -ForegroundColor Yellow
Write-Host "   cd C:\GitHub\myados\unicefData-dev" -ForegroundColor Gray
Write-Host "   .\scripts\verify-cleanup-success.ps1" -ForegroundColor Gray
Write-Host ""
Write-Host "2. If verification passes, force-push to remotes:" -ForegroundColor Yellow
Write-Host "   cd C:\GitHub\myados\unicefData" -ForegroundColor Gray
Write-Host "   git push origin --force --all" -ForegroundColor Gray
Write-Host "   git push origin --force --tags" -ForegroundColor Gray
Write-Host "   git push jpazvd --force --all" -ForegroundColor Gray
Write-Host "   git push jpazvd --force --tags" -ForegroundColor Gray
Write-Host ""
Write-Host "3. Notify all collaborators to re-clone the repository" -ForegroundColor Yellow
Write-Host ""
Write-Host "Mirror repo left at: $mirrorPath" -ForegroundColor Cyan
Write-Host "You can delete it after successful push: Remove-Item -Recurse -Force '$mirrorPath'" -ForegroundColor Cyan
