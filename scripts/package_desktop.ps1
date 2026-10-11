param(
    [ValidateSet('Windows', 'macOS', 'Linux')]
    [string[]]$Platforms = @('Windows', 'macOS', 'Linux'),
    [switch]$LegacyWindowsZip,
    [string[]]$WindowsBaseExecutables = @()
)
$ErrorActionPreference = 'Stop'
$projectDirectory = Split-Path -Parent $PSScriptRoot
$engine = Join-Path $projectDirectory '.tools/godot/Godot_v4.7.2-stable_win64_console.exe'
$outputDirectory = Join-Path $projectDirectory 'dist'
$null = New-Item -ItemType Directory -Path $outputDirectory -Force
$projectText = Get-Content -LiteralPath (Join-Path $projectDirectory 'project.godot') -Raw
$configuredVersion = [regex]::Match($projectText, 'config/version="([^"]+)"').Groups[1].Value
if ($configuredVersion -notmatch '^\d+\.\d+\.\d+$') { throw 'Use a version such as 0.1.3' }

if ($Platforms -contains 'Windows') {
    $windowsParameters = @{ LegacyZip = $LegacyWindowsZip }
    if ($PSBoundParameters.ContainsKey('WindowsBaseExecutables')) { $windowsParameters.BaseExecutables = $WindowsBaseExecutables }
    & (Join-Path $PSScriptRoot 'package_windows.ps1') @windowsParameters
}
$exports = @(
    @{ Platform = 'macOS'; Preset = 'macOS Apple Silicon'; File = "pesca-mortal-macos-arm64-v$configuredVersion.zip" },
    @{ Platform = 'Linux'; Preset = 'Linux Portable'; File = "pesca-mortal-linux-v$configuredVersion.x86_64" }
)
foreach ($export in $exports) {
    if ($Platforms -notcontains $export.Platform) { continue }
    $artifact = Join-Path $outputDirectory $export.File
    & $engine --headless --path $projectDirectory --export-release $export.Preset $artifact
    if ($LASTEXITCODE -ne 0) { throw ($export.Platform + ' export failed') }
    Write-Output ('Release asset: ' + $artifact)
    Get-FileHash -LiteralPath $artifact -Algorithm SHA256
}
Write-Output 'Arquivos gerados localmente. Nenhum commit, push ou release foi realizado.'
