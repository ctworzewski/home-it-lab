# Windows Update Automation with PowerShell & n8n

> Automated Windows Update checking, installation, reboot detection, and
> reporting using PowerShell, Windows Task Scheduler, and n8n.

![PowerShell](https://img.shields.io/badge/PowerShell-Automation-5391FE)
![Windows](https://img.shields.io/badge/Windows-11-0078D4)
![n8n](https://img.shields.io/badge/n8n-Workflow_Automation-FF6D5A)
![REST API](https://img.shields.io/badge/REST-API-009688)
![JSON](https://img.shields.io/badge/Data-JSON-555555)

## Overview

This project is part of my **Home IT Lab** and demonstrates an
end-to-end Windows Update automation workflow.

Windows Task Scheduler runs PowerShell scripts with elevated privileges.
The scripts interact with the Windows Update COM API and send execution
results as JSON to an n8n webhook. n8n evaluates the result and sends
the appropriate email notification.

The project contains two workflows:

-   **CHECK** --- detects available Windows updates and reports them to
    n8n.
-   **INSTALL** --- downloads and installs updates, checks the result
    and reboot requirement, then reports the outcome to n8n.

## Architecture

``` text
Windows Task Scheduler
          |
          v
      PowerShell
          |
          v
 Windows Update COM API
          |
          | HTTPS POST / JSON
          v
      n8n Webhook
          |
          v
     Status check
       /     \
      /       \
 SUCCESS     FAILED
      \       /
       \     /
    Email report
```

## How it works

1.  **Windows Task Scheduler** starts the PowerShell script
    automatically with elevated privileges.
2.  **PowerShell** checks or installs updates through the Windows Update
    COM API.
3.  The script sends the execution result to **n8n** using an HTTPS
    webhook and JSON payload.
4.  **n8n** evaluates the result and sends an email report. The INSTALL
    workflow also detects whether Windows requires a reboot.

------------------------------------------------------------------------

## Windows Update - CHECK

The CHECK workflow is responsible for monitoring available Windows
updates.

The PowerShell script searches for pending updates, builds a JSON report
containing the host, date, update count and update details, and sends it
to n8n. The workflow can then notify the administrator when updates are
available.

### n8n workflow

![Windows Update CHECK workflow](screenshots/WindowsUpdate-CHECK.png)

------------------------------------------------------------------------

## Windows Update - INSTALL

The INSTALL workflow performs the update process and reports its result.

The PowerShell script:

-   searches for available updates,
-   accepts required EULAs,
-   downloads and installs updates,
-   evaluates `ResultCode` and per-update `HRESULT`,
-   detects whether a reboot is required,
-   sends the final result to n8n.

n8n routes the report to the appropriate **SUCCESS** or **FAILED** email
path.

### n8n workflow

![Windows Update INSTALL
workflow](screenshots/WindowsUpdate-INSTALL.png)

------------------------------------------------------------------------

## Example webhook payload

PowerShell sends the result to n8n as an HTTP POST request with
`Content-Type: application/json`.

``` json
{
  "host": "WINDOWS-CLIENT",
  "date": "2026-09-15 09:35:08",
  "status": "SUCCESS",
  "found": 2,
  "installed": 2,
  "resultCode": 2,
  "rebootRequired": true,
  "error": "",
  "updates": []
}
```

This separation keeps system-level operations in PowerShell while n8n
handles workflow logic and notifications.

## Scheduled execution

The scripts can run unattended through **Windows Task Scheduler**.

Example action:

``` powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "C:\Scripts\WindowsUpdate-Install.ps1"
```

The installation task must run with:

> **Run with highest privileges**

Elevated privileges are required for Windows Update installation
operations.

## Repository structure

``` text
windows-update-automation/
├── scripts/
│   ├── WindowsUpdate-Check.ps1
│   └── WindowsUpdate-Install.ps1
├── workflows/
│   ├── windows-update-check.json
│   └── windows-update-install.json
├── screenshots/
│   ├── WindowsUpdate-CHECK.png
│   └── WindowsUpdate-INSTALL.png
└── README.md
```

-   `scripts/` --- PowerShell scripts for Windows Update operations and
    n8n reporting.
-   `workflows/` --- exported n8n workflows for CHECK and INSTALL.
-   `screenshots/` --- workflow screenshots used in this documentation.

## Security

The public version of this project should not contain
environment-specific secrets or credentials.

Before publishing, replace or remove:

-   real webhook URLs,
-   email addresses,
-   credentials and passwords,
-   API tokens,
-   private IP addresses,
-   other environment-specific secrets.

Example placeholder:

``` powershell
$WebhookUrl = "https://n8n.example.com/webhook/windows-update-install"
```

SMTP and other service credentials should be stored in **n8n
Credentials**, not directly in scripts or workflow definitions.

## Future improvements

Possible next steps:

-   multi-host Windows update management,
-   maintenance windows,
-   update history and centralized reporting,
-   active-user-aware reboot handling,
-   centralized update status dashboard,
-   Zabbix integration,
-   Wazuh integration,
-   automatic error analysis and remediation.

## Project goal

The goal of this Home IT Lab project is to combine traditional Windows
administration with practical automation:

**PowerShell + Windows Update + Task Scheduler + REST/Webhooks + n8n**

It provides hands-on practice with Windows administration, API-style
communication between systems, workflow automation, error handling, and
operational reporting.