param([string]$Version = '', [switch]$LegacyZip, [string[]]$BaseExecutables = @())
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
if (-not $PSBoundParameters.ContainsKey('BaseExecutables')) {
    # Normal release command also produces patches for the two latest archived builds.
    $BaseExecutables = @(Get-ChildItem -LiteralPath $outputDirectory -Filter 'pesca-mortal-windows-v*.exe' |
        Where-Object { $_.Name -match '^pesca-mortal-windows-v(\d+\.\d+\.\d+)\.exe$' -and [version]$Matches[1] -lt [version]$configuredVersion } |
        Sort-Object { [version]([regex]::Match($_.Name, 'v(\d+\.\d+\.\d+)').Groups[1].Value) } -Descending |
        Select-Object -First 2 -ExpandProperty FullName)
}
foreach ($basis in $BaseExecutables) {
    if ((Get-Item -LiteralPath $basis).FullName -eq $executable) { throw 'Patch base must be a previous build; increment the game version first' }
}
& $engine --headless --path $projectDirectory --export-release 'Windows Portable' $executable
if ($LASTEXITCODE -ne 0) { throw 'Windows export failed' }
Write-Output "Version: v$configuredVersion"
Write-Output "Release asset: $executable"
Get-FileHash -LiteralPath $executable -Algorithm SHA256
if ($BaseExecutables.Count) {
    . (Join-Path $PSScriptRoot 'windows_delta.ps1')
    foreach ($basis in $BaseExecutables) {
        $baseFile = Get-Item -LiteralPath $basis
        if ($baseFile.FullName -eq $executable) { throw 'Patch base must be a previous build' }
        $baseHash = (Get-FileHash -LiteralPath $basis -Algorithm SHA256).Hash.ToLowerInvariant()
        $patch = Join-Path $outputDirectory ("pesca-mortal-windows-$baseHash-v$configuredVersion.patch.gz")
        [MortalDelta]::Create($baseFile.FullName, $executable, $patch)
        if ((Get-Item -LiteralPath $patch).Length -lt (Get-Item -LiteralPath $executable).Length) {
            Write-Output "Patch asset: $patch"
            Get-FileHash -LiteralPath $patch -Algorithm SHA256
        } else {
            Remove-Item -LiteralPath $patch
            Write-Output 'Patch is larger than full executable; use full download for this base.'
        }
    }
}
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
