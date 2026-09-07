# Gradle transforms キャッシュ破損時の修復スクリプト
# 使い方:
#   1. Android Studio / Cursor の Gradle 同期を止める（Android Studio は完全終了推奨）
#   2. PowerShell: .\scripts\fix-gradle-cache.ps1

$ErrorActionPreference = "Continue"

$projectRoot = Split-Path $PSScriptRoot -Parent
$androidDir = Join-Path $projectRoot "android"
$transformsDir = Join-Path $env:USERPROFILE ".gradle\caches\8.11.1\transforms"

$javaHomes = @(
    "$env:LOCALAPPDATA\Android\Sdk\jbr",
    "C:\Program Files\Android\Android Studio\jbr",
    "C:\Program Files\Android\Android Studio1\jbr"
)

foreach ($home in $javaHomes) {
    if (Test-Path (Join-Path $home "bin\java.exe")) {
        $env:JAVA_HOME = $home
        break
    }
}

Write-Host "== Gradle cache repair ==" -ForegroundColor Cyan
Write-Host "Project: $projectRoot"

if (Test-Path (Join-Path $androidDir "gradlew.bat")) {
    Write-Host "Stopping Gradle daemons..."
    Push-Location $androidDir
    & .\gradlew.bat --stop 2>&1 | Out-Null
    Pop-Location
    Start-Sleep -Seconds 2
}

$locked = Get-Process -Name "studio64" -ErrorAction SilentlyContinue
if ($locked) {
    Write-Host ""
    Write-Host "警告: Android Studio が起動中です。" -ForegroundColor Yellow
    Write-Host "キャッシュ削除前に Android Studio を終了してください。" -ForegroundColor Yellow
    Write-Host "（終了後にこのスクリプトを再実行）"
    Write-Host ""
}

if (Test-Path $transformsDir) {
    Write-Host "Deleting: $transformsDir"
    Remove-Item -Recurse -Force $transformsDir -ErrorAction SilentlyContinue
    cmd /c "rmdir /s /q `"$transformsDir`"" 2>$null
}

if (Test-Path $transformsDir) {
    Write-Host "削除できませんでした。Android Studio を終了してから再実行してください。" -ForegroundColor Red
    exit 1
}

Write-Host "Deleting project caches..."
Remove-Item -Recurse -Force (Join-Path $androidDir ".gradle") -ErrorAction SilentlyContinue
Remove-Item -Recurse -Force (Join-Path $projectRoot "build") -ErrorAction SilentlyContinue

Write-Host "Running flutter clean..."
Push-Location $projectRoot
flutter clean 2>&1 | Out-Null
flutter pub get 2>&1 | Out-Null
Pop-Location

Write-Host ""
Write-Host "完了。次を実行してください:" -ForegroundColor Green
Write-Host "  flutter run"
Write-Host "または Android Studio を開き直して Gradle Sync"
