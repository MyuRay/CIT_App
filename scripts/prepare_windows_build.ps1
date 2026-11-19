[CmdletBinding()]
param(
    [string]$ProjectRoot = (Split-Path -Parent $PSScriptRoot),
    # Used only to recognize junctions created by the previous setup script.
    [string]$CacheRoot = (Join-Path $env:LOCALAPPDATA 'CIT_App\build-cache')
)

# Keep build paths visible to both Android Studio and packaged desktop tools.
# AppData may be virtualized per application; generated directories must not
# point there through junctions. Existing caches are preserved as backups.
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
if ($env:OS -ne 'Windows_NT') { throw 'This setup is for Windows only.' }

$projectPath = (Resolve-Path -LiteralPath $ProjectRoot).Path.TrimEnd('\')
if (-not (Test-Path -LiteralPath (Join-Path $projectPath 'pubspec.yaml'))) {
    throw 'ProjectRoot must contain pubspec.yaml.'
}
if ((Get-Content -LiteralPath (Join-Path $projectPath 'pubspec.yaml') -Raw) -notmatch '(?m)^name:\s*cit_app\s*$') {
    throw 'ProjectRoot must be the CIT_App Flutter project.'
}
$cachePath = [IO.Path]::GetFullPath($CacheRoot).TrimEnd('\')
$hasher = [Security.Cryptography.SHA256]::Create()
try {
    $hash = [BitConverter]::ToString($hasher.ComputeHash(
        [Text.Encoding]::UTF8.GetBytes($projectPath.ToLowerInvariant())
    )).Replace('-', '').Substring(0, 12).ToLowerInvariant()
} finally { $hasher.Dispose() }
$projectCache = Join-Path $cachePath $hash
$backupRoot = Join-Path $projectPath '.build-cache-backups'
$stamp = Get-Date -Format 'yyyyMMdd-HHmmss-fff'

# A Git-local ignore keeps these machine-specific backups out of commits.
$gitDirectory = Join-Path $projectPath '.git'
if (Test-Path -LiteralPath $gitDirectory -PathType Container) {
    $exclude = Join-Path $gitDirectory 'info\exclude'
    if (-not (Test-Path -LiteralPath (Split-Path -Parent $exclude))) {
        New-Item -ItemType Directory -Path (Split-Path -Parent $exclude) -Force | Out-Null
    }
    $oldExclude = if (Test-Path -LiteralPath $exclude) { Get-Content -LiteralPath $exclude -Raw } else { '' }
    if ($oldExclude -notmatch '(?m)^/\.build-cache-backups/\s*$') {
        Add-Content -LiteralPath $exclude -Value "`n/.build-cache-backups/"
    }
}

foreach ($relative in @('build', '.dart_tool', 'android\.gradle')) {
    $source = [IO.Path]::GetFullPath((Join-Path $projectPath $relative))
    $leaf = $relative.Replace('\', '-')
    $legacyTarget = [IO.Path]::GetFullPath((Join-Path $projectCache $leaf))
    $backup = [IO.Path]::GetFullPath((Join-Path $backupRoot "$leaf-$stamp"))
    if (-not $source.StartsWith($projectPath + '\', [StringComparison]::OrdinalIgnoreCase) -or
        -not $backup.StartsWith($backupRoot + '\', [StringComparison]::OrdinalIgnoreCase) -or
        -not $legacyTarget.StartsWith($projectCache + '\', [StringComparison]::OrdinalIgnoreCase)) {
        throw 'A generated directory resolved outside its expected root.'
    }
    $existing = Get-Item -LiteralPath $source -Force -ErrorAction SilentlyContinue
    if ($null -ne $existing -and -not [string]::IsNullOrEmpty($existing.LinkType)) {
        $linkTarget = [IO.Path]::GetFullPath([string]@($existing.Target)[0]).TrimEnd('\')
        if ($existing.LinkType -ne 'Junction' -or -not $linkTarget.Equals($legacyTarget, [StringComparison]::OrdinalIgnoreCase)) {
            throw "$source is linked elsewhere; it was left unchanged."
        }
        New-Item -ItemType Directory -Path $backupRoot -Force | Out-Null
        if (Test-Path -LiteralPath $backup) { throw "Backup already exists: $backup" }
        # Move only the known junction; never delete or move its target contents.
        Move-Item -LiteralPath $source -Destination $backup -ErrorAction Stop
        Write-Output "Preserved old $relative junction at $backup"
    } elseif ($null -ne $existing -and -not $existing.PSIsContainer) {
        throw "$source is not a directory; it was left unchanged."
    }
    New-Item -ItemType Directory -Path $source -Force | Out-Null
    Write-Output "$relative uses a normal project directory."
}

Write-Output 'Build directories are ready. Run flutter pub get, then run the app.'
