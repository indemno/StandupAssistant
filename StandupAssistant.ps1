param(
[string]$Command,
[string]$Argument
)

$ErrorActionPreference = 'Stop'

# ============================================

# Standup Assistant

# ============================================

$BaseDir = $PSScriptRoot
$LogsDir = Join-Path $BaseDir 'Logs'
$SummariesDir = Join-Path $BaseDir 'Summaries'
$ConfigFile = Join-Path $BaseDir 'config.json'
$SummaryScript = Join-Path $BaseDir 'GenerateMonthlySummary.ps1'

# Create folders

if (-not (Test-Path $LogsDir)) {
New-Item -ItemType Directory -Path $LogsDir | Out-Null
}

if (-not (Test-Path $SummariesDir)) {
New-Item -ItemType Directory -Path $SummariesDir | Out-Null
}

# Create default config

if (-not (Test-Path $ConfigFile)) {
@{
dailyTime   = '16:00'
morningTime = '08:55'
} | ConvertTo-Json | Set-Content $ConfigFile -Encoding UTF8
}

function Get-Config {
Get-Content $ConfigFile -Raw | ConvertFrom-Json
}

function Save-Config($cfg) {
$cfg | ConvertTo-Json | Set-Content $ConfigFile -Encoding UTF8
}

function Get-CurrentLogFile {
Join-Path $LogsDir ('standup-{0}.txt' -f (Get-Date -Format 'yyyy-MM'))
}

function Show-Header {
Clear-Host
Write-Host '========================================' -ForegroundColor Cyan
Write-Host 'Standup Assistant' -ForegroundColor Cyan
Write-Host '========================================' -ForegroundColor Cyan
Write-Host
}

function Show-Help {
Show-Header


Write-Host 'Purpose' -ForegroundColor Yellow
Write-Host '-------'
Write-Host 'Standup Assistant is a lightweight work journal for developers and knowledge workers.'
Write-Host 'It keeps a daily record of completed work, plans for tomorrow, and blockers.'
Write-Host
Write-Host 'AutoHotkey launches this script automatically:'
Write-Host '  - Standup time      : shows today''s latest entry'
Write-Host '  - Daily reflection  : opens the guided reflection questions'
Write-Host
Write-Host 'All entries are stored in monthly log files under the Logs folder.'
Write-Host 'Monthly summaries can be generated and sent to an AI assistant for manager updates.'
Write-Host
Write-Host 'Commands' -ForegroundColor Yellow
Write-Host '--------'
Write-Host 'edit        Edit today''s reflection (values are prefilled)'
Write-Host 'list        List available months and choose one'
Write-Host 'summary     Generate a monthly summary file'
Write-Host 'set time    Configure standup and daily reflection times'
Write-Host 'help        Show this help screen'
Write-Host


}

function Get-TodayBlock {
$logFile = Get-CurrentLogFile
$date = Get-Date -Format 'yyyy-MM-dd'


if (-not (Test-Path $logFile)) {
    return $null
}

$content = Get-Content $logFile -Raw

$dateIndex = $content.LastIndexOf($date)
if ($dateIndex -lt 0) {
    return $null
}

$startIndex = $content.LastIndexOf('========================================', $dateIndex)
if ($startIndex -lt 0) {
    $startIndex = 0
}

$nextIndex = $content.IndexOf('========================================', $dateIndex + $date.Length)

if ($nextIndex -gt $dateIndex) {
    return @{
        Start = $startIndex
        End = $nextIndex
        Text = $content.Substring($startIndex, $nextIndex - $startIndex).Trim()
        FullContent = $content
    }
}
else {
    return @{
        Start = $startIndex
        End = $content.Length
        Text = $content.Substring($startIndex).Trim()
        FullContent = $content
    }
}


}

function Get-DayBlock {
param([datetime]$Date)


$logFile = Join-Path $LogsDir ('standup-{0}.txt' -f $Date.ToString('yyyy-MM'))
$dateText = $Date.ToString('yyyy-MM-dd')

if (-not (Test-Path $logFile)) {
    return $null
}

$content = Get-Content $logFile -Raw

$dateIndex = $content.LastIndexOf($dateText)
if ($dateIndex -lt 0) {
    return $null
}

$startIndex = $content.LastIndexOf('========================================', $dateIndex)
if ($startIndex -lt 0) {
    $startIndex = 0
}

$nextIndex = $content.IndexOf('========================================', $dateIndex + $dateText.Length)

if ($nextIndex -gt $dateIndex) {
    return @{
        Start = $startIndex
        End = $nextIndex
        Text = $content.Substring($startIndex, $nextIndex - $startIndex).Trim()
        FullContent = $content
    }
}
else {
    return @{
        Start = $startIndex
        End = $content.Length
        Text = $content.Substring($startIndex).Trim()
        FullContent = $content
    }
}

}

function Show-Week {
Show-Header


Write-Host "Last 5 workdays" -ForegroundColor Green
Write-Host

$entries = @()
$date = Get-Date

while ($entries.Count -lt 5) {

    # Skip weekends
    if ($date.DayOfWeek -ne [System.DayOfWeek]::Saturday -and
        $date.DayOfWeek -ne [System.DayOfWeek]::Sunday) {

        $entry = Get-DayBlock $date

        if ($entry) {
            $entries += [PSCustomObject]@{
                Date = $date
                Text = $entry.Text
            }
        }
    }

    $date = $date.AddDays(-1)

    # Safety stop after searching one year
    if (((Get-Date) - $date).Days -gt 365) {
        break
    }
}

if ($entries.Count -eq 0) {
    Write-Host "No entries found." -ForegroundColor DarkGray
    return
}

foreach ($entry in $entries | Sort-Object Date -Descending) {
    Write-Host $entry.Text
    Write-Host
    Write-Host "----------------------------------------" -ForegroundColor DarkGray
    Write-Host
}
Read-Host "Press Enter to return"

}





function Get-TodayBlock {
return Get-DayBlock (Get-Date)
}




function Show-Today {
Show-Header


$yesterday = Get-DayBlock ((Get-Date).AddDays(-1))
$today = Get-DayBlock (Get-Date)

Write-Host ('Yesterday ({0})' -f (Get-Date).AddDays(-1).ToString('yyyy-MM-dd')) -ForegroundColor Yellow
Write-Host

if ($yesterday) {
    Write-Host $yesterday.Text
}
else {
    Write-Host 'No entry for yesterday.' -ForegroundColor DarkGray
}

Write-Host
Write-Host '----------------------------------------' -ForegroundColor DarkGray
Write-Host

Write-Host ('Today ({0})' -f (Get-Date).ToString('yyyy-MM-dd')) -ForegroundColor Green
Write-Host

if ($today) {
    Write-Host $today.Text
}
else {
    Write-Host 'No entry for today yet.' -ForegroundColor DarkGray
}

Write-Host
Write-Host '----------------------------------------' -ForegroundColor DarkGray
Write-Host


}


function Edit-Today {
Show-Header


$logFile = Get-CurrentLogFile
$date = Get-Date -Format 'yyyy-MM-dd'
$block = Get-TodayBlock

$done = ''
$plan = ''
$blockers = ''

if ($block) {
    $lines = $block.Text -split "`r?`n"

    for ($i = 0; $i -lt $lines.Count; $i++) {
        switch ($lines[$i].Trim()) {
            'What I did:' {
                if ($i + 1 -lt $lines.Count) {
                    $done = $lines[$i + 1].TrimStart('-',' ')
                }
            }
            'Plan tomorrow:' {
                if ($i + 1 -lt $lines.Count) {
                    $plan = $lines[$i + 1].TrimStart('-',' ')
                }
            }
            'Blockers:' {
                if ($i + 1 -lt $lines.Count) {
                    $blockers = $lines[$i + 1].TrimStart('-',' ')
                }
            }
        }
    }
}

Write-Host 'Press Enter to keep the current value.' -ForegroundColor Yellow
Write-Host

$newDone = Read-Host ('What did you do today? [{0}]' -f $done)
if ([string]::IsNullOrWhiteSpace($newDone)) {
    $newDone = $done
}

$newPlan = Read-Host ('Plan for tomorrow? [{0}]' -f $plan)
if ([string]::IsNullOrWhiteSpace($newPlan)) {
    $newPlan = $plan
}

$newBlockers = Read-Host ('Any blockers? [{0}]' -f $blockers)
if ([string]::IsNullOrWhiteSpace($newBlockers)) {
    $newBlockers = $blockers
}

$newEntry = "========================================`n$date`n`nWhat I did:`n- $newDone`n`nPlan tomorrow:`n- $newPlan`n`nBlockers:`n- $newBlockers`n"

if (-not (Test-Path $logFile)) {
    Set-Content -Path $logFile -Value $newEntry -Encoding UTF8
}
elseif ($block) {
    $before = $block.FullContent.Substring(0, $block.Start)
    $after = $block.FullContent.Substring($block.End)
    $updated = $before + $newEntry + $after
    Set-Content -Path $logFile -Value $updated -Encoding UTF8
}
else {
    Add-Content -Path $logFile -Value ("`n" + $newEntry) -Encoding UTF8
}

Write-Host
Write-Host 'Saved successfully.' -ForegroundColor Green
Start-Sleep -Seconds 1


}
function Show-History {
param([string]$Month)


Show-Header

$file = Join-Path $LogsDir ('standup-{0}.txt' -f $Month)

if (-not (Test-Path $file)) {
    Write-Host ('No log file found for {0}' -f $Month) -ForegroundColor Yellow
    Read-Host 'Press Enter to return'
    return
}

Write-Host ('History - {0}' -f $Month) -ForegroundColor Green
Write-Host

Get-Content $file | Out-Host

Write-Host
Read-Host 'Press Enter to return'


}

function List-Months {
Show-Header


$files = Get-ChildItem -Path $LogsDir -Filter 'standup-*.txt' -File | Sort-Object Name

if ($files.Count -eq 0) {
    Write-Host 'No log files found in Logs folder.' -ForegroundColor Yellow
    Read-Host 'Press Enter to return'
    return
}

Write-Host 'Available months:' -ForegroundColor Green
Write-Host

$months = @()

for ($i = 0; $i -lt $files.Count; $i++) {
    $month = $files[$i].BaseName.Replace('standup-','')
    $months += $month
    Write-Host ('{0}. {1}' -f ($i + 1), $month)
}

Write-Host
$selection = Read-Host 'Select month (number or YYYY-MM, Enter to cancel)'

if ([string]::IsNullOrWhiteSpace($selection)) {
    return
}

if ($selection -match '^\\d+$') {
    $index = [int]$selection - 1
    if ($index -ge 0 -and $index -lt $months.Count) {
        Show-History $months[$index]
        return
    }
}

Show-History $selection


}

function Generate-Summary {
Show-Header


if (-not (Test-Path $SummaryScript)) {
    Write-Host 'GenerateMonthlySummary.ps1 not found.' -ForegroundColor Yellow
    Read-Host 'Press Enter to return'
    return
}

Write-Host 'Generating monthly summary...' -ForegroundColor Green
Write-Host

powershell -ExecutionPolicy Bypass -File $SummaryScript

Write-Host
Read-Host 'Press Enter to return'


}

function Set-Times {
Show-Header

$cfg = Get-Config

Write-Host 'Configure reminder settings' -ForegroundColor Green
Write-Host

$standup = Read-Host ('Time for standup [{0}]' -f $cfg.morningTime)
if ([string]::IsNullOrWhiteSpace($standup)) {
    $standup = $cfg.morningTime
}

$reflection = Read-Host ('Time for daily reflection [{0}]' -f $cfg.dailyTime)
if ([string]::IsNullOrWhiteSpace($reflection)) {
    $reflection = $cfg.dailyTime
}

function Normalize-Time([string]$t) {
    $t = $t.Trim()

    if ($t -match '^(\d{2})(\d{2})$') {
        return ($Matches[1] + ':' + $Matches[2])
    }

    if ($t -match '^(\d{1,2})[:.](\d{2})$') {
        $h = [int]$Matches[1]
        $m = [int]$Matches[2]

        if ($h -ge 0 -and $h -le 23 -and $m -ge 0 -and $m -le 59) {
            return ('{0:00}:{1:00}' -f $h, $m)
        }
    }

    return $null
}

$standup = Normalize-Time $standup
if (-not $standup) {
    Write-Host 'Invalid standup time.' -ForegroundColor Red
    Start-Sleep -Seconds 2
    return
}

$reflection = Normalize-Time $reflection
if (-not $reflection) {
    Write-Host 'Invalid daily reflection time.' -ForegroundColor Red
    Start-Sleep -Seconds 2
    return
}

$defaultStartup = if ($cfg.showCliOnStartup) { 'Y' } else { 'N' }
$startupAnswer = Read-Host ('Show interactive CLI automatically when Windows starts? (Y/N) [{0}]' -f $defaultStartup)

if ([string]::IsNullOrWhiteSpace($startupAnswer)) {
    $showCli = $cfg.showCliOnStartup
}
else {
    $showCli = $startupAnswer.Trim().ToUpper().StartsWith('Y')
}

$cfg.morningTime = $standup
$cfg.dailyTime = $reflection
$cfg.showCliOnStartup = $showCli

Save-Config $cfg

Write-Host
Write-Host ('Standup:          {0}' -f $standup) -ForegroundColor Green
Write-Host ('Daily reflection: {0}' -f $reflection) -ForegroundColor Green
Write-Host ('Show CLI on startup: {0}' -f $showCli) -ForegroundColor Green
Write-Host
Write-Host 'Settings updated successfully.' -ForegroundColor Green
Start-Sleep -Seconds 2

}



# ======================================================

# AutoHotkey modes

# ======================================================

if ($Command) {


switch ($Command.ToLower()) {

    'daily' {
        Edit-Today
        Stop-Process -Id $PID
    }

    'today' {
        Show-Today
        Read-Host 'Press Enter to close'
        Stop-Process -Id $PID
    }

    'summary' {
        Generate-Summary
        Stop-Process -Id $PID
    }

    'list' {
        List-Months
        Stop-Process -Id $PID
    }

    'history' {
        Show-History $Argument
        Stop-Process -Id $PID
    }

}


}

# ======================================================

# Interactive mode

# ======================================================

while ($true) {

Show-Today

Write-Host
Write-Host "Commands:" -ForegroundColor Yellow

Write-Host "  help        Show detailed help"
Write-Host "  summary     Generate monthly summary"
Write-Host "  list        Browse previous months"
Write-Host "  edit        Edit today's reflection"
Write-Host "  week        Show the last 5 entries"
Write-Host "  set time    Configure reminder settings"
Write-Host
Write-Host "Press Enter to close, or type a command." -ForegroundColor DarkGray

$input = Read-Host '>'

if ([string]::IsNullOrWhiteSpace($input)) {
    Stop-Process -Id $PID
}

switch ($input.ToLower()) {

    'edit' {
        Edit-Today
    }

    'week' {
        Show-Week
    }

    'list' {
        List-Months
    }

    'summary' {
        Generate-Summary
    }

    'set time' {
        Set-Times
    }

    'help' {
        Show-Help
        Read-Host 'Press Enter to continue'
    }

    'exit' {
        Stop-Process -Id $PID
    }

    default {
        Write-Host
        Write-Host ('Unknown command: {0}' -f $input) -ForegroundColor Red
        Write-Host 'Type "help" for available commands.'
        Start-Sleep -Seconds 1
    }

}

}
