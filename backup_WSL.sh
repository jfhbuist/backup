#!/bin/bash
# This script makes a backup of important folders to an external hard drive, using rsync.
# Requires rsync.
# Requires running with sudo.
# All commands will be run with sudo, except those preceded by sudo -u $real_user.  
# This can be applied as a precaution.

# ref: https://askubuntu.com/questions/425754/how-do-i-run-a-sudo-command-inside-a-script
if ! [ $(id -u) = 0 ]; then
  echo "This script needs to be run with sudo." >&2
  exit 1
fi

# get name of real user
if [ $SUDO_USER ]; then
  real_user=$SUDO_USER
else
  real_user=$(whoami)
fi

echo "This script makes a backup of listed folders using rsync to an external hard drive."

# Ask for the letter that the OS has given the external drive:
echo -n "Enter the letter for the external drive (eg. E) and press [ENTER]: "
read drive_letter
# Check if drive letter is valid:
if ! ( [[ ${#drive_letter} == 1 ]] && [[ "$drive_letter" =~ ^[a-zA-Z]+$ ]] ); then 
  echo "You did not enter a valid drive letter, please try again."
  exit 1
fi

# Check for confirmation:
echo -n "Chosen drive letter is $drive_letter. Are you sure? (Y/N): "
read confirmation
if ! ( [ "$confirmation" == "Y" ] || [ "$confirmation" == "y" ] ); then
  echo "Backup was aborted."
  exit 1
fi

drive_letter=$(echo "$drive_letter" | tr '[:upper:]' '[:lower:]')
DRIVE_PATH="/mnt/${drive_letter}"
# Check if drive is already mounted
if mountpoint -q /mnt/e; then
  mounted=true
else
  mounted=false
fi
# Check if folder already exists
if [ -d "$DRIVE_PATH" ]; then
  folder_exists=true
else
  folder_exists=false
fi

# If drive is already mounted, it may not be an external drive.
# In this case check for confirmation.
if [ "$mounted" = true ] || [ "$folder_exists" = true ]; then
  echo "External drive seems to be mounted already at path $DRIVE_PATH."
  echo -n "Are you sure this is the correct external drive? (Y/N): "
  read confirmation
  if ! ( [ "$confirmation" == "Y" ] || [ "$confirmation" == "y" ] ); then
    echo "Backup was aborted."
    exit 1
  fi
fi

# We have two backup versions, to be updated in a staggered manner. Ask which to update now.
echo -n "Enter the backup letter (A/B) and press [ENTER]: "
read backup_letter
# Check if backup letter is valid:
if ! ( [ "$backup_letter" == "A" ] || [ "$backup_letter" == "B" ] ); then
  echo "You did not enter a valid backup letter, please try again."
  exit 1
fi

# Check for confirmation:
echo -n "Chosen backup letter is $backup_letter. Are you sure? (Y/N): "
read confirmation
if ! ( [ "$confirmation" == "Y" ] || [ "$confirmation" == "y" ] ); then
  echo "Backup was aborted."
  exit 1
fi

# Load paths from config file:
source backup_WSL_config.sh
LOG_PATH="${DRIVE_PATH}/${LOG_PATH}"
DESTINATION_PATH="${DRIVE_PATH}/${DESTINATION_PATH}_${backup_letter}"
PRETTY_DESTINATION_PATH=$(basename "${DESTINATION_PATH}")

echo "Log path is: ${LOG_PATH}."
SOURCE_PATH_CHECK="Source paths are:"
DESTINATION_PATH_CHECK="Destination paths are:"
for SYNC_PATH in "${SYNC_PATHS[@]}"
do
  FULL_SOURCE_PATH="${SOURCE_PATH}/${SYNC_PATH}"
  SOURCE_PATH_CHECK+=" ${FULL_SOURCE_PATH},"
  FULL_DESTINATION_PATH=$(dirname "${DESTINATION_PATH}/${SYNC_PATH}")
  FULL_DESTINATION_PATH="${FULL_DESTINATION_PATH}/"
  DESTINATION_PATH_CHECK+=" ${FULL_DESTINATION_PATH},"
done
SOURCE_PATH_CHECK="${SOURCE_PATH_CHECK%?}."
DESTINATION_PATH_CHECK="${DESTINATION_PATH_CHECK%?}."
echo $SOURCE_PATH_CHECK
echo $DESTINATION_PATH_CHECK

# Check for confirmation:
echo -n "Are you sure? (Y/N): "
read confirmation
if !( [ "$confirmation" == "Y" ] || [ "$confirmation" == "y" ] ); then
  echo "Backup was aborted."
  exit 1
fi

# mount drive (we need sudo for this)
# only mount drive if it was not already mounted
cd /
if [ "$mounted" = false ] || [ "$folder_exists" = false ]; then
  mkdir "$DRIVE_PATH"
  mount -t drvfs E: "$DRIVE_PATH"
fi

for SYNC_PATH in "${SYNC_PATHS[@]}"
do
  FULL_SOURCE_PATH="${SOURCE_PATH}/${SYNC_PATH}"
  FULL_DESTINATION_PATH=$(dirname "${DESTINATION_PATH}/${SYNC_PATH}")
  FULL_DESTINATION_PATH="${FULL_DESTINATION_PATH}/"
  # --dry-run option can be added for testing purposes. In this case, nothing happens.
  # Options --no-perms --no-owner --no-group are added to support NTFS file system
  # Option --modify-window=1 could be added additionally to prevent unnecessary copying
  rsync -avh --no-perms --no-owner --no-group --stats --delete --exclude=".*/" "$FULL_SOURCE_PATH" "$FULL_DESTINATION_PATH"
  sleep 5
done

# Write to log and notify user of end of script.
dt=$(date '+%d/%m/%Y %H:%M:%S');
echo "Backup of $PRETTY_DESTINATION_PATH made on $dt." >> "$LOG_PATH"
echo "Backup of $PRETTY_DESTINATION_PATH finished at $dt."

# unmount drive (we need sudo for this)
# only unmount drive if it was not already mounted (before this script was run)
if [ "$mounted" = false ] || [ "$folder_exists" = false ]; then
  umount "$DRIVE_PATH"
  rmdir "$DRIVE_PATH"
fi

# Return to home
cd ~
