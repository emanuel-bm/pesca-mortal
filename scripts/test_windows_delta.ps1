$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'windows_delta.ps1')
$folder = Join-Path (Split-Path -Parent $PSScriptRoot) ('.tools/delta-test-' + [Guid]::NewGuid().ToString('N'))
$null = New-Item -ItemType Directory -Path $folder
$basis = Join-Path $folder 'old.exe'
$target = Join-Path $folder 'new.exe'
$patch = Join-Path $folder 'update.patch.gz'
$restored = Join-Path $folder 'restored.exe'
$bytes = New-Object byte[] 1048576
$random = New-Object Random 42
$random.NextBytes($bytes)
[IO.File]::WriteAllBytes($basis, $bytes)
$bytes[20000] = $bytes[20000] -bxor 255
[IO.File]::WriteAllBytes($target, $bytes)
[MortalDelta]::Create($basis, $target, $patch)
[MortalDelta]::Apply($basis, $patch, $restored)
if ((Get-FileHash $target).Hash -ne (Get-FileHash $restored).Hash) { throw 'Reconstruction differs' }
if ((Get-Item $patch).Length -ge 32768) { throw 'Small change downloads too much' }
$rejected = $false
try { [MortalDelta]::Apply($target, $patch, $restored) } catch { $rejected = $true }
if (-not $rejected) { throw 'Wrong base accepted' }
$corrupt = [IO.File]::ReadAllBytes($patch)
[IO.File]::WriteAllBytes($patch, $corrupt[0..100])
$rejected = $false
try { [MortalDelta]::Apply($basis, $patch, $restored) } catch { $rejected = $true }
if (-not $rejected) { throw 'Truncated patch accepted' }
Write-Output 'DELTA PASS: exact reconstruction, small download, wrong base and truncation rejected'
