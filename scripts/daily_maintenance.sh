#!/bin/bash

# --- CONFIGURATION ---
LOG_FILE="/var/log/daily_maintenance.log"
BACKUP_DIR="/home/sentry/backups"
SOURCE_DIR="/home/sentry/documents"
DATE_STAMP=$(date +'%Y-%m-%d')
BACKUP_FILE="backup_$DATE_STAMP.tar.gz"

# --- COLORS (The Professional Look) ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# --- FUNCTIONS ---
log() {
    local msg="$1"
    local type="$2" # INFO, SUCCESS, ERROR
    local color=$NC
    
    if [ "$type" == "SUCCESS" ]; then color=$GREEN; fi
    if [ "$type" == "ERROR" ]; then color=$RED; fi
    if [ "$type" == "INFO" ]; then color=$YELLOW; fi

    echo -e "${CYAN}[$(date +'%T')]${NC} ${color}$msg${NC}"
    echo "[$(date +'%Y-%m-%d %T')] [$type] $msg" | sudo tee -a $LOG_FILE > /dev/null
}

# --- MAIN SCRIPT ---

# 1. System Update
log "Starting System Maintenance..." "INFO"
log "Updating package lists..." "INFO"

if sudo apt update -y > /dev/null 2>&1; then
    log "Package list updated." "SUCCESS"
else
    log "Failed to update packages." "ERROR"
fi

# 2. Cleanup
log "Cleaning up orphaned packages..." "INFO"
sudo apt autoremove -y > /dev/null 2>&1
sudo apt clean
log "System cleanup complete." "SUCCESS"

# 3. Backup Protocol (The Deliverable)
log "Starting Backup of $SOURCE_DIR..." "INFO"

# Ensure backup directory exists
mkdir -p $BACKUP_DIR

# Create the archive
# -c: Create, -z: Gzip, -f: File
if tar -czf "$BACKUP_DIR/$BACKUP_FILE" -C "$SOURCE_DIR" .; then
    log "Backup created successfully: $BACKUP_DIR/$BACKUP_FILE" "SUCCESS"
    
    # Verify content size
    FILE_SIZE=$(du -h "$BACKUP_DIR/$BACKUP_FILE" | cut -f1)
    log "Backup Size: $FILE_SIZE" "SUCCESS"
else
    log "Backup FAILED." "ERROR"
    exit 1
fi

log "Daily Maintenance Completed Successfully." "SUCCESS"
