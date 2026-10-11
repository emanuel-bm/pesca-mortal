# Refresh the bundled offline history after publishing a GitHub release.
param([switch]$IncludeCurrentVersion)
$ErrorActionPreference = 'Stop'
$projectDirectory = Split-Path -Parent $PSScriptRoot
$config = Get-Content -LiteralPath (Join-Path $projectDirectory 'updates.cfg') -Raw
$repository = [regex]::Match($config, 'repository="([A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+)"').Groups[1].Value
if (-not $repository) { throw 'Configure repository in updates.cfg' }
$all = @()
$page = 1
do {
    $response = Invoke-RestMethod -Uri "https://api.github.com/repos/$repository/releases?per_page=100&page=$page" -Headers @{ 'User-Agent' = 'Pesca-Mortal'; Accept = 'application/vnd.github+json' }
    $batch = @($response | ForEach-Object { $_ })
    $all += $batch
    $page++
} while ($batch.Count -eq 100)
$entries = @($all | Where-Object { -not $_.draft -and -not $_.prerelease -and $_.tag_name -match '^v?\d+\.\d+\.\d+$' } | Sort-Object published_at -Descending | Select-Object tag_name,name,body,published_at)
if (-not $entries.Count) { throw 'No published stable release found; offline snapshot was preserved' }
if ($IncludeCurrentVersion) {
    $projectText = Get-Content -LiteralPath (Join-Path $projectDirectory 'project.godot') -Raw
    $version = [regex]::Match($projectText, 'config/version="([^"]+)"').Groups[1].Value
    if ($version -notmatch '^\d+\.\d+\.\d+$') { throw 'Invalid game version' }
    if (-not ($entries | Where-Object { $_.tag_name -eq "v$version" -or $_.tag_name -eq $version })) {
        $notesPath = Join-Path $projectDirectory "docs/releases/$version.md"
        $body = Get-Content -LiteralPath $notesPath -Raw -Encoding UTF8
        if (-not $body.Trim()) { throw 'Write release notes before preparing the build' }
        $firstLine = ($body -split '\r?\n')[0].Trim()
        $heading = if ($firstLine.StartsWith('# ')) { $firstLine.TrimStart('#').Trim() } else { "Pesca Mortal $version" }
        $entries = @([pscustomobject]@{ tag_name = "v$version"; name = $heading; body = $body; published_at = [DateTime]::UtcNow.ToString('yyyy-MM-ddTHH:mm:ssZ') }) + $entries
    }
}
$json = ConvertTo-Json -InputObject $entries -Depth 5
[IO.File]::WriteAllText((Join-Path $projectDirectory 'assets/release_notes.json'), $json, [Text.UTF8Encoding]::new($false))
Write-Output "Offline history refreshed: $($entries.Count) releases"
