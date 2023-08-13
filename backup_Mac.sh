#!/bin/bash
# This script makes a backup of important folders to an external hard drive, using rsync.
# Requires rsync.

echo "This script makes a backup of listed folders using rsync to an external hard drive."

# We have two backup versions, to be updated in a staggered manner. Ask which to update now.
echo -n "Enter the backup letter (A/B) and press [ENTER]: "
read backup_letter
# Check if backup letter is valid:
if ! ( [ "$backup_letter" == "A" ] || [ "$backup_letter" == "B" ] ); then
  echo "You did not enter a valid letter, please try again."
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
source backup_Mac_config.sh
DESTINATION_PATH="${DESTINATION_PATH}_${backup_letter}"
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
if ! ( [ "$confirmation" == "Y" ] || [ "$confirmation" == "y" ] ); then
  echo "Backup was aborted."
  exit 1
fi

cd / 
for SYNC_PATH in "${SYNC_PATHS[@]}"
do
  FULL_SOURCE_PATH="${SOURCE_PATH}/${SYNC_PATH}"
  FULL_DESTINATION_PATH=$(dirname "${DESTINATION_PATH}/${SYNC_PATH}")
  FULL_DESTINATION_PATH="${FULL_DESTINATION_PATH}/"
  # --dry-run option can be added for testing purposes. In this case, nothing happens.
  rsync -azv --delete --exclude=".git/" "$FULL_SOURCE_PATH" "$FULL_DESTINATION_PATH"
  sleep 5
done

# Write to log and notify user of end of script.
dt=$(date '+%d/%m/%Y %H:%M:%S');
echo "Backup of $PRETTY_DESTINATION_PATH made on $dt." >> "$LOG_PATH"
echo "Backup of $PRETTY_DESTINATION_PATH finished at $dt."
cd ~
