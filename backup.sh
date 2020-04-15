#!/bin/bash
# Put your Ghost username and password in `credentials.sh`

# Change to the directory where this script is
backupDir=/home/user/backups/backup-ghost-site/

# Change to match your domain
domain="https://EXAMPLE.COM"

# Change to the image folder for your blog
ghostImagesFolder=/var/www/ghost/content/images/

# Backup archive name
backupName="ghost.backup"

function backupImages() {
  rsync_result=$(rsync -ai --delete $ghostImagesFolder $backupDir/images-backup)

   if [ $? -eq 0 ]; then

    if [ -n "${rsync_result}" ]; then
      echo "Rsync copied new images"
      mkdir $backupDir/backup/images
      cp -r $backupDir/images-backup/* $backupDir/backup/images
      return 0
    else
      echo "No new images"
    fi
  else
    echo "Error!"
    exit 1
  fi
  return 1
}


function backupJSON() {
  curl -c $backupDir/ghost-cookie.txt -d username=$GHOSTUSER -d password=$GHOSTPASSWORD -H "Origin: $domain" $domain/ghost/api/v3/admin/session
  if $(curl -f -b $backupDir/ghost-cookie.txt -H "Origin: $domain" $domain/ghost/api/v3/admin/db/ -o $backupDir/new-database.json); then
    echo Got JSON

    # If we have a previous DB to compare with
    if [[ -f $backupDir/database.json ]]; then

      # Make current & previous DB copies without the
      # values that change with every API access -
      # This lets us backup the DB only when it changes
      node $backupDir/stripDBTimes.js $backupDir/new-database.json $backupDir/tmp_new-database.json
      node $backupDir/stripDBTimes.js $backupDir/database.json $backupDir/tmp_database.json


      # Backup if they differ
      if [[ -n $(diff $backupDir/tmp_database.json $backupDir/tmp_new-database.json -q) ]]; then
        echo DB changed
        return 0
      else
        echo No change to DB
        return 1
      fi
    else
      # No database.json = this is the first run, backup
      echo "First run, telling backup() to backup"
      return 0
    fi
  fi
echo Failed to get json
return 1
}

function cleanupDatabases() {
  mv --force $backupDir/new-database.json $backupDir/database.json &>/dev/null
  rm -f $backupDir/tmp_new-database.json
  rm -f $backupDir/tmp_database.json
}

function cleanBackupDir() {
  # Clean backup directory
  rm -rf "$backupDir/backup/images"
  rm -f "$backupDir/backup/database.json"
}

function backup() {
  echo Starting backup on $(date)
  cd $backupDir
  # Get Ghost username & password
  # Stored as GHOSTUSER & GHOSTPASSWORD
  . $backupDir/credentials.sh

  if [[ ! -d $backupDir/backup ]]; then
    mkdir $backupDir/backup
  fi

  cleanBackupDir

  # rsync (Ghost images) -> images-backup
  # Return 0 if if rsync made changes
  # (e.g. there are new images)
  backupImages
  backedUpImages=$?

  # Use Curl to get DB as JSON from Ghost Admin API
  # Diff new and old DBs, return 0 if the DB changed
  backupJSON
  backedUpJSON=$?

  if [[ $backedUpImages -eq 0 ]]; then
    cp -r $backupDir/images-backup/* $backupDir/backup/
  fi
  # Always include DB if we're backing up images
  if [[ $backedUpJSON -eq 0 ]] ||
    [[ $backedUpImages -eq 0 ]]; then
  cp $backupDir/new-database.json $backupDir/backup/database.json
  mv --force $backupDir/new-database.json $backupDir/database.json

  filename=$backupName.`date +%d-%m-%Y`.zip
  cd $backupDir/backup/

  # if [[ -f database.json ]] || [[ -d images/ ]]; then
  zip -r $filename database.json images/
  echo Filename is $filename

  mv --force $filename $backupDir

  echo Backing up to drive
  # Upload backup to Google Drive
  node $backupDir/backupToDrive.js "$backupDir/$filename"
else
  echo Nothing to back up
fi

cd $backupDir

cleanBackupDir
cleanupDatabases

# Remove backups older than 4 days
find $backupDir -ctime +4 -name "$backupName*.zip" -delete

  }

# Call the function with the name passed on the command
# line
#"$@"

backup
