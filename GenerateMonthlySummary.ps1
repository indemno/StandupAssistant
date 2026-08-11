$ErrorActionPreference = "Stop"

try {
    $logsDir = Join-Path $PSScriptRoot "Logs"
    $summariesDir = Join-Path $PSScriptRoot "Summaries"

    if (-not (Test-Path $summariesDir)) {
        New-Item -ItemType Directory -Path $summariesDir | Out-Null
    }

    $month = Get-Date -Format "yyyy-MM"

    $logFile = Join-Path $logsDir ("standup-{0}.txt" -f $month)
    $summaryFile = Join-Path $summariesDir ("summary-{0}.txt" -f $month)

    if (-not (Test-Path $logFile)) {
        throw "Log file not found: $logFile"
    }

    # Read the standup log as UTF-8
    $content = [System.IO.File]::ReadAllText(
        $logFile,
        [System.Text.Encoding]::UTF8
    )

    $entryCount = ([regex]::Matches($content, '(?m)^\d{4}-\d{2}-\d{2}$')).Count

    $summary = @"
Monthly summary $month

Metadata
- Generated: $(Get-Date -Format "yyyy-MM-dd HH:mm")
- Source: $(Split-Path $logFile -Leaf)
- Logged days: $entryCount

--------------------------------------------------

AI PROMPT

You are a senior engineering manager at a Swedish software company.

Summarize the developer's month based on the standup logs below.

Write the entire response in Swedish.

Return the following sections:

1. Executive summary for a manager (5 to 7 sentences)
2. Salary review version focusing on ownership, initiative, impact, and deliveries
3. Key deliveries
4. Recurring work areas
5. Blockers and risks
6. Suggested goals for next month
7. A short bullet list suitable for a development review

Use a professional but natural Swedish tone.

--------------------------------------------------

Standup logs

$content

"@

    # Save as UTF-8 with BOM
    $utf8 = New-Object System.Text.UTF8Encoding($true)
    [System.IO.File]::WriteAllText($summaryFile, $summary, $utf8)

    Write-Host "Summary created:"
    Write-Host $summaryFile

    Invoke-Item $summaryFile
}
catch {
    Write-Host "ERROR"
    Write-Host $_.Exception.Message
}

Read-Host "Press Enter to exit"