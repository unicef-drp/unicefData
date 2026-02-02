$ado_src = "C:\Users\jpazevedo\ado\plus"
$repo_dst = "C:\GitHub\myados\unicefData\stata\src"
$dev_dst = "C:\GitHub\myados\unicefData-dev\stata\src"

Write-Host "UNICEF FILE SYNCHRONIZATION" -ForegroundColor Cyan
Write-Host "Source: $ado_src"
Write-Host "Dest:   $repo_dst and $dev_dst`n"

# Helper files
$helper_files = @(
    "_get_dataflow_direct.ado",
    "_get_dataflow_for_indicator.ado",
    "_query_metadata.ado",
    "_query_indicators.ado",
    "_unicef_indicator_info.ado",
    "_unicef_load_fallback_sequences.ado",
    "_unicef_fetch_with_fallback.ado",
    "_linewrap.ado",
    "_metadata_linewrap.ado",
    "__unicef_parse_indicator_yaml.ado"
)

Write-Host "Syncing helper files..." -ForegroundColor Yellow
$count = 0
foreach ($file in $helper_files) {
    $src = Join-Path $ado_src "_" $file
    if (Test-Path $src) {
        Copy-Item -Path $src -Destination (Join-Path $repo_dst "_" $file) -Force -EA SilentlyContinue
        Copy-Item -Path $src -Destination (Join-Path $dev_dst "_" $file) -Force -EA SilentlyContinue
        Write-Host "  ✓ $file"
        $count++
    }
}
Write-Host "  Synced: $count files`n"

# YAML files
$yaml_files = @("_dataflow_fallback_sequences.yaml", "_unicefdata_dataflow_metadata.yaml")

Write-Host "Syncing YAML metadata files..." -ForegroundColor Yellow
$count = 0
foreach ($file in $yaml_files) {
    $src = Join-Path $ado_src "_" $file
    if (Test-Path $src) {
        Copy-Item -Path $src -Destination (Join-Path $repo_dst "_" $file) -Force -EA SilentlyContinue
        Copy-Item -Path $src -Destination (Join-Path $dev_dst "_" $file) -Force -EA SilentlyContinue
        Write-Host "  ✓ $file"
        $count++
    }
}
Write-Host "  Synced: $count files`n"

# Main commands
$cmd_files = @("unicefdata.ado", "unicefdata_sync.ado", "unicefdata_examples.ado", "unicefdata_xmltoyaml.ado", "unicefdata_xmltoyaml_py.ado")

Write-Host "Syncing main command files..." -ForegroundColor Yellow
$count = 0
foreach ($file in $cmd_files) {
    $src = Join-Path $ado_src "u" $file
    if (Test-Path $src) {
        Copy-Item -Path $src -Destination (Join-Path $repo_dst "u" $file) -Force -EA SilentlyContinue
        Copy-Item -Path $src -Destination (Join-Path $dev_dst "u" $file) -Force -EA SilentlyContinue
        Write-Host "  ✓ $file"
        $count++
    }
}
Write-Host "  Synced: $count files`n"

Write-Host "✓ SYNC COMPLETE - Repositories aligned with Stata ado path" -ForegroundColor Green
