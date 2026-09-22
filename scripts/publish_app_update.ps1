#requires -Version 7.0
param(
    [Parameter(Mandatory = $true)]
    [ValidateSet('android', 'ios')]
    [string]$Platform,
    [Parameter(Mandatory = $true)]
    [ValidatePattern('^\d+\.\d+\.\d+$')]
    [string]$Version,
    [ValidatePattern('^\d+(\.\d+){0,2}$')]
    [string]$BuildNumber,
    [string]$StoreUrl,
    [switch]$Disable,
    [switch]$ValidateOnly,
    [string]$ProjectId = 'cit-app-2de1c'
)

# Run only AFTER the specified release is available to all intended store users.
# Access tokens stay in memory; existing unrelated Remote Config is preserved.
$ErrorActionPreference = 'Stop'
if ($Platform -eq 'android' -and $BuildNumber -notmatch '^\d+$') {
    throw 'Android requires the published integer versionCode in -BuildNumber.'
}
if (-not $StoreUrl -and $Platform -eq 'android') {
    $StoreUrl = 'https://play.google.com/store/apps/details?id=jp.ac.chibakoudai.citapp'
}
if (-not $StoreUrl -and $Platform -eq 'ios') {
    $StoreUrl = 'https://apps.apple.com/jp/app/cit-app/id6752514796'
}
$store = $null
if (-not [Uri]::TryCreate($StoreUrl, [UriKind]::Absolute, [ref]$store) -or
    $store.Scheme -ne 'https' -or $store.UserInfo -or $store.Port -ne 443) {
    throw 'A valid HTTPS store URL is required.'
}
if ($Platform -eq 'android' -and ($store.Host -ne 'play.google.com' -or
    $store.AbsolutePath -ne '/store/apps/details' -or
    $store.Query -notmatch '(^\?|&)id=jp\.ac\.chibakoudai\.citapp(&|$)')) {
    throw 'Use the CIT App Google Play URL.'
}
if ($Platform -eq 'ios' -and ($store.Host -ne 'apps.apple.com' -or
    $store.AbsolutePath -notmatch '/id6752514796/?$')) {
    throw 'Use the published CIT App App Store URL.'
}

$token = & gcloud.cmd auth print-access-token
if ($LASTEXITCODE -ne 0 -or -not $token) { throw 'Google Cloud authentication failed.' }
try {
    $endpoint = "https://firebaseremoteconfig.googleapis.com/v1/projects/$ProjectId/remoteConfig"
    $headers = @{
        Authorization = "Bearer $token"
        'x-goog-user-project' = $ProjectId
        'Accept-Encoding' = 'gzip'
    }
    # The gzip user agent is needed for Google's response to include an ETag.
    $response = Invoke-WebRequest -Uri $endpoint -Headers $headers -UserAgent 'cit-app-release (gzip)' -UseBasicParsing
    $etag = @($response.Headers['ETag'])[0]
    if (-not $etag) { throw 'No ETag returned; refusing to overwrite Remote Config.' }
    $template = $response.Content | ConvertFrom-Json
    $template.PSObject.Properties.Remove('version')
    if (-not $template.parameters) {
        $template | Add-Member -NotePropertyName parameters -NotePropertyValue ([pscustomobject]@{}) -Force
    }
    $policyValues = [ordered]@{
        enabled = -not $Disable.IsPresent
        version = $Version
        storeUrl = $StoreUrl
    }
    if ($BuildNumber) { $policyValues['buildNumber'] = $BuildNumber }
    $policy = $policyValues | ConvertTo-Json -Compress
    $key = "app_update_$Platform"
    $parameter = @{
        defaultValue = @{value = $policy}
        valueType = 'JSON'
        description = 'Published CIT App release for the optional startup update prompt. Change only after store rollout completes.'
    }
    $template.parameters | Add-Member -NotePropertyName $key -NotePropertyValue $parameter -Force
    $body = [Text.Encoding]::UTF8.GetBytes(($template | ConvertTo-Json -Depth 100))
    $headers['If-Match'] = $etag

    # Validate first. Do not use the validation ETag for the subsequent write.
    Invoke-WebRequest -Method Put -Uri "${endpoint}?validate_only=true" -Headers $headers `
        -UserAgent 'cit-app-release (gzip)' -ContentType 'application/json; charset=utf-8' -Body $body -UseBasicParsing -SkipHeaderValidation | Out-Null
    if ($ValidateOnly) {
        Write-Output "Validated $key = $Version ($BuildNumber). No changes published."
        return
    }
    Invoke-WebRequest -Method Put -Uri $endpoint -Headers $headers `
        -UserAgent 'cit-app-release (gzip)' -ContentType 'application/json; charset=utf-8' -Body $body -UseBasicParsing -SkipHeaderValidation | Out-Null
    $headers.Remove('If-Match')
    $verified = Invoke-RestMethod -Uri $endpoint -Headers $headers -UserAgent 'cit-app-release (gzip)'
    if ($verified.parameters.$key.defaultValue.value -ne $policy) {
        throw 'Published value could not be verified. Read Remote Config before retrying.'
    }
    Write-Output "Published and verified $key = $Version ($BuildNumber), enabled=$(-not $Disable.IsPresent)."
} finally {
    $token = $null
    if ($headers) { $headers.Remove('Authorization') }
}
