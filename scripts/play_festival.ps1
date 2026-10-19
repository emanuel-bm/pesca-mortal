$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
$engineName = 'Godot_v4.7.2-stable_win64.exe'
$enginePath = Join-Path $projectRoot ".tools/godot/$engineName"
if (-not (Test-Path -LiteralPath $enginePath)) {
    # Managed worktrees share the main checkout's ignored portable engine.
    $commonGitDirectory = & git -C $projectRoot rev-parse --path-format=absolute --git-common-dir
    if ($LASTEXITCODE -eq 0) {
        $mainCheckout = Split-Path -Parent $commonGitDirectory
        $enginePath = Join-Path $mainCheckout ".tools/godot/$engineName"
    }
}
if (-not (Test-Path -LiteralPath $enginePath)) {
    throw 'Godot portatil nao encontrado. Instale a engine em .tools/godot.'
}
Start-Process -FilePath $enginePath -ArgumentList @('--path', ('"' + $projectRoot + '"'), '--', '--festival')
