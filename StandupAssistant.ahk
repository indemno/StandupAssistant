#Requires AutoHotkey v2.0
#SingleInstance Force

baseDir := A_ScriptDir
psScript := baseDir "\StandupAssistant.ps1"
configFile := baseDir "\config.json"

lastTrigger := ""

if !FileExist(psScript) {
MsgBox("StandupAssistant.ps1 was not found in:`n" psScript)
ExitApp
}

TrayTip("Standup Assistant", "Scheduler is running.", 3)

; Start interactive CLI only if launched manually
if (A_Args.Length = 0) {
Run("powershell.exe -NoExit -ExecutionPolicy Bypass -File `"" psScript "`"")
}

; Always run the scheduler
SetTimer(CheckTime, 60000)
CheckTime()

CheckTime() {
global lastTrigger, psScript, configFile


standupTime := "08:55"
reflectionTime := "16:00"

if FileExist(configFile) {
    json := FileRead(configFile, "UTF-8")

    if RegExMatch(json, '"morningTime"\s*:\s*"([^"]+)"', &m)
        standupTime := m[1]

    if RegExMatch(json, '"dailyTime"\s*:\s*"([^"]+)"', &r)
        reflectionTime := r[1]
}

current := FormatTime(, "HH:mm")

if (current = reflectionTime) {
    if (lastTrigger != current) {
        lastTrigger := current
        Run("powershell.exe -ExecutionPolicy Bypass -File `"" psScript "`" daily")
    }
}
else if (current = standupTime) {
    if (lastTrigger != current) {
        lastTrigger := current
        Run("powershell.exe -ExecutionPolicy Bypass -File `"" psScript "`" today")
    }
}
else {
    lastTrigger := ""
}


}
