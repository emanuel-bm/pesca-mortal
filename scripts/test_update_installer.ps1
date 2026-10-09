$ErrorActionPreference = 'Stop'
$projectDirectory = Split-Path -Parent $PSScriptRoot
$testDirectory = Join-Path $projectDirectory ('.tools/atualização-test-' + [Guid]::NewGuid().ToString('N'))
$null = New-Item -ItemType Directory -Path $testDirectory
$sourceDirectory = Join-Path $testDirectory 'source'
$null = New-Item -ItemType Directory -Path $sourceDirectory
$targetPath = Join-Path $testDirectory 'Pesca Mortal.exe'
$newPath = Join-Path $sourceDirectory 'Pesca Mortal.exe'
# A harmless executable that records when it was launched, then exits.
$source = @'
using System;
using System.IO;
public class UpdateFixture {
 public static void Main(string[] args) {
  string exe = System.Reflection.Assembly.GetExecutingAssembly().Location;
  File.WriteAllText(Path.Combine(Path.GetDirectoryName(exe), "launched.txt"), String.Join(" ", args));
 }
}
'@
Add-Type -TypeDefinition $source -OutputAssembly $newPath -OutputType ConsoleApplication
[IO.File]::WriteAllText($targetPath, 'old installation')
Add-Type -AssemblyName System.IO.Compression.FileSystem
$zipPath = Join-Path $testDirectory 'update.zip'
[IO.Compression.ZipFile]::CreateFromDirectory($sourceDirectory, $zipPath)
$parametersPath = Join-Path $testDirectory 'parameters.json'
$settings = @{ pid = 2147483647; archive = $zipPath; target = $targetPath; entry = 'Pesca Mortal.exe'; sha256 = (Get-FileHash -LiteralPath $zipPath -Algorithm SHA256).Hash }
$settings | ConvertTo-Json | Set-Content -LiteralPath $parametersPath -Encoding UTF8
$installer = Join-Path $PSScriptRoot 'install_update.ps1'
& $installer -ParametersPath $parametersPath
$marker = Join-Path $testDirectory 'launched.txt'
for ($attempt = 0; $attempt -lt 40 -and -not (Test-Path -LiteralPath $marker); $attempt++) { Start-Sleep -Milliseconds 100 }
if (-not (Test-Path -LiteralPath $marker)) { throw 'Updated executable was not launched' }
if ((Get-FileHash -LiteralPath $targetPath).Hash -ne (Get-FileHash -LiteralPath $newPath).Hash) { throw 'Replacement differs from release executable' }
if ((Get-Content -LiteralPath $marker -Raw).Length -gt 0) { throw 'Unexpected launch failure' }
Remove-Item -LiteralPath $marker
$settings.sha256 = '0' * 64
$settings | ConvertTo-Json | Set-Content -LiteralPath $parametersPath -Encoding UTF8
& $installer -ParametersPath $parametersPath
for ($attempt = 0; $attempt -lt 40 -and -not (Test-Path -LiteralPath $marker); $attempt++) { Start-Sleep -Milliseconds 100 }
if (-not (Test-Path -LiteralPath $marker)) { throw 'Original executable was not relaunched after checksum failure' }
if ((Get-Content -LiteralPath $marker -Raw) -notmatch '--update-install-failed') { throw 'Failure state was not passed to the original executable' }
if ((Get-FileHash -LiteralPath $targetPath).Hash -ne (Get-FileHash -LiteralPath $newPath).Hash) { throw 'Original executable was changed after checksum failure' }
Remove-Item -LiteralPath $marker
$settings.sha256 = (Get-FileHash -LiteralPath $zipPath -Algorithm SHA256).Hash
$settings.entry = 'missing.exe'
$settings | ConvertTo-Json | Set-Content -LiteralPath $parametersPath -Encoding UTF8
& $installer -ParametersPath $parametersPath
for ($attempt = 0; $attempt -lt 40 -and -not (Test-Path -LiteralPath $marker); $attempt++) { Start-Sleep -Milliseconds 100 }
if (-not (Test-Path -LiteralPath $marker)) { throw 'Original executable was not relaunched after missing entry' }
if ((Get-Content -LiteralPath $marker -Raw) -notmatch '--update-install-failed') { throw 'Missing entry did not produce failure state' }
Remove-Item -LiteralPath $marker
# Force a launch failure after replacement to exercise backup restoration.
$previousHash = (Get-FileHash -LiteralPath $targetPath).Hash
[IO.File]::WriteAllBytes($newPath, [byte[]](77, 90, 0, 0))
$brokenZipPath = Join-Path $testDirectory 'broken.zip'
[IO.Compression.ZipFile]::CreateFromDirectory($sourceDirectory, $brokenZipPath)
$settings.entry = 'Pesca Mortal.exe'
$settings.archive = $brokenZipPath
$settings.sha256 = (Get-FileHash -LiteralPath $brokenZipPath -Algorithm SHA256).Hash
$settings | ConvertTo-Json | Set-Content -LiteralPath $parametersPath -Encoding UTF8
& $installer -ParametersPath $parametersPath
for ($attempt = 0; $attempt -lt 40 -and -not (Test-Path -LiteralPath $marker); $attempt++) { Start-Sleep -Milliseconds 100 }
if (-not (Test-Path -LiteralPath $marker)) { throw 'Backup was not relaunched after replacement failed' }
if ((Get-FileHash -LiteralPath $targetPath).Hash -ne $previousHash) { throw 'Backup was not restored' }
Remove-Item -LiteralPath $marker
# Direct EXE input must install without archive extraction.
Copy-Item -LiteralPath $targetPath -Destination $newPath -Force
$settings.format = 'exe'
$settings.archive = $newPath
$settings.sha256 = (Get-FileHash -LiteralPath $newPath -Algorithm SHA256).Hash
$settings | ConvertTo-Json | Set-Content -LiteralPath $parametersPath -Encoding UTF8
& $installer -ParametersPath $parametersPath
for ($attempt = 0; $attempt -lt 40 -and -not (Test-Path -LiteralPath $marker); $attempt++) { Start-Sleep -Milliseconds 100 }
if (-not (Test-Path -LiteralPath $marker)) { throw 'Direct executable was not relaunched' }
if ((Get-Content -LiteralPath $marker -Raw).Length -gt 0) { throw 'Direct executable install failed' }
if ((Get-FileHash -LiteralPath $targetPath).Hash -ne $settings.sha256) { throw 'Direct executable differs from downloaded file' }
Remove-Item -LiteralPath $marker
$settings.sha256 = '0' * 64
$settings | ConvertTo-Json | Set-Content -LiteralPath $parametersPath -Encoding UTF8
& $installer -ParametersPath $parametersPath
for ($attempt = 0; $attempt -lt 40 -and -not (Test-Path -LiteralPath $marker); $attempt++) { Start-Sleep -Milliseconds 100 }
if (-not (Test-Path -LiteralPath $marker) -or (Get-Content -LiteralPath $marker -Raw) -notmatch '--update-install-failed') { throw 'Direct executable checksum failure was not recovered' }
Write-Output 'Installer checks passed: EXE and ZIP replacement, restart, checksum failures and rollback.'
