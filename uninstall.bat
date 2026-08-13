@echo off
setlocal

echo ============================================
echo Standup Assistant Uninstaller
echo ============================================
echo.

set "STARTUP=%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup\Standup Assistant.lnk"

echo Stopping Standup Assistant...
taskkill /F /IM AutoHotkey64.exe >nul 2>&1
taskkill /F /IM AutoHotkey.exe >nul 2>&1

echo Removing startup shortcut...

if exist "%STARTUP%" (
del "%STARTUP%"
)

if exist "%STARTUP%" (
echo.
echo Failed to remove startup shortcut.
) else (
echo.
echo Startup shortcut removed successfully.
)

echo.
echo Standup Assistant has been uninstalled.
echo Your Logs and Summaries folders have NOT been deleted.
echo AutoHotkey remains installed on this computer.
echo.
pause
