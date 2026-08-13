@echo off
setlocal

echo ============================================
echo Standup Assistant Installer
echo ============================================
echo.

set "BASE=%~dp0"
set "SCRIPT=%BASE%StandupAssistant.ahk"
set "INSTALLER=%BASE%AutoHotkey_2.0.26_setup.exe"
set "STARTUP=%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup\Standup Assistant.lnk"

if not exist "%SCRIPT%" (
echo ERROR: StandupAssistant.ahk was not found.
pause
exit /b 1
)

if not exist "%INSTALLER%" (
echo ERROR: AutoHotkey_2.0.26_setup.exe was not found.
pause
exit /b 1
)

echo Installing AutoHotkey v2...
start /wait "" "%INSTALLER%" /silent

echo Creating startup shortcut...

powershell -NoProfile -ExecutionPolicy Bypass -Command ^
"$WshShell = New-Object -ComObject WScript.Shell; ^
$Shortcut = $WshShell.CreateShortcut('%STARTUP%'); ^
$Shortcut.TargetPath = '%SCRIPT%'; ^
$Shortcut.Arguments = 'background'; ^
$Shortcut.WorkingDirectory = '%BASE%'; ^
$Shortcut.Save()"

if exist "%STARTUP%" (
echo.
echo Installation completed successfully.
echo Standup Assistant will start automatically in the background when Windows starts.
echo.
echo Starting Standup Assistant...
start "" "%SCRIPT%" background
) else (
echo.
echo Failed to create startup shortcut.
)

echo.
pause
