param([Parameter(Mandatory=$true)][string]$ParametersPath)
$ErrorActionPreference = 'Stop'
$settings = Get-Content -LiteralPath $ParametersPath -Raw | ConvertFrom-Json
$targetPath = [IO.Path]::GetFullPath([string]$settings.target)
$targetDirectory = [IO.Path]::GetDirectoryName($targetPath)
$taskId = [Guid]::NewGuid().ToString('N')
$stagedPath = Join-Path $targetDirectory ('.pesca-update-' + $taskId + '.exe')
$backupPath = Join-Path $targetDirectory ('.pesca-backup-' + $taskId + '.exe')
$archive = $null
$backedUp = $false
$installed = $false
try {
    if ([IO.Path]::GetFileName([string]$settings.entry) -ne [string]$settings.entry -or -not ([string]$settings.entry).EndsWith('.exe')) { throw 'Invalid executable name' }
    if ((Get-FileHash -LiteralPath $settings.archive -Algorithm SHA256).Hash -ne [string]$settings.sha256) { throw 'Checksum mismatch' }
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    $archive = [IO.Compression.ZipFile]::OpenRead([string]$settings.archive)
    # Release archives contain one executable with an embedded PCK, at the root.
    $entry = $archive.GetEntry([string]$settings.entry)
    if ($null -eq $entry -or $entry.Length -lt 2 -or $entry.Length -gt 1GB) { throw 'Executable missing or invalid' }
    [IO.Compression.ZipFileExtensions]::ExtractToFile($entry, $stagedPath, $false)
    $archive.Dispose()
    $archive = $null
    $stream = [IO.File]::OpenRead($stagedPath)
    try {
        if ($stream.ReadByte() -ne 77 -or $stream.ReadByte() -ne 90) { throw 'Invalid Windows executable' }
    } finally { $stream.Dispose() }
    $gameProcess = Get-Process -Id ([int]$settings.pid) -ErrorAction SilentlyContinue
    if ($null -ne $gameProcess -and -not $gameProcess.WaitForExit(60000)) { throw 'Game did not close' }
    # Antivirus scanners may briefly keep the executable locked.
    for ($attempt = 0; $attempt -lt 20; $attempt++) {
        try {
            Move-Item -LiteralPath $targetPath -Destination $backupPath
            $backedUp = $true
            break
        } catch {
            if ($attempt -eq 19) { throw }
            Start-Sleep -Milliseconds 500
        }
    }
    Move-Item -LiteralPath $stagedPath -Destination $targetPath
    $installed = $true
    Start-Process -FilePath $targetPath -WorkingDirectory $targetDirectory -WindowStyle Hidden
    Remove-Item -LiteralPath $backupPath -ErrorAction SilentlyContinue
} catch {
    $_ | Out-String | Set-Content -LiteralPath (Join-Path ([IO.Path]::GetDirectoryName($ParametersPath)) 'update-error.log')
    if ($backedUp -and (Test-Path -LiteralPath $backupPath)) {
        if ($installed -and (Test-Path -LiteralPath $targetPath)) { Remove-Item -LiteralPath $targetPath }
        Move-Item -LiteralPath $backupPath -Destination $targetPath
    }
    $gameProcess = Get-Process -Id ([int]$settings.pid) -ErrorAction SilentlyContinue
    if ($null -ne $gameProcess) { $null = $gameProcess.WaitForExit(60000) }
    if ($null -eq (Get-Process -Id ([int]$settings.pid) -ErrorAction SilentlyContinue)) {
        Start-Process -FilePath $targetPath -ArgumentList '--', '--update-install-failed' -WorkingDirectory $targetDirectory -WindowStyle Hidden
    }
} finally {
    if ($null -ne $archive) { $archive.Dispose() }
    if (Test-Path -LiteralPath $stagedPath) { Remove-Item -LiteralPath $stagedPath -ErrorAction SilentlyContinue }
}
