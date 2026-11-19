[CmdletBinding()]
param([string]$ProjectRoot = (Split-Path -Parent $PSScriptRoot))

# Run after the failed build has stopped. Preserve generated files rather than
# recursively deleting a OneDrive directory which may still be held open.
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$projectPath = (Resolve-Path -LiteralPath $ProjectRoot).Path.TrimEnd('\')
if ((Get-Content -LiteralPath (Join-Path $projectPath 'pubspec.yaml') -Raw) -notmatch '(?m)^name:\s*cit_app\s*$') {
    throw 'ProjectRoot must be the CIT_App Flutter project.'
}
$cachePath = [IO.Path]::GetFullPath((Join-Path $projectPath 'build\app\intermediates\assets\debug\mergeDebugAssets'))
$backupPath = [IO.Path]::GetFullPath(($cachePath + '.recovery-' + (Get-Date -Format 'yyyyMMdd-HHmmss-fff')))
foreach ($targetPath in @($cachePath, $backupPath)) {
    if (-not $targetPath.StartsWith($projectPath + '\', [StringComparison]::OrdinalIgnoreCase)) {
        throw 'Generated cache path is outside the project.'
    }
}
# Cloud placeholders have ReparsePoint but no LinkType. Reject directory links
# at every ancestor rather than following them outside the verified project.
$ancestorPath = $cachePath
while ($ancestorPath.Length -gt $projectPath.Length) {
    $ancestor = Get-Item -LiteralPath $ancestorPath -Force -ErrorAction SilentlyContinue
    if ($null -ne $ancestor -and -not [string]::IsNullOrEmpty($ancestor.LinkType)) {
        throw "Unexpected directory link at $ancestorPath; left unchanged."
    }
    $ancestorPath = Split-Path -Parent $ancestorPath
}
$existing = Get-Item -LiteralPath $cachePath -Force -ErrorAction SilentlyContinue
if ($null -ne $existing) {
    if (-not $existing.PSIsContainer) { throw 'Expected a generated cache directory.' }
    if (@(Get-ChildItem -LiteralPath $cachePath -Force).Count -gt 0 -or
        ($existing.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0) {
        Rename-Item -LiteralPath $cachePath -NewName (Split-Path -Leaf $backupPath)
        Write-Output "Preserved generated assets at $backupPath"
    }
}
New-Item -ItemType Directory -Path $cachePath -Force | Out-Null
Write-Output 'Android debug asset cache is ready. Run the app again in Android Studio.'
