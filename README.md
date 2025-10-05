## 1. Executive Summary

This document describes the design and implementation of a lightweight Windows 11 automation that ensures any file saved into a designated folder automatically receives a .png extension if no extension is present.

The solution is intended for environments where image files are frequently generated or copied without extensions (e.g., screenshots or raw image dumps) and manual correction is inefficient. The system operates unattended and performs periodic checks every 5 minutes.

The design prioritizes reliability, maintainability, and minimal system impact while adhering to Windows security and operational best practices.

## 2. Objectives and Scope
### 2.1 Objectives

- Detect and rename files in a specific folder that lack an extension.
- Append .png as the default extension.
- Log each action (renamed or skipped).
- Run automatically every 5 minutes, persisting across system reboots.
- Require no user interaction after deployment.

### 2.2 Scope

✅ In Scope:
- Windows 11 desktop or server environment.
- Single target folder (expandable to multiple via configuration).
- Scheduled Task infrastructure using PowerShell.

🚫 Out of Scope:
- Real-time event monitoring (e.g., via filesystem watcher).
- Non-Windows operating systems.
- GUI interface or multi-folder management beyond configuration edits.

## 3. System Overview

The system consists of:

1. PowerShell Script (AppendPng.ps1)

   Core logic that scans a folder, identifies files without extensions, and renames them with .png.

2. Windows Task Scheduler Job (Append PNG to Extensionless Files)

   A persistent scheduled task that runs the PowerShell script every 5 minutes, with elevated privileges.

3. Log File (append-png.log)

   Plain-text log stored in the target directory to record all rename actions and errors.

## 4. Architecture Diagram

```
 ┌────────────────────┐
 │ Windows Task       │
 │ Scheduler          │
 │ (5-minute trigger) │
 └─────────┬──────────┘
           │
           ▼
 ┌────────────────────────────────┐
 │ PowerShell Script              │
 │  • Validate folder             │
 │  • Enumerate files             │
 │  • If no extension → rename    │
 │  • Log result                  │
 └─────────┬──────────────────────┘
           │
           ▼
 ┌────────────────────────────┐
 │ Target Folder              │
 │  e.g., C:\Images\Incoming  │
 │  append-png.log            │
 └────────────────────────────┘
```

## 5. Technical Design

### 5.1 Core Logic (`AppendPng.ps1`)

1. Enumerates all files in the target folder.  
2. Checks whether the file has an extension.  
3. If not, renames it by appending `.png`.  
4. Logs each rename action or error to `append-png.log`.

### 5.2 Scheduled Task Definition

Two scheduled tasks are created for reliability across Windows versions:

| Task Name | Purpose | Schedule | Action | Run Level |
|------------|----------|-----------|----------|------------|
| **Append PNG - Every5Min** | Renames files every 5 minutes | Every 5 minutes indefinitely | `powershell.exe -NoProfile -ExecutionPolicy Bypass -File "C:\Tools\AppendPng.ps1" -Folder "C:\Target\Folder"` | Highest |
| **Append PNG - AtStartup** | Ensures immediate check after reboot | At system startup | Same as above | Highest |

**Security:**
- Run whether user is logged on or not if you want unattended operation.
- For OneDrive or user-profile folders, the task should run under your user credentials (`/RU` and `/RP`).


## 6. Deployment Plan

### Step 1 — Place Scripts
- Save both scripts in `C:\Tools\`:
  - `C:\Tools\AppendPng.ps1`
  - `C:\Tools\Schedule-AppendPng.ps1` (optional helper)

### Step 2 — Run PowerShell as Administrator

### Step 3 — (Optional) Set Execution Policy
If not already set:
```powershell Set-ExecutionPolicy -Scope CurrentUser RemoteSigned```

### Step 4 — Create Scheduled Tasks

#### Option A — Manual commands (recommended, simple)

```
$Folder = "C:\Users\jacky\OneDrive\文档"
$Action = 'powershell.exe -NoProfile -ExecutionPolicy Bypass -File "C:\Tools\AppendPng.ps1" -Folder "' + $Folder + '"'

schtasks /Create /TN "Append PNG - Every5Min" /SC MINUTE /MO 5 /TR "$Action" /RL HIGHEST
schtasks /Create /TN "Append PNG - AtStartup" /SC ONSTART /TR "$Action" /RL HIGHEST
```
#### Option B — Using the helper script

```powershell.exe -ExecutionPolicy Bypass -File "C:\Tools\Schedule-AppendPng.ps1" -Folder "C:\Users\jacky\OneDrive\文档"```

### Step 5 - Verify the task

```
schtasks /Query /TN "Append PNG - Every5Min"
schtasks /Query /TN "Append PNG - AtStartup"
```

or view the tasks in Task Scheduler

## 7. Testing and Validation

| Test Case                                             | Expected Result                                    | Outcome |
| ----------------------------------------------------- | -------------------------------------------------- | ------- |
| 1. Place a file named `testfile` in the target folder | File is renamed to `testfile.png` within 5 minutes | ✅       |
| 2. Restart the system                                 | Task runs at startup and renames files immediately | ✅       |
| 3. File already has `.png` extension                  | No action taken                                    | ✅       |
| 4. Folder path does not exist                         | Logged as error in `append-png.log`                | ✅       |
| 5. File locked by another process                     | Skipped; retried on next cycle                     | ✅       |

## 8. Logging and Monitoring

- Log file: append-png.log in target folder
- Contains timestamps, actions, and errors
- Example:
```
2025-10-05 09:00:00 INFO  Renamed "img001" -> "img001.png"
2025-10-05 09:05:00 ERROR Access denied for "tmpfile"
```

## 9. Security Considerations

- The PowerShell script runs under the specified user’s context.
- Use /RU and /RP with schtasks to supply credentials if running unattended.
- Avoid storing passwords in plain text if possible. Use a service account if feasible.
- Script runs with ExecutionPolicy Bypass, but only for this command invocation—system policy remains intact.

## 10. Maintenance and Troubleshooting

View Task Status

```
Get-ScheduledTaskInfo -TaskName "Append PNG - Every5Min"
Get-ScheduledTaskInfo -TaskName "Append PNG - AtStartup"
```

Force Immediate Run

```
Start-ScheduledTask -TaskName "Append PNG - Every5Min"
```

Remove Tasks

```
schtasks /Delete /TN "Append PNG - Every5Min" /F
schtasks /Delete /TN "Append PNG - AtStartup" /F
```

## 11. Future Enhancements

- Multi-folder monitoring via config JSON.
- Optional e-mail or Teams alert on rename failures.
- Real-time detection using FileSystemWatcher.
- GUI configuration utility.

## 12. Conclusion

This design provides a robust, maintainable, and secure solution for automatically appending .png extensions to extensionless files in Windows 11. It requires no manual intervention post-deployment, survives reboots, and ensures auditability through logging. The approach balances simplicity with reliability, suitable for both standalone and enterprise desktop use.
