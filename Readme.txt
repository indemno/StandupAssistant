# Standup Assistant

A lightweight local standup and work journal for developers and knowledge workers.

Standup Assistant makes daily standups and end-of-day reflections almost frictionless while automatically building a searchable history of your work. Over time, it becomes a monthly activity log that can be summarized with AI and used during 1:1s, performance reviews, sprint retrospectives, or monthly reporting.

Everything runs **locally on your machine**. No cloud services, accounts, or external data storage.

## Installation

1. Download or clone the repository.
2. Extract all files into a single folder.
3. Run **install.bat**.

The installer will:

* Create a Windows Startup shortcut for Standup Assistant
* Configure the application to run automatically in the background
* Create a desktop shortcut for manually opening the Standup Assistant command interface
* Open the official AutoHotkey website so AutoHotkey v2 can be installed if it is not already available

AutoHotkey is **not included as an executable in the package**.

Official AutoHotkey website:

https://www.autohotkey.com/

After AutoHotkey v2 has been installed, the background scheduler can run automatically with Windows.

## First Run

On first launch, Standup Assistant automatically creates a `config.json` file if one does not already exist.

The default configuration is:

json
{
  "dailyTime": "16:00",
  "morningTime": "08:55",
  "showCliOnStartup": false
}
