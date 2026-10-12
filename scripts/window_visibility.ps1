param([long]$WindowHandle, [string]$StatusPath, [switch]$LibraryOnly)
$ErrorActionPreference = 'Stop'
Add-Type -TypeDefinition @'
using System;
using System.Runtime.InteropServices;
public static class GameWindowVisibility {
 [StructLayout(LayoutKind.Sequential)] public struct Rect { public int Left, Top, Right, Bottom; }
 [StructLayout(LayoutKind.Sequential)] public struct Point { public int X, Y; }
 delegate bool EnumProc(IntPtr window, IntPtr data);
 [DllImport("user32.dll", EntryPoint="GetWindowLongW")] static extern int GetWindowLong(IntPtr window, int index);
 [DllImport("user32.dll")] static extern bool EnumWindows(EnumProc callback, IntPtr data);
 [DllImport("user32.dll")] public static extern bool IsWindow(IntPtr window);
 [DllImport("user32.dll")] static extern bool IsWindowVisible(IntPtr window);
 [DllImport("user32.dll")] static extern bool IsIconic(IntPtr window);
 [DllImport("user32.dll")] static extern bool GetWindowRect(IntPtr window, out Rect rect);
 [DllImport("user32.dll")] static extern bool GetClientRect(IntPtr window, out Rect rect);
 [DllImport("user32.dll")] static extern bool ClientToScreen(IntPtr window, ref Point point);
 [DllImport("user32.dll")] static extern uint GetWindowThreadProcessId(IntPtr window, out uint process);
 [DllImport("user32.dll")] static extern IntPtr GetForegroundWindow();
 [DllImport("dwmapi.dll")] static extern int DwmGetWindowAttribute(IntPtr window, int attribute, out int value, int size);
 [DllImport("dwmapi.dll", EntryPoint="DwmGetWindowAttribute")] static extern int FrameBounds(IntPtr window, int attribute, out Rect rect, int size);
 public static bool Blocked(IntPtr game) {
  if (!IsWindowVisible(game) || IsIconic(game)) return true;
  uint gameProcess; GetWindowThreadProcessId(game, out gameProcess);
  uint foregroundProcess; GetWindowThreadProcessId(GetForegroundWindow(), out foregroundProcess);
  if (foregroundProcess != gameProcess) return true;
  Rect area; if (!GetClientRect(game, out area)) return false;
  Point origin = new Point(); if (!ClientToScreen(game, ref origin)) return false;
  area.Left += origin.X; area.Right += origin.X; area.Top += origin.Y; area.Bottom += origin.Y;
  bool blocked = false;
  // EnumWindows visits top-level windows from front to back. Stop at the game.
  EnumWindows(delegate(IntPtr window, IntPtr unused) {
   if (window == game) return false;
   uint process; GetWindowThreadProcessId(window, out process);
   if (process == gameProcess || !IsWindowVisible(window) || IsIconic(window)) return true;
   // Driver/HUD utility overlays pass clicks through and cannot take focus.
   // AMD's fullscreen DVR overlay has these flags even when its UI is hidden.
   const int passiveOverlay = 0x08000020; // WS_EX_NOACTIVATE | WS_EX_TRANSPARENT
   if ((GetWindowLong(window, -20) & passiveOverlay) == passiveOverlay) return true;
   int cloaked; if (DwmGetWindowAttribute(window, 14, out cloaked, 4) == 0 && cloaked != 0) return true;
   Rect bounds;
   if (FrameBounds(window, 9, out bounds, 16) != 0 && !GetWindowRect(window, out bounds)) return true;
   if (bounds.Right > bounds.Left && bounds.Bottom > bounds.Top &&
       bounds.Left < area.Right && bounds.Right > area.Left && bounds.Top < area.Bottom && bounds.Bottom > area.Top) {
    blocked = true; return false;
   }
   return true;
  }, IntPtr.Zero);
  return blocked;
 }
}
'@
if ($LibraryOnly) { return }
$gameWindow = [IntPtr]$WindowHandle
try {
 while ([GameWindowVisibility]::IsWindow($gameWindow)) {
  $value = if ([GameWindowVisibility]::Blocked($gameWindow)) { '1' } else { '0' }
  # A single byte, read with sharing by the game; never block the render thread.
  $stream = [IO.File]::Open($StatusPath, [IO.FileMode]::Create, [IO.FileAccess]::Write, [IO.FileShare]::ReadWrite)
  try { $stream.WriteByte([byte][char]$value) } finally { $stream.Dispose() }
  Start-Sleep -Milliseconds 150
 }
} finally {
 Remove-Item -LiteralPath $StatusPath -ErrorAction SilentlyContinue
}
