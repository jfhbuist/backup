#!/bin/bash
# This script makes a backup of important folders using rsync to newest disk.
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
# If folder already exists, drive may already be mounted, and it may not be an external drive. 
# In this case abort.
if [ -d "$DRIVE_PATH" ]; then
  echo "External drive seems to be mounted already at path $DRIVE_PATH. Backup aborted."
  exit 1
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
cd /
mkdir "$DRIVE_PATH"
mount -t drvfs E: "$DRIVE_PATH"

for SYNC_PATH in "${SYNC_PATHS[@]}"
do
  FULL_SOURCE_PATH="${SOURCE_PATH}/${SYNC_PATH}"
  FULL_DESTINATION_PATH=$(dirname "${DESTINATION_PATH}/${SYNC_PATH}")
  FULL_DESTINATION_PATH="${FULL_DESTINATION_PATH}/"
  # --dry-run option can be added for testing purposes. In this case, nothing happens.
  rsync -azv --delete "$FULL_SOURCE_PATH" "$FULL_DESTINATION_PATH"
  sleep 5
done

# Write to log and notify user of end of script.
dt=$(date '+%d/%m/%Y %H:%M:%S');
echo "Backup of $PRETTY_DESTINATION_PATH made on $dt." >> "$LOG_PATH"
echo "Backup of $PRETTY_DESTINATION_PATH finished at $dt."

# unmount drive (we need sudo for this)
umount "$DRIVE_PATH"
rmdir "$DRIVE_PATH"

# Return to home
cd ~
