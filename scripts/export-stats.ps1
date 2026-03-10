# ユーザー数推移エクスポートスクリプト（PowerShell版）

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "ユーザー数推移エクスポートツール" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# サービスアカウントキーのパスを確認
if (-not $env:GOOGLE_APPLICATION_CREDENTIALS) {
    Write-Host "[警告] GOOGLE_APPLICATION_CREDENTIALS環境変数が設定されていません" -ForegroundColor Yellow
    Write-Host ""
    $serviceAccount = Read-Host "サービスアカウントキーのパスを入力してください（Enterでスキップ）"
    if ($serviceAccount) {
        $env:GOOGLE_APPLICATION_CREDENTIALS = $serviceAccount
    }
}

# Node.jsの存在確認
$nodePath = Get-Command node -ErrorAction SilentlyContinue
if (-not $nodePath) {
    Write-Host "[エラー] Node.jsが見つかりません" -ForegroundColor Red
    Write-Host "Node.jsをインストールしてください: https://nodejs.org/" -ForegroundColor Red
    Read-Host "Enterキーを押して終了"
    exit 1
}

# スクリプトの実行
Write-Host "ユーザー数推移データを取得中..." -ForegroundColor Green
Write-Host ""

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$projectRoot = Split-Path -Parent $scriptDir
Set-Location $projectRoot

node scripts/user-growth-stats.js $args

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Green
    Write-Host "エクスポートが完了しました！" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Green
} else {
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Red
    Write-Host "エラーが発生しました" -ForegroundColor Red
    Write-Host "========================================" -ForegroundColor Red
}

Read-Host "Enterキーを押して終了"


