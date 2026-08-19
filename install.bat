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

powershell -NoProfile -Command ^
"$shell = New-Object -ComObject WScript.Shell; ^
$shortcut = $shell.CreateShortcut([Environment]::ExpandEnvironmentVariables('%STARTUP%')); ^
$shortcut.TargetPath = [IO.Path]::GetFullPath('%SCRIPT%'); ^
$shortcut.Arguments = 'background'; ^
$shortcut.Save()"

echo Creating desktop shortcut...

powershell -NoProfile -Command ^
"$desktop = [Environment]::GetFolderPath('Desktop'); ^
$shell = New-Object -ComObject WScript.Shell; ^
$shortcut = $shell.CreateShortcut((Join-Path $desktop 'Standup Assistant.lnk')); ^
$shortcut.TargetPath = [IO.Path]::GetFullPath('%SCRIPT%'); ^
$shortcut.Save()"

echo.
echo ============================================
echo Installation completed.
echo ============================================
echo.
echo Starting Standup Assistant...

start "" "%SCRIPT%" background

echo.
pause