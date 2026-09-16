[CmdletBinding()]
param(
    [string]$ProjectRoot = (Split-Path -Parent $PSScriptRoot),
    [string]$CacheRoot = (Join-Path $env:LOCALAPPDATA 'CIT_App\build-cache')
)

# Keep generated files local while preserving Flutter/Android Studio's paths.
# Existing generated directories are retained as backups; nothing is deleted.
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
$excludedRoots = @($projectPath, $env:OneDrive, $env:OneDriveConsumer, $env:OneDriveCommercial)
foreach ($excludedRoot in $excludedRoots) {
    if ([string]::IsNullOrWhiteSpace($excludedRoot)) { continue }
    $excludedPath = [IO.Path]::GetFullPath($excludedRoot).TrimEnd('\')
    if ($cachePath.Equals($excludedPath, [StringComparison]::OrdinalIgnoreCase) -or
        $cachePath.StartsWith($excludedPath + '\', [StringComparison]::OrdinalIgnoreCase)) {
        throw 'CacheRoot must be outside the project and OneDrive.'
    }
}

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
    $destination = [IO.Path]::GetFullPath((Join-Path $projectCache $leaf))
    $backup = [IO.Path]::GetFullPath((Join-Path $backupRoot "$leaf-$stamp"))
    # Validate both ends immediately before any directory move.
    if (-not $source.StartsWith($projectPath + '\', [StringComparison]::OrdinalIgnoreCase) -or
        -not $backup.StartsWith($backupRoot + '\', [StringComparison]::OrdinalIgnoreCase) -or
        -not $destination.StartsWith($projectCache + '\', [StringComparison]::OrdinalIgnoreCase)) {
        throw 'A generated directory resolved outside its expected root.'
    }
    $existing = Get-Item -LiteralPath $source -Force -ErrorAction SilentlyContinue
    if ($null -ne $existing -and -not [string]::IsNullOrEmpty($existing.LinkType)) {
        $linkTarget = [IO.Path]::GetFullPath([string]@($existing.Target)[0]).TrimEnd('\')
        if ($existing.LinkType -eq 'Junction' -and $linkTarget.Equals($destination, [StringComparison]::OrdinalIgnoreCase)) {
            New-Item -ItemType Directory -Path $destination -Force | Out-Null
            Write-Output "$relative already uses $destination"
            continue
        }
        throw "$source is already linked elsewhere; it was left unchanged."
    }
    if ($null -ne $existing -and -not $existing.PSIsContainer) {
        throw "$source is not a directory; it was left unchanged."
    }
    New-Item -ItemType Directory -Path $destination -Force | Out-Null
    if ($null -ne $existing) {
        New-Item -ItemType Directory -Path $backupRoot -Force | Out-Null
        if (Test-Path -LiteralPath $backup) { throw "Backup already exists: $backup" }
        Move-Item -LiteralPath $source -Destination $backup -ErrorAction Stop
        Write-Output "Preserved old $relative at $backup"
    }
    New-Item -ItemType Junction -Path $source -Target $destination | Out-Null
    Write-Output "$relative -> $destination"
}

Write-Output 'Local build caches are ready. Run flutter pub get, then run the app.'
