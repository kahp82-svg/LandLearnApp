@echo off
chcp 65001 >nul
cd /d "%~dp0"
echo.
echo   LandLearnApp -^> dothome /html/app/
echo   FTP 비밀번호 입력 필요
echo.
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0upload-to-dothome.ps1"
pause
