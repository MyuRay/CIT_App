[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$BundlePath,
    [Parameter(Mandatory)][string]$BundletoolPath,
    [switch]$AllowUnsigned
)

# Read-only checks of the actual artifact. Never uploads or signs a bundle.
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$projectPath = Split-Path -Parent $PSScriptRoot
$bundleFile = (Resolve-Path -LiteralPath $BundlePath).Path
$bundletoolFile = (Resolve-Path -LiteralPath $BundletoolPath).Path
$javaFile = if ($env:JAVA_HOME) { Join-Path $env:JAVA_HOME 'bin/java.exe' } else { (Get-Command java).Source }
$jarsignerFile = Join-Path (Split-Path -Parent $javaFile) 'jarsigner.exe'
$pubspec = Get-Content -LiteralPath (Join-Path $projectPath 'pubspec.yaml') -Raw
if ($pubspec -notmatch '(?m)^version:\s*([^+\s]+)\+(\d+)\s*$') { throw 'pubspec version is missing.' }
$expectedName = $Matches[1]
$expectedCode = $Matches[2]

$validationOutput = & $javaFile -jar $bundletoolFile validate "--bundle=$bundleFile"
if ($LASTEXITCODE -ne 0) { throw 'bundletool validation failed.' }
$manifestText = & $javaFile -jar $bundletoolFile dump manifest "--bundle=$bundleFile" --module=base
if ($LASTEXITCODE -ne 0) { throw 'Unable to read bundled manifest.' }
[xml]$manifest = $manifestText -join "`n"
$androidNamespace = 'http://schemas.android.com/apk/res/android'
$root = $manifest.DocumentElement
$application = $root.SelectSingleNode('application')
$sdk = $root.SelectSingleNode('uses-sdk')
if ($root.GetAttribute('package') -ne 'jp.ac.chibakoudai.citapp') { throw 'Unexpected application ID.' }
if ($root.GetAttribute('versionName', $androidNamespace) -ne $expectedName -or
    $root.GetAttribute('versionCode', $androidNamespace) -ne $expectedCode) { throw 'Bundled version does not match pubspec.' }
if ([int]$sdk.GetAttribute('targetSdkVersion', $androidNamespace) -lt 36) { throw 'Target SDK must be at least 36.' }
foreach ($flag in @('debuggable', 'usesCleartextTraffic', 'testOnly')) {
    if ($application.GetAttribute($flag, $androidNamespace) -eq 'true') { throw "Unsafe release application flag: $flag" }
}
$permissions = @($root.SelectNodes('uses-permission') | ForEach-Object { $_.GetAttribute('name', $androidNamespace) })
$forbidden = @(
    'com.google.android.gms.permission.AD_ID',
    'android.permission.ACCESS_ADSERVICES_AD_ID', 'android.permission.ACCESS_ADSERVICES_ATTRIBUTION',
    'android.permission.READ_MEDIA_IMAGES', 'android.permission.READ_MEDIA_VIDEO',
    'android.permission.READ_EXTERNAL_STORAGE', 'android.permission.WRITE_EXTERNAL_STORAGE',
    'android.permission.MANAGE_EXTERNAL_STORAGE', 'android.permission.REQUEST_INSTALL_PACKAGES'
)
foreach ($permission in $forbidden) {
    if ($permission -in $permissions) { throw "Unexpected permission: $permission" }
}
foreach ($metadataName in @('google_analytics_adid_collection_enabled', 'google_analytics_default_allow_ad_personalization_signals')) {
    $entry = @($application.SelectNodes('meta-data') | Where-Object { $_.GetAttribute('name', $androidNamespace) -eq $metadataName })
    if ($entry.Count -ne 1 -or $entry[0].GetAttribute('value', $androidNamespace) -ne 'false') {
        throw "Analytics privacy setting is missing: $metadataName"
    }
}

$bundleConfig = & $javaFile -jar $bundletoolFile dump config "--bundle=$bundleFile"
if ($LASTEXITCODE -ne 0 -or ($bundleConfig -join "`n") -notmatch 'PAGE_ALIGNMENT_16K') {
    throw 'Bundle does not declare 16 KB APK ZIP alignment.'
}

Add-Type -AssemblyName System.IO.Compression.FileSystem
$archive = [IO.Compression.ZipFile]::OpenRead($bundleFile)
$libraries = @()
try {
    $hasSignature = @($archive.Entries | Where-Object { $_.FullName -match '^META-INF/.*\.(RSA|DSA|EC)$' }).Count -gt 0
    if (-not $hasSignature -and -not $AllowUnsigned) { throw 'UNSIGNED bundle: restore the Play upload key and rebuild.' }
    foreach ($entry in $archive.Entries | Where-Object { $_.FullName -match '^base/lib/(arm64-v8a|x86_64)/.*\.so$' }) {
        $stream = $entry.Open()
        $memory = [IO.MemoryStream]::new()
        try { $stream.CopyTo($memory); $bytes = $memory.ToArray() } finally { $stream.Dispose(); $memory.Dispose() }
        if ($bytes.Length -lt 64 -or $bytes[0] -ne 127 -or $bytes[1] -ne 69 -or $bytes[2] -ne 76 -or
            $bytes[3] -ne 70 -or $bytes[4] -ne 2 -or $bytes[5] -ne 1) { throw "Unexpected ELF format: $($entry.FullName)" }
        $tableOffset = [BitConverter]::ToUInt64($bytes, 32)
        $entrySize = [BitConverter]::ToUInt16($bytes, 54)
        $entryCount = [BitConverter]::ToUInt16($bytes, 56)
        $alignments = @()
        for ($i = 0; $i -lt $entryCount; $i++) {
            $offset = [int]($tableOffset + $i * $entrySize)
            if ([BitConverter]::ToUInt32($bytes, $offset) -eq 1) {
                $alignment = [BitConverter]::ToUInt64($bytes, $offset + 48)
                $alignments += $alignment
                if ($alignment -lt 16384) { throw "ELF alignment below 16 KB: $($entry.FullName)" }
            }
        }
        if ($alignments.Count -eq 0) { throw "No ELF LOAD segments: $($entry.FullName)" }
        $libraries += [pscustomobject]@{ path = $entry.FullName; minimumLoadAlignment = ($alignments | Measure-Object -Minimum).Minimum }
    }
    if ($libraries.Count -eq 0) { throw 'No 64-bit native libraries checked.' }
} finally { $archive.Dispose() }

if ($hasSignature) {
    $signatureText = & $jarsignerFile '-J-Duser.language=en' -verify -verbose -certs $bundleFile 2>&1 | Out-String
    if ($LASTEXITCODE -ne 0 -or $signatureText -notmatch 'jar verified' -or $signatureText -match 'CN=Android Debug') {
        throw 'Bundle signature verification failed or uses the Android debug key.'
    }
}
[pscustomobject]@{
    bundle = $bundleFile
    sha256 = (Get-FileHash -LiteralPath $bundleFile -Algorithm SHA256).Hash
    versionName = $expectedName
    versionCode = [int]$expectedCode
    targetSdk = [int]$sdk.GetAttribute('targetSdkVersion', $androidNamespace)
    minSdk = [int]$sdk.GetAttribute('minSdkVersion', $androidNamespace)
    signed = $hasSignature
    status = $(if ($hasSignature) { 'LOCAL_CHECKS_PASSED_CHECK_PLAY_UPLOAD_CERTIFICATE' } else { 'UNSIGNED_LOCAL_INSPECTION_ONLY_NOT_FOR_UPLOAD' })
    pageAlignment = '16 KB (bundle config and 64-bit ELF LOAD segments)'
    permissions = $permissions
    libraries = $libraries
} | ConvertTo-Json -Depth 5
