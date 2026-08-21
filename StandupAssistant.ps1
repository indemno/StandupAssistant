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

# ============================================
# Create folders
# ============================================

if (-not (Test-Path $LogsDir)) {
    New-Item -ItemType Directory -Path $LogsDir | Out-Null
}

if (-not (Test-Path $SummariesDir)) {
    New-Item -ItemType Directory -Path $SummariesDir | Out-Null
}

# ============================================
# Create default config
# ============================================

if (-not (Test-Path $ConfigFile)) {
    @{
        dailyTime   = '16:00'
        morningTime = '08:55'
        showCliOnStartup = $false
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

# ============================================
# Help
# ============================================

function Show-Help {
    Show-Header

    Write-Host 'Purpose' -ForegroundColor Cyan
    Write-Host '-------'
    Write-Host 'Standup Assistant is a lightweight work journal for developers and knowledge workers.'
    Write-Host 'It keeps a daily record of planned work, completed work, plans for tomorrow, and blockers.'
    Write-Host
    Write-Host 'AutoHotkey launches this script automatically:'
    Write-Host '  - Standup time      : asks for today''s plan'
    Write-Host '  - Daily reflection  : shows today''s plan and opens the reflection questions'
    Write-Host
    Write-Host 'All entries are stored in monthly log files under the Logs folder.'
    Write-Host 'Monthly summaries can be generated and sent to an AI assistant for manager updates.'
    Write-Host
    Write-Host 'Commands' -ForegroundColor Cyan
    Write-Host '--------'
    Write-Host 'edit        Edit today''s reflection (values are prefilled)'
    Write-Host 'list        List available months and choose one'
    Write-Host 'summary     Generate a monthly summary file'
    Write-Host 'set time    Configure standup and daily reflection times'
    Write-Host 'help        Show this help screen'
    Write-Host
}

# ============================================
# Get today's block
# ============================================

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

    $nextIndex = $content.IndexOf(
        '========================================',
        $dateIndex + $dateText.Length
    )

    if ($nextIndex -gt $dateIndex) {
        return @{
            Start      = $startIndex
            End        = $nextIndex
            Text       = $content.Substring($startIndex, $nextIndex - $startIndex).Trim()
            FullContent = $content
        }
    }
    else {
        return @{
            Start      = $startIndex
            End        = $content.Length
            Text       = $content.Substring($startIndex).Trim()
            FullContent = $content
        }
    }
}

function Get-TodayBlock {
    return Get-DayBlock (Get-Date)
}

# ============================================
# Extract a value from an entry
# ============================================

function Get-EntryValue {
    param(
        [string]$Text,
        [string]$Field
    )

    if ([string]::IsNullOrWhiteSpace($Text)) {
        return ''
    }

    $lines = $Text -split "`r?`n"

    for ($i = 0; $i -lt $lines.Count; $i++) {
        if ($lines[$i].Trim() -eq $Field) {
            if ($i + 1 -lt $lines.Count) {
                return $lines[$i + 1].TrimStart('-',' ')
            }

            return ''
        }
    }

    return ''
}

# ============================================
# Show week
# ============================================

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

    # Oldest first, latest last.
    # This means scrolling upwards goes backwards through the week.
    foreach ($entry in $entries | Sort-Object Date) {
        Write-Host $entry.Text
        Write-Host
        Write-Host "----------------------------------------" -ForegroundColor DarkGray
        Write-Host
    }

    Read-Host "Press Enter to return"
}

# ============================================
# Morning plan
# ============================================

function Set-PlanToday {
    Show-Header

    $today = Get-Date

    # Find previous working day
    $previousWorkday = $today.AddDays(-1)

    while ($previousWorkday.DayOfWeek -eq [DayOfWeek]::Saturday -or
           $previousWorkday.DayOfWeek -eq [DayOfWeek]::Sunday) {

        $previousWorkday = $previousWorkday.AddDays(-1)
    }

    $yesterday = Get-DayBlock $previousWorkday
    $todayBlock = Get-TodayBlock

    # Show previous workday
    Write-Host ('Previous workday ({0})' -f $previousWorkday.ToString('yyyy-MM-dd')) -ForegroundColor Cyan
    Write-Host

    if ($yesterday) {
        Write-Host $yesterday.Text
    }
    else {
        Write-Host 'No entry for previous workday.' -ForegroundColor DarkGray
    }

    Write-Host
    Write-Host '----------------------------------------' -ForegroundColor DarkGray
    Write-Host

    # Get existing plan for today, if there is one
    $planToday = ''

    if ($todayBlock) {
        $planToday = Get-EntryValue $todayBlock.Text 'Plan today:'
    }

    # Ask for today's plan
    Write-Host "Good morning!" -ForegroundColor Green
    Write-Host
    Write-Host "What do you plan to do today?" -ForegroundColor Cyan
    Write-Host

    $newPlanToday = Read-EditableInput 'Plan for today?' $planToday

    # Preserve any existing fields from today
    $done = ''
    $planTomorrow = ''
    $blockers = ''

    if ($todayBlock) {
        $done = Get-EntryValue $todayBlock.Text 'What I did:'
        $planTomorrow = Get-EntryValue $todayBlock.Text 'Plan tomorrow:'
        $blockers = Get-EntryValue $todayBlock.Text 'Blockers:'
    }

    $date = $today.ToString('yyyy-MM-dd')
    $logFile = Get-CurrentLogFile

    $newEntry = @"
========================================
$date

Plan today:
- $newPlanToday

What I did:
- $done

Plan tomorrow:
- $planTomorrow

Blockers:
- $blockers

"@

    if (-not (Test-Path $logFile)) {
        Set-Content -Path $logFile -Value $newEntry -Encoding UTF8
    }
    elseif ($todayBlock) {
        $before = $todayBlock.FullContent.Substring(0, $todayBlock.Start)
        $after = $todayBlock.FullContent.Substring($todayBlock.End)

        $updated = $before + $newEntry + $after

        Set-Content -Path $logFile -Value $updated -Encoding UTF8
    }
    else {
        Add-Content -Path $logFile -Value ("`n" + $newEntry) -Encoding UTF8
    }

    Write-Host
    Write-Host 'Plan saved successfully.' -ForegroundColor Green
    Write-Host

    Start-Sleep -Seconds 1
}

# ============================================
# Show today
# ============================================

function Show-Today {
    Show-Header

    $today = Get-Date

    # Find previous working day
    $previousWorkday = $today.AddDays(-1)

    while ($previousWorkday.DayOfWeek -eq [DayOfWeek]::Saturday -or
           $previousWorkday.DayOfWeek -eq [DayOfWeek]::Sunday) {

        $previousWorkday = $previousWorkday.AddDays(-1)
    }

    $yesterday = Get-DayBlock $previousWorkday
    $todayBlock = Get-DayBlock $today

    Write-Host ('Previous workday ({0})' -f $previousWorkday.ToString('yyyy-MM-dd')) -ForegroundColor Cyan
    Write-Host

    if ($yesterday) {
        Write-Host $yesterday.Text
    }
    else {
        Write-Host 'No entry for previous workday.' -ForegroundColor DarkGray
    }

    Write-Host
    Write-Host '----------------------------------------' -ForegroundColor DarkGray
    Write-Host

    Write-Host ('Today ({0})' -f $today.ToString('yyyy-MM-dd')) -ForegroundColor Green
    Write-Host

    if ($todayBlock) {
        Write-Host $todayBlock.Text
    }
    else {
        Write-Host 'No entry for today yet.' -ForegroundColor DarkGray
    }

    Write-Host
    Write-Host '----------------------------------------' -ForegroundColor DarkGray
    Write-Host
}

function Read-EditableInput {
    param(
        [string]$Prompt,
        [string]$DefaultValue = ''
    )

    $result = Read-Host $Prompt

    if ([string]::IsNullOrWhiteSpace($result)) {
        return $DefaultValue
    }

    return $result
}

# ============================================
# Open log for manual editing
# ============================================

function Open-Log {
    $logFile = Get-CurrentLogFile

    if (-not (Test-Path $logFile)) {
        New-Item -ItemType File -Path $logFile -Force | Out-Null
    }

    # Open the log in Notepad.
    $process = Start-Process notepad.exe -ArgumentList "`"$logFile`"" -PassThru

    # Wait for Notepad to create its main window.
    $process.WaitForInputIdle() | Out-Null
    Start-Sleep -Milliseconds 300

    # Send Ctrl+End to move to the end of the document.
    Add-Type -AssemblyName System.Windows.Forms
    [System.Windows.Forms.SendKeys]::SendWait('^({END})')
}

# ============================================
# Daily reflection
# ============================================

function Edit-Today {
    param(
        [bool]$AllowPlanEdit = $true
    )

    Show-Header

    $logFile = Get-CurrentLogFile
    $date = Get-Date -Format 'yyyy-MM-dd'
    $block = Get-TodayBlock

    $planToday = ''
    $done = ''
    $plan = ''
    $blockers = ''

    if ($block) {
        $planToday = Get-EntryValue $block.Text 'Plan today:'
        $done = Get-EntryValue $block.Text 'What I did:'
        $plan = Get-EntryValue $block.Text 'Plan tomorrow:'
        $blockers = Get-EntryValue $block.Text 'Blockers:'
    }

    # Plan today
    if ($AllowPlanEdit) {
        $newPlanToday = Read-EditableInput 'Plan for today?' $planToday
    }
    else {
        Write-Host 'Your plan for today:' -ForegroundColor Cyan
        Write-Host

        if ([string]::IsNullOrWhiteSpace($planToday)) {
            Write-Host 'No plan recorded for today.' -ForegroundColor DarkGray
        }
        else {
            Write-Host "- $planToday"
        }

        Write-Host
        Write-Host '----------------------------------------' -ForegroundColor DarkGray
        Write-Host

        $newPlanToday = $planToday
    }

    # Daily reflection fields
    $newDone = Read-EditableInput 'What did you do today?' $done

    $newPlan = Read-EditableInput 'Plan for tomorrow?' $plan

    $newBlockers = Read-EditableInput 'Any blockers?' $blockers

    $newEntry = @"
========================================
$date

Plan today:
- $newPlanToday

What I did:
- $newDone

Plan tomorrow:
- $newPlan

Blockers:
- $newBlockers

"@

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

# ============================================
# History
# ============================================

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

# ============================================
# List months
# ============================================

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

    if ($selection -match '^\d+$') {
        $index = [int]$selection - 1

        if ($index -ge 0 -and $index -lt $months.Count) {
            Show-History $months[$index]
            return
        }
    }

    Show-History $selection
}

# ============================================
# Generate summary
# ============================================

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

# ============================================
# Configure times
# ============================================

function Set-Times {
    Show-Header

    $cfg = Get-Config

    Write-Host 'Configure reminder settings' -ForegroundColor Green
    Write-Host

    $standup = Read-Host ('Time for reminder and morningplan [{0}]' -f $cfg.morningTime)

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

            if ($h -ge 0 -and $h -le 23 -and
                $m -ge 0 -and $m -le 59) {

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

    $startupAnswer = Read-Host (
        'Show interactive CLI automatically when Windows starts? (Y/N) [{0}]' -f $defaultStartup
    )

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
            Edit-Today $false
            Stop-Process -Id $PID
        }

        'today' {
            Set-PlanToday
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
    Write-Host "Commands:" -ForegroundColor Green

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
            Open-Log
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