@echo off
REM ユーザー数推移エクスポートスクリプト（Windows用バッチファイル）

echo ========================================
echo ユーザー数推移エクスポートツール
echo ========================================
echo.

REM サービスアカウントキーのパスを確認
if "%GOOGLE_APPLICATION_CREDENTIALS%"=="" (
    echo [警告] GOOGLE_APPLICATION_CREDENTIALS環境変数が設定されていません
    echo.
    echo サービスアカウントキーのパスを入力してください（Enterでスキップ）:
    set /p SERVICE_ACCOUNT="パス: "
    if not "!SERVICE_ACCOUNT!"=="" (
        set GOOGLE_APPLICATION_CREDENTIALS=!SERVICE_ACCOUNT!
    )
)

REM Node.jsの存在確認
where node >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo [エラー] Node.jsが見つかりません
    echo Node.jsをインストールしてください: https://nodejs.org/
    pause
    exit /b 1
)

REM スクリプトの実行
echo ユーザー数推移データを取得中...
echo.

cd /d %~dp0..
node scripts/user-growth-stats.js %*

if %ERRORLEVEL% EQU 0 (
    echo.
    echo ========================================
    echo エクスポートが完了しました！
    echo ========================================
) else (
    echo.
    echo ========================================
    echo エラーが発生しました
    echo ========================================
)

pause


