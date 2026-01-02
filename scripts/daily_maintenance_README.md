# Automated System Maintenance & Backup Script

**Component:** Phase 1 (Iron Foundation) - Day 2  
**Author:** Pratik Chandra Thakur  
**Status:** Active

## 📋 Overview
This Bash script automates the daily hygiene required for a secure Linux server. It adheres to the DevSecOps principle of "Operational Excellence" by eliminating manual toil for routine tasks. 

It performs system updates, cleans up package caches to reduce attack surface, and generates timestamped backups of critical data.

## ✨ Features
* **System Hardening:** Automatically installs security updates (`apt update` & `upgrade`).
* **Disk Hygiene:** Removes orphaned packages and clears `apt` cache to free space.
* **Automated Backups:** Creates a `.tar.gz` archive of the `~/documents` directory.
* **Visual Logging:** Implements "Traffic Light" color coding (Green/Red) for immediate visual status checks.
* **Audit Trail:** Logs all activities with timestamps to `/var/log/daily_maintenance.log`.

## 🚀 Usage

### 1. Installation
Clone the repository and navigate to the scripts folder:
```bash
git clone [https://github.com/YourUsername/AuditBot.git](https://github.com/YourUsername/AuditBot.git)
cd AuditBot/scripts
