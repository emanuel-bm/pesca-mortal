param([string]$Version = '')
$ErrorActionPreference = 'Stop'
$projectDirectory = Split-Path -Parent $PSScriptRoot
$projectFile = Join-Path $projectDirectory 'project.godot'
$configuredVersion = [regex]::Match((Get-Content -LiteralPath $projectFile -Raw), 'config/version="([^"]+)"').Groups[1].Value
if ($Version -and $Version -ne $configuredVersion) { throw 'Version must match application/config/version in project.godot' }
if ($configuredVersion -notmatch '^\d+\.\d+\.\d+$') { throw 'Use a version such as 1.0.1' }
$outputDirectory = Join-Path $projectDirectory 'dist/Pesca-Mortal-Windows'
$null = New-Item -ItemType Directory -Path $outputDirectory -Force
$engine = Join-Path $projectDirectory '.tools/godot/Godot_v4.7.2-stable_win64_console.exe'
$executable = Join-Path $outputDirectory 'Pesca Mortal.exe'
& $engine --headless --path $projectDirectory --export-release 'Windows Portable' $executable
if ($LASTEXITCODE -ne 0) { throw 'Windows export failed' }
$archive = Join-Path $projectDirectory 'dist/Pesca-Mortal-Windows.zip'
# Keep the executable at the ZIP root, as expected by the integrated installer.
Compress-Archive -LiteralPath $executable -DestinationPath $archive -Force
Write-Output "Version: v$configuredVersion"
Write-Output "Release asset: $archive"
Get-FileHash -LiteralPath $archive -Algorithm SHA256
