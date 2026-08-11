@echo off
setlocal

echo ============================================
echo Standup Assistant Installer
echo ============================================
echo.

set "SCRIPT=%~dp0StandupAssistant.ahk"
set "STARTUP=%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup\Standup Assistant.lnk"

if not exist "%SCRIPT%" (
echo ERROR: StandupAssistant.ahk was not found.
echo %SCRIPT%
pause
exit /b 1
)

powershell -NoProfile -ExecutionPolicy Bypass -Command "$WshShell = New-Object -ComObject WScript.Shell; $Shortcut = $WshShell.CreateShortcut('%STARTUP%'); $Shortcut.TargetPath = '%SCRIPT%'; $Shortcut.WorkingDirectory = Split-Path '%SCRIPT%'; $Shortcut.Save()"

if exist "%STARTUP%" (
echo.
echo Startup shortcut created successfully.
echo.
start "" "%SCRIPT%"
) else (
echo.
echo Failed to create startup shortcut.
)

echo.
pause
