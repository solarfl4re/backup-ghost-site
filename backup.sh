#!/bin/bash

function backupImages() {
  rsync_result=$(rsync -ai --delete /var/www/svarych/content/images/ images-backup)

   if [ $? -eq 0 ]; then
    echo "Success!"

    if [ -n "${rsync_result}" ]; then
      echo "Rsync made changes!!"
      mkdir svarych-cloud-backup/images
      cp -r images-backup/* svarych-cloud-backup/images
      return 0
    else
      echo "No changes!!"
    fi
  else
    echo "Error!"
    exit 1
  fi
}


function backupJSON() {
  curl -c ghost-cookie.txt -d username=david@davidlane.io -d password="JhvbguDwfXhyQP2F]m" -H "Origin: https://svarych.com" https://svarych.com/ghost/api/v3/admin/session
  if $(curl -f -b ghost-cookie.txt -H "Origin: https://svarych.com" https://svarych.com/ghost/api/v3/admin/db/ -o database.json); then
    echo Got JSON
    cp database.json svarych-cloud-backup/
    rm previous-database.json
    mv database.json previous-database.json
    return 0

  else
    echo Failed to get json
    return 1
  fi
}

function backup() {
  # Remove backup dir
  rm -rf "svarych-cloud-backup/"
  mkdir "svarych-cloud-backup"

  # rsync Ghost images -> images-backup
  # Copy to svarych-cloud-backup only if rsync made
  # changes
  backupImages
  backedUpImages=$?

  # Use Curl to get json from svarych.com API
  # If it fails, renew cookie and try again, then copy
  # json to svarych-cloud-backup
  backupJSON
  backedUpJSON=$?

  # If we saved either images or JSON, backup
  if [[ $backedUpImages -eq 0 ]] || [[ $backedUpJSON -eq 0 ]]; then
    filename=svarych.backup.`date +%d-%m-%Y`.tb2
    tar -cjf $filename svarych-cloud-backup/*
    # Log date & dir size, e.g. '09-04-2020 4.0K'
    #echo $(date +%d-%m-%Y) $(du -sh svarych-cloud-backup | awk '{print $1}') >> ~/repos/svarych-backups/backups.txt

    # Upload backup to Google Drive
    node backupToDrive.js "`pwd`/$filename"
  else
    echo svarych-cloud-backup empty, nothing to back up
  fi
}

# Call the function with the name passed on the command
# line
"$@"
