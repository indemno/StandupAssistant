@echo off
setlocal

echo ============================================
echo Standup Assistant Installer
echo ============================================
echo.

set "BASE=%~dp0"
set "SCRIPT=%BASE%StandupAssistant.ahk"
set "STARTUP=%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup\Standup Assistant.lnk"
set "DESKTOP=%USERPROFILE%\Desktop\Standup Assistant.lnk"

if not exist "%SCRIPT%" (
    echo ERROR: StandupAssistant.ahk was not found.
    pause
    exit /b 1
)

start "" "https://www.autohotkey.com/"

echo Creating startup shortcut...

powershell -NoProfile -ExecutionPolicy Bypass -Command ^
"$WshShell = New-Object -ComObject WScript.Shell; ^
$Shortcut = $WshShell.CreateShortcut('%STARTUP%'); ^
$Shortcut.TargetPath = '%SCRIPT%'; ^
$Shortcut.Arguments = 'background'; ^
$Shortcut.Save()"

echo Creating desktop shortcut...

powershell -NoProfile -ExecutionPolicy Bypass -Command ^
"$desktop = [Environment]::GetFolderPath('Desktop'); ^
$shell = New-Object -ComObject WScript.Shell; ^
$shortcut = $shell.CreateShortcut((Join-Path $desktop 'Standup Assistant.lnk')); ^
$shortcut.TargetPath = '%SCRIPT%'; ^
$shortcut.Save()"

echo.
echo ============================================
echo Installation completed.
echo ============================================
echo.
echo Standup Assistant shortcut created on the desktop.
echo Standup Assistant will start automatically with Windows.
echo.
echo Please install AutoHotkey v2 if it is not already installed.
echo.
pause