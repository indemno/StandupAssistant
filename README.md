# StandupAssistant
Standup Assistant


## Installation

1. Install **AutoHotkey v2**.
2. Place all project files in a single folder.
3. Run `StandupAssistant.ahk` once to verify everything works.
4.Run install.bat or add a shortcut to `StandupAssistant.ahk` in:

%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup

After that, the scheduler starts automatically whenever you log in.



# Standup Assistant

A lightweight terminal-based work journal for developers and knowledge workers.

The goal of Standup Assistant is to make daily standups and end-of-day reflections effortless while automatically building a searchable history of your work. Over time, it becomes a monthly activity log that can be summarized with AI and forwarded to a manager during 1:1s, monthly reviews, or performance discussions.

## Purpose

Standup Assistant supports three simple workflows:

* **Morning standup**: Quickly review what you did yesterday, what you planned, and any blockers before your standup meeting.
* **Daily reflection**: At the end of the workday, answer three short questions about your progress.
* **Monthly summary**: Generate a structured summary file that can be sent to ChatGPT, Claude, GitHub Copilot, or another AI assistant for a concise manager-ready report.

The tool is intentionally minimal and runs entirely locally.

## Features

* Terminal-based interface (PowerShell)
* Automatic daily log files grouped by month
* Editable entries with prefilled values
* Browse historical months
* Configurable reminder times
* AI-friendly monthly summary generation
* Automatic startup via AutoHotkey scheduler

## Project structure

StandupAssistant/
├── StandupAssistant.ps1        # Main application
├── StandupAssistant.ahk        # Scheduler (AutoHotkey)
├── GenerateMonthlySummary.ps1  # Builds monthly summary file
├── config.json                 # Reminder configuration
├── Logs/                       # Monthly standup logs
├── Summaries/                  # Generated summary files
└── README.md

## How it works

### Morning

At the configured **standup time**, AutoHotkey launches:

StandupAssistant.ps1 today

The application displays today's most recent entry and exits after confirmation.

### End of day

At the configured **daily reflection time**, AutoHotkey launches:

StandupAssistant.ps1 daily

The application goes directly into the three reflection questions:

* What did you do today?
* Plan for tomorrow?
* Any blockers?

Existing values are prefilled, so pressing **Enter** keeps the current value. After saving, the window closes automatically.

### Manual use

Running `StandupAssistant.ps1` directly opens the interactive interface.

Example:

========================================
Standup Assistant
=================

2026-08-11

What I did:

* Finished Bolagsverket integration

Plan tomorrow:

* Continue investigation

Blockers:

* Mail environment still broken

---

Commands:
edit        Edit today's reflection
list        Browse previous months
summary     Generate monthly summary
set time    Configure reminder times
help        Show detailed help
exit        Close the application

## Commands

### edit

Edit today's reflection. Existing values are prefilled.

### list

Lists available months and lets you choose one by number or `YYYY-MM`.

### summary

Runs `GenerateMonthlySummary.ps1` and creates a summary file for the current month.

### set time

Configure both reminder times interactively:

* **Time for standup**
* **Time for daily reflection**

Values are stored in `config.json`.

### help

Displays detailed documentation and usage information.

### exit

Closes the application.

## Configuration

Reminder times are stored in `config.json`.

Example:

{
"dailyTime": "16:00",
"morningTime": "08:55"
}

The AutoHotkey scheduler reads this file automatically.

## Monthly summaries

Running `summary` generates a file in the `Summaries` folder.

The generated file contains:

* Metadata
* Number of logged workdays
* An AI prompt
* All standup entries for the selected month

The file can be pasted directly into ChatGPT, Claude, GitHub Copilot, or another AI assistant to produce a manager-ready monthly report.

## Typical workflow

Morning:

* Read today's log before standup

Afternoon:

* Complete the daily reflection

End of month:

* Generate a summary
* Send it to an AI assistant
* Forward the result to your manager

## Philosophy

This project is intentionally simple.

It is not a task manager, ticket tracker, or project management system.

It is a **low-friction work journal** designed to capture what you actually accomplished each day and turn that history into useful documentation with minimal effort.

Author
Created by Christofer Malmberg.
This started as a personal developer productivity tool and evolved into a lightweight local standup and reflection assistant. Feel free to modify, extend, and share it internally.
