$ErrorActionPreference = 'Stop'
. "$PSScriptRoot/window_visibility.ps1" -LibraryOnly
Add-Type -AssemblyName System.Windows.Forms
Add-Type @'
using System;
using System.Runtime.InteropServices;
public static class VisibilityTestNative {
 [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr window);
 [DllImport("user32.dll")] public static extern IntPtr GetForegroundWindow();
}
'@
$testDirectory = Join-Path ([IO.Path]::GetTempPath()) ([Guid]::NewGuid().ToString())
[IO.Directory]::CreateDirectory($testDirectory) | Out-Null
$overlayScript = Join-Path $testDirectory 'overlay.ps1'
$readyPath = Join-Path $testDirectory 'ready'
$commandPath = Join-Path $testDirectory 'command'
$overlaySource = @'
param($Directory)
Add-Type -AssemblyName System.Windows.Forms
Add-Type -ReferencedAssemblies System.Windows.Forms @"
using System.Windows.Forms;
public class NoFocusOverlay : Form {
 protected override bool ShowWithoutActivation { get { return true; } }
 protected override CreateParams CreateParams { get { var p = base.CreateParams; p.ExStyle |= 0x08000000; return p; } }
}
"@
$form = New-Object NoFocusOverlay
$form.StartPosition = 'Manual'
$form.Location = New-Object Drawing.Point(150, 150)
$form.Size = New-Object Drawing.Size(220, 180)
$form.TopMost = $true
$form.Text = 'Visibility regression test'
$form.Show()
try {
 while ($true) {
  [Windows.Forms.Application]::DoEvents()
  $command = Get-Content (Join-Path $Directory 'command') -ErrorAction SilentlyContinue
  if ($command -eq 'outside') { $form.Location = New-Object Drawing.Point(750, 150) }
  if ($command -eq 'hidden') { $form.Hide() }
  if ($command -eq 'behind') {
   $form.Location = New-Object Drawing.Point(150, 150)
   $form.TopMost = $false
   $form.SendToBack()
  }
  [IO.File]::WriteAllText((Join-Path $Directory 'ready'), [string]$command)
  Start-Sleep -Milliseconds 30
 }
} finally { $form.Dispose() }
'@
[IO.File]::WriteAllText($overlayScript, $overlaySource)
$game = New-Object Windows.Forms.Form
$game.StartPosition = 'Manual'
$game.Location = New-Object Drawing.Point(100, 100)
$game.Size = New-Object Drawing.Size(500, 400)
$game.Text = 'Game visibility test'
$overlayProcess = $null
$monitorProcess = $null
$statusPath = Join-Path $testDirectory 'status'
function Check($condition, $message) { if (-not $condition) { throw $message } }
function Await-Command($command) {
 [IO.File]::WriteAllText($commandPath, $command)
 $deadline = [DateTime]::UtcNow.AddSeconds(15)
 do {
  [Windows.Forms.Application]::DoEvents()
  Start-Sleep -Milliseconds 50
  $ready = Get-Content $readyPath -ErrorAction SilentlyContinue
 } until ($ready -eq $command -or [DateTime]::UtcNow -gt $deadline)
 Check ($ready -eq $command) 'Overlay helper did not respond'
}
function Await-Status($value) {
 $deadline = [DateTime]::UtcNow.AddSeconds(15)
 do {
  [Windows.Forms.Application]::DoEvents()
  Start-Sleep -Milliseconds 50
  $status = Get-Content $statusPath -ErrorAction SilentlyContinue
 } until ($status -eq $value -or [DateTime]::UtcNow -gt $deadline)
 Check ($status -eq $value) 'Monitor did not publish expected visibility'
}
try {
 $game.Show()
 [VisibilityTestNative]::SetForegroundWindow($game.Handle) | Out-Null
 [Windows.Forms.Application]::DoEvents()
 Check (-not [GameWindowVisibility]::Blocked($game.Handle)) 'Uncovered focused game must run'
 $monitorProcess = Start-Process powershell.exe -WindowStyle Hidden -PassThru -ArgumentList @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', ('"' + "$PSScriptRoot/window_visibility.ps1" + '"'), '-WindowHandle', $game.Handle.ToInt64(), '-StatusPath', ('"' + $statusPath + '"'))
 Await-Status '0'
 [IO.File]::WriteAllText($commandPath, 'overlap')
 $overlayProcess = Start-Process powershell.exe -WindowStyle Hidden -PassThru -ArgumentList @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', ('"' + $overlayScript + '"'), ('"' + $testDirectory + '"'))
 Await-Command 'overlap'
 Check ([VisibilityTestNative]::GetForegroundWindow() -eq $game.Handle) 'Overlay must preserve game focus to reproduce the bug'
 Check ([GameWindowVisibility]::Blocked($game.Handle)) 'External overlay without focus loss must be detected'
 Await-Status '1'
 Await-Command 'outside'
 Check (-not [GameWindowVisibility]::Blocked($game.Handle)) 'Non-overlapping external window must not pause the game'
 Await-Status '0'
 Await-Command 'behind'
 Check (-not [GameWindowVisibility]::Blocked($game.Handle)) 'Overlapping window behind the game must not pause it'
 Await-Status '0'
 Await-Command 'hidden'
 Check (-not [GameWindowVisibility]::Blocked($game.Handle)) 'Hidden external window must not pause the game'
 Write-Output 'WINDOW VISIBILITY PASS: external overlap with game still focused; outside and hidden windows ignored.'
} finally {
 if ($overlayProcess -and -not $overlayProcess.HasExited) { Stop-Process -Id $overlayProcess.Id }
 if ($monitorProcess -and -not $monitorProcess.HasExited) { Stop-Process -Id $monitorProcess.Id }
 $game.Dispose()
 # Only the explicitly created, resolved temporary directory is removed.
 $resolvedTestDirectory = [IO.Path]::GetFullPath($testDirectory)
 if ([IO.Path]::GetDirectoryName($resolvedTestDirectory) -eq [IO.Path]::GetTempPath().TrimEnd('\')) {
  Remove-Item -LiteralPath $resolvedTestDirectory -Recurse -Force
 }
}
