#!/bin/bash

PROFILE_NAME=DEFAULT
BACKUP_NAME=Full_Backup
COMPARTMENT_ID='ocid1.tenancy.oc1**********************************************' # Get this from your Oracle Profile
TMP_BACKUP_NAME=$(date +%Y-%m-%d_%H-%M-%S)

echo "Running at ${TMP_BACKUP_NAME}."
echo "Getting previous backup..."

OUTPUT=$(oci bv boot-volume-backup list --compartment-id ${COMPARTMENT_ID} --display-name ${BACKUP_NAME} --lifecycle-state AVAILABLE --query "data [0].{bootVolumeId:\"boot-volume-id\",id:id}" --raw-output --profile ${PROFILE_NAME})
LAST_BACKUP_ID=$(echo $OUTPUT | /usr/bin/jq -r '.id')
BOOT_VOLUME_ID=$(echo $OUTPUT | /usr/bin/jq -r '.bootVolumeId')

echo "Last backup id: $LAST_BACKUP_ID"
echo "Boot volume id: $BOOT_VOLUME_ID"

echo "Creating new backup..."
NEW_BACKUP_ID=$(oci bv boot-volume-backup create --boot-volume-id ${BOOT_VOLUME_ID} --type FULL --display-name ${TMP_BACKUP_NAME} --wait-for-state AVAILABLE --query "data.id" --raw-output --profile ${PROFILE_NAME})

if [ -z "$NEW_BACKUP_ID" ]
then
    echo "New backup creation failed...Exiting script!"; exit
else
    echo "New backup id: $NEW_BACKUP_ID"
fi

echo "Deleting old backup..."
DELETED_BACKUP=$(oci bv boot-volume-backup delete --force --boot-volume-backup-id ${LAST_BACKUP_ID} --wait-for-state TERMINATED --profile ${PROFILE_NAME})

echo "Renaming temp backup..."
RENAMED_BACKUP=$(oci bv boot-volume-backup update --boot-volume-backup-id ${NEW_BACKUP_ID} --display-name ${BACKUP_NAME} --profile ${PROFILE_NAME})

echo "Backup process complete! Goodbye!"
