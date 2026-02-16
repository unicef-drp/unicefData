# Setup Git hooks for unicefData repository (Windows)
# Run once after cloning: .\scripts\setup-hooks.ps1

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RepoRoot = Split-Path -Parent $ScriptDir
$HooksSrc = Join-Path $ScriptDir "git-hooks"
$HooksDst = Join-Path $RepoRoot ".git\hooks"

Write-Host "Installing Git hooks..."

if (Test-Path $HooksSrc) {
    Copy-Item "$HooksSrc\post-checkout" "$HooksDst\post-checkout" -Force
    Copy-Item "$HooksSrc\post-checkout" "$HooksDst\post-merge" -Force
    Write-Host "Installed: post-checkout, post-merge"
} else {
    Write-Error "ERROR: $HooksSrc not found"
    exit 1
}

Write-Host "Running initial fixture unpack..."
$FixturesZip = Join-Path $RepoRoot "tests\fixtures.zip"
$FixturesDir = Join-Path $RepoRoot "tests\fixtures"

if (Test-Path $FixturesZip) {
    try {
        Expand-Archive -Path $FixturesZip -DestinationPath $FixturesDir -Force
        Write-Host "Test fixtures unpacked."
    } catch {
        Write-Error "ERROR: Failed to unpack fixtures: $_"
        exit 1
    }
}

Write-Host "Done!"
