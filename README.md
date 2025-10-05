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

## 4. System Overview

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

### 5.1 Core Logic (PowerShell). 

See `AppendPng.ps1`

### 5.2 Scheduled Task Definition

- Task Name: Append PNG to Extensionless Files
- Trigger: Every 5 minutes; repeat indefinitely; also runs at startup.
- Action:
  ```
  powershell.exe -NoProfile -ExecutionPolicy Bypass -File "C:\Tools\AppendPng.ps1" -Folder "C:\Target\Folder"
  ```
- Run Level: Highest privileges.
- Security: “Run whether user is logged on or not.”
- Logon Type: Password stored securely by Windows Credential Manager.

### 5.3 Folder Permissions

- The script executes under the specified service account.
- Read/Write access is required on the target folder for rename and log creation.
- Logging file permissions inherit from the folder ACL.

## 6. Deployment Plan

| Step | Description                                           | Responsible   |
| ---- | ----------------------------------------------------- | ------------- |
| 1    | Copy `AppendPng.ps1` to `C:\Tools`                    | Administrator |
| 2    | Create target directory (e.g., `C:\Images\Incoming`)  | Administrator |
| 3    | Copy `Schedule-AppendPng.ps1` to `C:\Tools`           | Administrator |
| 4    | Create Scheduled Task via provided PowerShell command | Administrator |
| 5    | Validate execution via manual run                     | Administrator |
| 6    | Verify log file entries                               | Administrator |

step 3 command: `powershell.exe -ExecutionPolicy Bypass -File "C:\Tools\Schedule-AppendPng.ps1" -Folder "C:\Target\Folder"`

## 7. Security Considerations
- Execution policy is set to Bypass for the scheduled task only, not system-wide.
- Script requires no internet connectivity and does not modify registry or system files.
- Logging avoids sensitive data and writes only to a known directory.
- Least-privilege principle: ideally runs as a non-administrative service account with folder-level write permission.
- Digital signing of AppendPng.ps1 (optional) is recommended in managed environments.

## 8. Logging and Error Handling

- Log entries are timestamped (ISO 8601 format).
- Both successes and failures are recorded.
- Typical log lines:
```
2025-10-04T13:05:12.102 RENAMED "IMG_001" -> "IMG_001.png"
2025-10-04T13:10:15.887 FAILED "TEMPFILE": The process cannot access the file because it is being used by another process.
```
- Old logs can be rotated monthly using a simple scheduled archive script.

## 9. Testing and Validation

```
| Test ID | Description                               | Expected Result                              |
| ------- | ----------------------------------------- | -------------------------------------------- |
| T1      | Place `testfile` (no extension) in folder | Renamed to `testfile.png`                    |
| T2      | Place `testfile.png`                      | Skipped, log entry indicates skip            |
| T3      | Place multiple duplicates (`a`, `a`, `a`) | Renamed to `a.png`, `a (1).png`, `a (2).png` |
| T4      | File locked during run                    | Error logged, retried on next cycle          |
| T5      | Reboot system                             | Task re-triggers and runs automatically      |
```

## 10. Maintenance and Monitoring

- Monitoring: Review append-png.log weekly for errors.
- Updates: Script can be version-controlled in Git for traceability.
- Task Verification:
```
Get-ScheduledTask -TaskName "Append PNG to Extensionless Files" | Get-ScheduledTaskInfo
```
- Change Control: Modifications (e.g., target folder or interval) must be approved and tested in staging before production rollout.

## 11. Future Enhancements

- Multi-folder monitoring via config JSON.
- Optional e-mail or Teams alert on rename failures.
- Real-time detection using FileSystemWatcher.
- GUI configuration utility.

## 12. Conclusion

This design provides a robust, maintainable, and secure solution for automatically appending .png extensions to extensionless files in Windows 11. It requires no manual intervention post-deployment, survives reboots, and ensures auditability through logging. The approach balances simplicity with reliability, suitable for both standalone and enterprise desktop use.
