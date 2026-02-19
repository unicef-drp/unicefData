# PowerShell script to automate the creation of the unicefdata zip package

# Define paths
$pkgFile = "c:\GitHub\myados\unicefData-dev\stata\ssc\unicefdata.pkg"
$srcFolder = "c:\GitHub\myados\unicefData-dev\stata\src"
$zipFolder = "c:\GitHub\myados\unicefData-dev\stata\ssc"
$tempFolder = "$zipFolder\temp_unzip"
$zipFile = "$zipFolder\unicefData_220.zip"

# Ensure temp folder exists
if (Test-Path $tempFolder) {
    Remove-Item -Recurse -Force $tempFolder
}
New-Item -ItemType Directory -Path $tempFolder

# Read files from pkg
$files = Get-Content $pkgFile | Where-Object { $_ -match '^f ' } | ForEach-Object { ($_ -split ' ')[1] }

# Copy files to temp folder preserving subdirectory structure
foreach ($file in $files) {
    # Remove 'src/' prefix if present since srcFolder already points to src/
    $relativePath = $file -replace '^src/', ''
    $sourcePath = Join-Path -Path $srcFolder -ChildPath $relativePath
    $destPath = Join-Path -Path $tempFolder -ChildPath $relativePath
    if (Test-Path $sourcePath) {
        $destDir = Split-Path -Parent $destPath
        if (-not (Test-Path $destDir)) {
            New-Item -ItemType Directory -Path $destDir -Force | Out-Null
        }
        Copy-Item -Path $sourcePath -Destination $destPath -Force
    } else {
        Write-Host "Warning: File not found - $sourcePath"
    }
}

# Recreate the zip file
if (Test-Path $zipFile) {
    Remove-Item -Force $zipFile
}
Compress-Archive -Path "$tempFolder\*" -DestinationPath $zipFile -Force

# Cleanup
Remove-Item -Recurse -Force $tempFolder

Write-Host "Zip package created: $zipFile"