#!/bin/bash
# This script defines the inputs for the script backup_Mac.sh
SOURCE_PATH="Users/MyName"                              # General path to data on internal drive
LOG_PATH="Volumes/MyDrive/Backups/backup_log.txt"       # Path to log file on external drive
DESTINATION_PATH="/Volumes/MyDrive/Backups/MyBackup"    # Path on external drive where data should be sent to
SYNC_PATHS=("Cloud" "Local" "bin")                      # More specific paths to data on internal drive 
