param([string]$Version = '', [switch]$LegacyZip)
$ErrorActionPreference = 'Stop'
$projectDirectory = Split-Path -Parent $PSScriptRoot
$projectFile = Join-Path $projectDirectory 'project.godot'
$configuredVersion = [regex]::Match((Get-Content -LiteralPath $projectFile -Raw), 'config/version="([^"]+)"').Groups[1].Value
if ($Version -and $Version -ne $configuredVersion) { throw 'Version must match application/config/version in project.godot' }
if ($configuredVersion -notmatch '^\d+\.\d+\.\d+$') { throw 'Use a version such as 1.0.1' }
$outputDirectory = Join-Path $projectDirectory 'dist'
$null = New-Item -ItemType Directory -Path $outputDirectory -Force
$engine = Join-Path $projectDirectory '.tools/godot/Godot_v4.7.2-stable_win64_console.exe'
$executable = Join-Path $outputDirectory ("pesca-mortal-windows-v$configuredVersion.exe")
& $engine --headless --path $projectDirectory --export-release 'Windows Portable' $executable
if ($LASTEXITCODE -ne 0) { throw 'Windows export failed' }
Write-Output "Version: v$configuredVersion"
Write-Output "Release asset: $executable"
Get-FileHash -LiteralPath $executable -Algorithm SHA256
if ($LegacyZip) {
    # Optional bridge for installed 0.1.2 clients that still request this ZIP.
    $legacyDirectory = Join-Path $outputDirectory 'compatibilidade'
    $null = New-Item -ItemType Directory -Path $legacyDirectory -Force
    $legacyExecutable = Join-Path $legacyDirectory 'Pesca Mortal.exe'
    Copy-Item -LiteralPath $executable -Destination $legacyExecutable -Force
    $archive = Join-Path $outputDirectory 'Pesca-Mortal-Windows.zip'
    Compress-Archive -LiteralPath $legacyExecutable -DestinationPath $archive -Force
    Write-Output "Optional compatibility asset: $archive"
    Get-FileHash -LiteralPath $archive -Algorithm SHA256
}
