#Requires AutoHotkey v2.0
#SingleInstance Force

; ============================================
; Standup Assistant Scheduler
; ============================================

baseDir := A_ScriptDir
psScript := baseDir "\StandupAssistant.ps1"
configFile := baseDir "\config.json"

lastTrigger := ""

if !FileExist(psScript) {
    MsgBox(
        "StandupAssistant.ps1 was not found in:`n" psScript,
        "Standup Assistant",
        "Iconx"
    )
    ExitApp
}

; --------------------------------------------------
; Read startup preference from config
; --------------------------------------------------

showCliOnStartup := false

if FileExist(configFile) {
    json := FileRead(configFile, "UTF-8")

    if RegExMatch(json, '"showCliOnStartup"\s*:\s*(true|false)', &s)
        showCliOnStartup := (s[1] = "true")
}

; --------------------------------------------------
; Helper: launch the interactive PowerShell CLI
; --------------------------------------------------

LaunchCli() {
    global psScript
    Run("powershell.exe -NoExit -ExecutionPolicy Bypass -File `"" psScript "`"")
}

; --------------------------------------------------
; Manual launch
; Open command mode only.
; Scheduler stays running, but does NOT immediately
; check the timer.
; --------------------------------------------------

if (A_Args.Length = 0) {
    LaunchCli()
}

; --------------------------------------------------
; Startup/background mode
; --------------------------------------------------

else if (A_Args[1] = "background") {
    if (showCliOnStartup) {
        LaunchCli()
    }

    ; Check immediately when started automatically
    SetTimer(CheckTime, 60000)
    CheckTime()
}

; --------------------------------------------------
; Start scheduler for manual launch
; --------------------------------------------------

if (A_Args.Length = 0) {
    SetTimer(CheckTime, 60000)
}
else if (A_Args[1] != "background") {
    SetTimer(CheckTime, 60000)
}

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

    ; Daily reflection
    if (current = reflectionTime) {
        if (lastTrigger != current) {
            lastTrigger := current
            Run("powershell.exe -ExecutionPolicy Bypass -File `"" psScript "`" daily")
        }
    }

    ; Morning standup
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