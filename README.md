# Standup Assistant

A lightweight local standup and work journal for developers and knowledge workers.

Standup Assistant makes daily standups and end-of-day reflections almost frictionless while automatically building a searchable history of your work. Over time, it becomes a monthly activity log that can be summarized with AI and used during 1:1s, performance reviews, sprint retrospectives, or monthly reporting.

Everything runs **locally on your machine**. No cloud services, accounts, or external data storage.

## Installation

1. Download or clone the repository.
2. Extract all files into a single folder.
3. Run **install.bat**.

The installer will:

* Install **AutoHotkey v2** (included in the package) if necessary
* Create a Windows Startup shortcut
* Start Standup Assistant in the background

## Purpose

Standup Assistant is built around three simple workflows:

* **Morning standup**: Review yesterday and today before your standup meeting.
* **Daily reflection**: Capture what you accomplished, what comes next, and any blockers.
* **Monthly summary**: Generate an AI-friendly summary file that can be turned into a concise manager-ready report.

The philosophy is simple: spend less than a minute writing each day and let the history become useful documentation automatically.

## Features

* Local PowerShell terminal interface
* Automatic monthly log files
* Editable daily entries with prefilled values
* View **today and yesterday** at startup
* View the **last five workdays**
* Browse historical months
* Configurable reminder times
* Optional CLI launch on Windows startup
* AI-friendly monthly summary generation
* Background scheduler using AutoHotkey

## Project Structure

StandupAssistant/
├── StandupAssistant.ps1        # Main application
├── StandupAssistant.ahk        # Background scheduler
├── GenerateMonthlySummary.ps1  # Builds monthly summary files
├── config.json                 # Reminder configuration
├── Logs/                       # Monthly work logs
├── Summaries/                  # Generated summary files
├── install.bat                 # Installer
├── uninstall.bat               # Removes startup integration
└── README.md

## How It Works

### Morning

At the configured **standup time**, AutoHotkey launches:

StandupAssistant.ps1 today

The application displays:

* Yesterday's entry
* Today's entry

and then closes after confirmation.

### End of Day

At the configured **daily reflection time**, AutoHotkey launches:

StandupAssistant.ps1 daily

You are prompted with three questions:

* What did you do today?
* Plan for tomorrow?
* Any blockers?

Existing values are prefilled, so pressing **Enter** keeps the current value. After saving, the window closes automatically.

### Manual Use

Running `StandupAssistant.ps1` directly opens the interactive interface.

Example:

========================================
Standup Assistant
=================

Yesterday (2026-08-12)
...

---

Today (2026-08-13)
...

---

Commands:
edit        Edit today's reflection
week        Show the last five workdays
list        Browse previous months
summary     Generate a monthly summary
set time    Configure reminder settings
help        Show detailed help

Press Enter to close, or type a command.

## Commands

### edit

Edit today's reflection. Existing values are prefilled.

### week

Displays the **five most recent workday entries**, automatically skipping weekends.

### list

Browse available months and open any previous month by number or `YYYY-MM`.

### summary

Generates a monthly summary file using `GenerateMonthlySummary.ps1`.

### set time

Configure:

* Standup reminder time
* Daily reflection reminder time
* Whether the interactive CLI should open automatically when Windows starts

Settings are stored in `config.json`.

### help

Displays detailed usage information.

## Configuration

Reminder and startup settings are stored in `config.json`.

Example:

{
"dailyTime": "16:00",
"morningTime": "08:55",
"showCliOnStartup": false
}

The AutoHotkey scheduler reads this file automatically.

## Monthly Summaries

Running `summary` generates a file in the `Summaries` folder.

The file contains:

* Metadata
* Number of logged workdays
* An AI prompt
* All entries for the selected month

It can be pasted directly into ChatGPT, Claude, GitHub Copilot, or another AI assistant to generate a structured monthly report.

## Typical Workflow

**Morning**

* Review yesterday and today before standup

**Afternoon**

* Complete the daily reflection

**End of month**

* Generate a summary
* Paste it into an AI assistant
* Send the resulting report to your manager

## Privacy

Standup Assistant stores everything **locally** on your computer.

No data is uploaded, synchronized, or shared automatically, making it suitable for internal company work where privacy and ownership of notes are important.

## Philosophy

Standup Assistant is intentionally minimal.

It is **not** a task manager, issue tracker, or project management system.

It is a **low-friction work journal** designed to capture what you actually accomplished each day and turn that history into useful documentation with almost no maintenance.

## Author

Created by **Christofer Malmberg**.

Originally built as a personal developer productivity tool and gradually evolved into a lightweight local standup and reflection assistant. Feel free to modify, extend, and share it internally.
