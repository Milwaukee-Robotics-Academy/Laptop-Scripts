# Milwaukee Robotics Academy — Laptop Scripts

A comprehensive suite of PowerShell automation scripts designed for preparing, maintaining, configuring, and updating **FIRST Robotics Competition (FRC)** programming and Driver Station laptops.

---

## Table of Contents

- [Overview](#overview)
- [System Requirements & Prerequisites](#system-requirements--prerequisites)
- [Quick Start](#quick-start)
- [Primary Workflow Scripts](#primary-workflow-scripts)
  - [Laptop-Reset.ps1](#laptop-resetps1)
  - [frc-latest-download.ps1](#frc-latest-downloadps1)
  - [frc-latest-install.ps1](#frc-latest-installps1)
  - [frc-cleanup-previous.ps1](#frc-cleanup-previousps1)
  - [driverstation-setup.ps1](#driverstation-setupps1)
  - [driverstation-event-end.ps1](#driverstation-event-endps1)
  - [create-exes.ps1](#create-exesps1)
- [Common Lifecycles & Scenarios](#common-lifecycles--scenarios)
- [Repository Structure](#repository-structure)
- [Utility Scripts (`util/`)](#utility-scripts-util)
- [Bootstrap Installer (`LaptopInstaller/`)](#bootstrap-installer-laptopinstaller)
- [Customization & Configuration](#customization--configuration)

---

## Overview

Setting up and managing laptops for an FRC team involves recurring, complex configuration tasks: installing large vendor software suites (WPILib, NI Game Tools, Driver Station, vendor libraries), configuring static networking for competition fields, cleaning up legacy software between seasons, debloating Windows, and preventing student/mentor credential bleed across shared laptops.

This repository automates these workflows with modular, self-documenting PowerShell scripts that can run directly in a PowerShell console or be compiled into standalone `.exe` binaries using [PS2EXE](https://github.com/MScholtes/PS2EXE).

---

## System Requirements & Prerequisites

- **Operating System:** Windows 10 or Windows 11 (64-bit).
- **PowerShell:** Windows PowerShell 5.1 (built into Windows) or PowerShell 7+.
- **Privileges:** Administrator privileges are required for system-level configurations (`#Requires -RunAsAdministrator`). Run PowerShell as an Administrator.
- **Internet Access:** Required for WinGet package installation and downloading GitHub releases.
- **Optional Module:** `ps2exe` (only needed if compiling `.ps1` files to `.exe`):
  ```powershell
  Install-Module ps2exe -Scope CurrentUser
  ```

---

## Quick Start

### Option 1: Git Clone
Open an elevated (Administrator) PowerShell terminal and run:
```powershell
git clone https://github.com/Milwaukee-Robotics-Academy/Laptop-Scripts.git C:\Laptop-Scripts
cd C:\Laptop-Scripts
```

### Option 2: Bootstrap Executable
For fresh machines lacking Git, run `LaptopInstaller\LoadScripts.exe` (or execute `LaptopInstaller\loadscripts.ps1`), which bundles Portable Git and automatically clones this repository into `C:\Laptop-Scripts`.

---

## Primary Workflow Scripts

### [Laptop-Reset.ps1](file:///Users/erik/Documents/Laptop-Scripts/Laptop-Reset.ps1)
**Purpose:** Restores a laptop to a clean, standardized baseline state for team members and students.
- **What it does:**
  1. Clears stored GitHub credentials from Windows Credential Manager to prevent account bleed across users.
  2. Resets the Windows network stack (Winsock, IP stack, DNS, DHCP) and stages the team Wi-Fi network profile.
  3. Debloats Windows by removing preinstalled OEM and consumer Microsoft Store (`Appx`) apps.
  4. Installs core robotics utilities and diagnostic tools via WinGet.
  5. Configures developer-friendly defaults for Angry IP Scanner, Notepad++, and Windows Explorer.
- **Usage:**
  ```powershell
  .\Laptop-Reset.ps1
  ```

---

### [frc-latest-download.ps1](file:///Users/erik/Documents/Laptop-Scripts/frc-latest-download.ps1)
**Purpose:** Automatically queries GitHub Releases for the latest FRC software packages and downloads them locally.
- **What it does:**
  1. Queries the GitHub API for latest releases (supporting pre-release/beta versions) for:
     - **WPILib:** Resolves download links for the large Windows-x64 `.iso` installer.
     - **FRC Driver Station:** Resolves browser download URLs for the Windows executable installer.
  2. Creates the target installer directory (`C:\FRC_Latest_Installers`) if it does not already exist.
  3. Downloads each package using `curl.exe` with redirect support and proxy bypass.
- **Parameters:**
  - `-DownloadDir`: Destination folder (defaults to `C:\FRC_Latest_Installers`).
  - `-IncludePrereleases`: Boolean flag to include beta/pre-release builds (defaults to `$true`).
- **Usage:**
  ```powershell
  .\frc-latest-download.ps1
  # Or with custom options:
  .\frc-latest-download.ps1 -DownloadDir "D:\Installers" -IncludePrereleases $false
  ```

---

### [frc-latest-install.ps1](file:///Users/erik/Documents/Laptop-Scripts/frc-latest-install.ps1)
**Purpose:** Automated installation pipeline for the latest FRC software suite.
- **What it does:**
  1. Installs base developer and diagnostic utilities via WinGet (`install-base-apps.ps1`).
  2. Mounts the downloaded WPILib `.iso` image and launches `WPILibInstaller.exe` with `-Wait`.
  3. Executes all standalone installers (`.exe` and `.msi`) found in the installer directory (e.g., Driver Station, REV Hardware Client).
  4. Configures Angry IP Scanner default settings for FRC subnets.
  5. Locates `code.cmd` and installs recommended VS Code extensions (Java pack, Python, PowerShell, GitHub Repositories/Codespaces).
  6. Disables Windows Defender Firewall profiles so mDNS/Bonjour discovery works seamlessly in pit environments.
- **Parameters:**
  - `-InstallerDir`: Directory containing downloaded installer media (defaults to `C:\FRC_Latest_Installers`).
- **Usage:**
  ```powershell
  .\frc-latest-install.ps1
  ```

---

### [frc-cleanup-previous.ps1](file:///Users/erik/Documents/Laptop-Scripts/frc-cleanup-previous.ps1)
**Purpose:** Cleans up and uninstalls previous-season FRC software to prepare laptops for a new season.
- **What it does:**
  1. Deletes the public WPILib directory for the given year (`C:\Users\Public\wpilib\<Year>`).
  2. Removes year-specific FRC desktop shortcuts and tool folders from both Public and User desktops.
  3. Removes WPILib entries from both `Machine` and `User` `PATH` environment variables.
  4. Uninstalls National Instruments FRC Game Tools and LabVIEW packages via NI Package Manager (`nipkg.exe`).
  5. Scans Windows Registry (32-bit and 64-bit) for season-specific vendor tools (PathPlanner, AdvantageScope, CTRE Phoenix, REV Hardware Client) and runs silent uninstallers.
- **Parameters:**
  - `-Year` *(Mandatory)*: The 4-digit FRC season year to clean up (e.g., `2026`).
- **Usage:**
  ```powershell
  .\frc-cleanup-previous.ps1 -Year 2026
  ```

---

### [driverstation-setup.ps1](file:///Users/erik/Documents/Laptop-Scripts/driverstation-setup.ps1)
**Purpose:** Configures a laptop for competition match play at an FRC event.
- **What it does:**
  1. Accepts your team number and automatically computes the FRC static IP address (`10.TE.AM.5`, gateway `10.TE.AM.4`, subnet mask `255.0.0.0`).
  2. Disables the Windows Update service (`wuauserv`) to prevent mid-match background restarts.
  3. Disables Wi-Fi and Bluetooth network adapters to comply with FIRST field regulations and prevent wireless interference.
  4. Assigns the static IP to the active physical Ethernet adapter and disables IPv6.
  5. Disables USB power saving and selective suspend (`powercfg`).
  6. Disables Windows Defender Firewall across all profiles to prevent communication drops with the field and robot.
- **Parameters:**
  - `-TeamNumber` *(Mandatory)*: 1 to 5 digit FRC team number (e.g. `254`, `1114`, `10254`).
- **Usage:**
  ```powershell
  .\driverstation-setup.ps1 -TeamNumber 254
  ```

---

### [driverstation-event-end.ps1](file:///Users/erik/Documents/Laptop-Scripts/driverstation-event-end.ps1)
**Purpose:** Restores a Driver Station laptop to standard workshop/home operation after a competition event concludes.
- **What it does:**
  1. Re-enables the Windows Update service (`wuauserv`) and sets startup to Automatic.
  2. Re-enables all Wi-Fi and Bluetooth network adapters.
  3. Reverts the Ethernet adapter from the competition static IP back to automatic DHCP.
- **Usage:**
  ```powershell
  .\driverstation-event-end.ps1
  ```

---

### [create-exes.ps1](file:///Users/erik/Documents/Laptop-Scripts/create-exes.ps1)
**Purpose:** Compiles all `.ps1` PowerShell scripts in the workspace into standalone Windows `.exe` binaries using `PS2EXE`.
- **What it does:**
  - Recursively finds all `.ps1` files in the repository.
  - Automatically excludes itself (`create-exes.ps1`).
  - Converts each script into a matching `.exe` in the same directory.
- **Prerequisites:** `Install-Module ps2exe -Scope CurrentUser`
- **Usage:**
  ```powershell
  .\create-exes.ps1
  ```

---

## Common Lifecycles & Scenarios

### Scenario 1: Pre-Season / Annual Laptop Refresh
```powershell
# 1. Clean up the previous season's software (e.g. 2026)
.\frc-cleanup-previous.ps1 -Year 2026

# 2. Reset the system baseline and install developer utilities
.\Laptop-Reset.ps1

# 3. Download the latest season installers
.\frc-latest-download.ps1

# 4. Install the new season FRC suite, WPILib, and tools
.\frc-latest-install.ps1

# 5. Reboot the laptop
Restart-Computer
```

### Scenario 2: Competition Event Preparation
```powershell
# In the pit before match 1 (connect Ethernet cable first)
.\driverstation-setup.ps1 -TeamNumber <YOUR_TEAM_NUMBER>

# After the competition ends (restores Wi-Fi, DHCP, and Windows updates)
.\driverstation-event-end.ps1
```

---

## Repository Structure

```
Laptop-Scripts/
├── Laptop-Reset.ps1                 # Master baseline reset & setup script
├── frc-latest-download.ps1          # GitHub release downloader (WPILib, Driver Station)
├── frc-latest-install.ps1           # Automated FRC software & extensions installer
├── frc-cleanup-previous.ps1         # Season software uninstaller (WPILib, NI, vendor tools)
├── driverstation-setup.ps1          # Competition Driver Station configuration (Static IP, optimizations)
├── driverstation-event-end.ps1      # Post-event recovery script (restores DHCP, Wi-Fi, updates)
├── create-exes.ps1                  # Compiles .ps1 scripts to standalone .exe binaries
├── README.md                        # Documentation and usage guide
│
├── LaptopInstaller/                 # Self-contained bootstrap installer
│   ├── PortableGit.exe              # Self-extracting archive of Git
│   ├── loadscripts.ps1              # Bootstrap script to extract Git & clone this repo
│   └── LoadScripts.exe              # Compiled bootstrap executable
│
└── util/                            # Modular sub-scripts and configuration helpers
    ├── app-default-settings.ps1     # Master coordinator for application defaults
    ├── angry-ip-scanner-default-settings.ps1 # Configures Angry IP Scanner FRC defaults
    ├── notepadplusplus-dont-remember-last-session.ps1 # Disables Notepad++ session memory
    ├── explorer-settings.ps1        # Enables file extensions, hidden files, and full paths
    ├── install-base-apps.ps1        # Installs base diagnostic tools via WinGet
    ├── remove-unwanted-apps.ps1     # Debloats Windows preinstalled Appx store apps
    ├── network-dhcp.ps1             # Flushes DNS, resets Winsock/IP, and re-enables DHCP
    ├── wifi-setup.ps1               # Stages team Wi-Fi profile (MilwaukeeRobotics)
    ├── clear-github-creds.ps1       # Clears GitHub credentials from Credential Manager
    └── test-github.ps1              # Development utility for testing GitHub API queries
```

---

## Utility Scripts (`util/`)

The `util/` directory contains modular sub-scripts designed to be invoked directly or called by master workflows:

| Script | Description |
|---|---|
| [app-default-settings.ps1](file:///Users/erik/Documents/Laptop-Scripts/util/app-default-settings.ps1) | Executes Angry IP Scanner, Notepad++, and Windows Explorer configuration sub-scripts. |
| [angry-ip-scanner-default-settings.ps1](file:///Users/erik/Documents/Laptop-Scripts/util/angry-ip-scanner-default-settings.ps1) | Sets registry preferences for Angry IP Scanner: ping timeout (200ms), FRC ports (`22, 80, 443, 5800, 8080`), and displays alive hosts only. |
| [notepadplusplus-dont-remember-last-session.ps1](file:///Users/erik/Documents/Laptop-Scripts/util/notepadplusplus-dont-remember-last-session.ps1) | Configures Notepad++ `config.xml` to set `RememberLastSession="no"` and clears `session.xml`. |
| [explorer-settings.ps1](file:///Users/erik/Documents/Laptop-Scripts/util/explorer-settings.ps1) | Sets Windows Explorer registry flags: reveals file extensions (`HideFileExt=0`), shows hidden files (`Hidden=1`), and displays full paths in title bar (`FullPath=1`). |
| [install-base-apps.ps1](file:///Users/erik/Documents/Laptop-Scripts/util/install-base-apps.ps1) | Uses WinGet to install essential diagnostic utilities (Wireshark, PuTTY, Git, 7-Zip, Notepad++, Angry IP Scanner, Apple Bonjour mDNS, Python, PathPlanner, 1Password, PowerToys, Balena Etcher, PowerShell 7). |
| [remove-unwanted-apps.ps1](file:///Users/erik/Documents/Laptop-Scripts/util/remove-unwanted-apps.ps1) | Uninstalls consumer/OEM Windows Store packages (Teams, Office hub, Solitaire, News, Weather, Clipchamp, Xbox, etc.). |
| [network-dhcp.ps1](file:///Users/erik/Documents/Laptop-Scripts/util/network-dhcp.ps1) | Flushes DNS, resets Winsock and TCP/IP stack, deletes saved WLAN profiles, and switches active network adapters back to DHCP. |
| [wifi-setup.ps1](file:///Users/erik/Documents/Laptop-Scripts/util/wifi-setup.ps1) | Generates and applies a standard WPA2-Personal WLAN XML profile for team Wi-Fi. |
| [clear-github-creds.ps1](file:///Users/erik/Documents/Laptop-Scripts/util/clear-github-creds.ps1) | Uses `cmdkey.exe` to find and delete any stored GitHub personal access tokens or credentials. |

---

## Bootstrap Installer (`LaptopInstaller/`)

When deploying on freshly reimaged laptops that do not yet have Git installed:
1. Copy or distribute the `LaptopInstaller/` folder (e.g., via USB drive or [network share](https://drive.google.com/file/d/1zXlmaLduF_JXMjRIZljJAf-PdMoF30pz/view?usp=sharing)).
2. Run `LoadScripts.exe` (or `loadscripts.ps1`).
3. The script will:
   - Unpack the included `PortableGit.exe` to `.\PortableGit`.
   - Add Git to the temporary session `$env:PATH`.
   - Ensure `ps2exe` is installed via NuGet.
   - Clone this repository into `C:\Laptop-Scripts`.
   - Run `create-exes.ps1` to compile the executables.

---

## Customization & Configuration

- **Team Number:** Set via `-TeamNumber` in `driverstation-setup.ps1`.
- **Team Wi-Fi Network:** Edit default SSID and password variables in [util/wifi-setup.ps1](file:///Users/erik/Documents/Laptop-Scripts/util/wifi-setup.ps1).
- **Adding Download Packages:** Add new entries to the `$Packages` array in [frc-latest-download.ps1](file:///Users/erik/Documents/Laptop-Scripts/frc-latest-download.ps1) (e.g. for CTRE Phoenix Tuner, PathPlanner, or AdvantageScope GitHub releases).
- **Adding WinGet Apps:** Add app IDs to the `$WingetApps` array in [util/install-base-apps.ps1](file:///Users/erik/Documents/Laptop-Scripts/util/install-base-apps.ps1).
- **Adding VS Code Extensions:** Add extension IDs to the `$extensions` array in [frc-latest-install.ps1](file:///Users/erik/Documents/Laptop-Scripts/frc-latest-install.ps1).
