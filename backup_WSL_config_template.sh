#!/bin/bash
# This script defines the inputs for the script backup_WSL.sh
SOURCE_PATH="/mnt/d"                    # Internal drive containing data to backup
LOG_PATH="Backups/backup_log.txt"       # Path to log file on external drive
DESTINATION_PATH="Backups/MyBackup"     # Path on external drive where data should be sent to
SYNC_PATHS=("Cloud/Home" "Local")       # Paths to data on internal drive 
