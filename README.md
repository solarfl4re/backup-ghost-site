# backup-ghost-site
Shell script to back up a Ghost CMS site (depends on [gdrive-upload](https://github.com/solarfl4re/gdrive-upload) to upload to Google Drive). Has been **running in production for more than a year**.

Pull requests welcome.

## Before Using
- Install `zip` (`sudo apt install zip`)

**Set up `gdrive-upload`**
- Open [Node.js Quickstart](https://developers.google.com/drive/api/v3/quickstart/nodejs) and click 'Enable the Drive API'.
- Give your project a name, and choose `TVs and limited input devices` in the dropdown.
- Save `credentials.json` to `gdrive-upload/src` and in that directory run `node client.js` to set up your credentials.

**Change defaults in `backup.sh` to match your site**
- Change `backupDir` to the directory that `backup-ghost-site` is located in (e.g. /home/david/repos/backup-ghost-site)
- Change `domain` to the address of your site, e.g. `https://davidlane.io`.
- Change `ghostImagesFolder` to the path of your images directory (e.g. /var/www/ghost/content/images/)
- _(Optional)_ Change `backupName` to customize the name of the backup archive

**Tell `backup-ghost-site` where `gdrive-upload` is**
- In backupToDrive.js, enter the path to `gdrive-upload`, for example: `...require('../gdrive-upload')`.
You can also use `npm link` to make `gdrive-upload` available globally.

**Enter your Ghost login credentials in `credentials.sh`**
````bash
GHOSTUSER="Your username here"
GHOSTPASSWORD="Your password here"
````
## Using
Run `backup.sh` to manually backup (or test and make sure it's working).

To run daily, add it to your crontab. Mine looks like this (backing up every night at 3 am):
````crontab
* * 3 * * /bin/bash /home/david/repos/backup-ghost-site/backup.sh > /home/david/repos/backup-ghost-site/cron.log
````

### Backing up to something besides Google Drive
`backup.sh` uploads the backup with the line `node $backupDir/backupToDrive.js "$backupDir/$filename"`. Change this to fit your needs (e.g. replace with something to backup to Dropbox or another server).


## Technical details
**Database backup**
- Using `curl`, saves a JSON dump of the database from the `/ghost/api/v3/admin/db/` endpoint.
- Calls `stripDBTimes.js` to strip values that change whenever we access the API
- Runs `diff` and to only backup when something has changed (e.g. a new or updated page). Currently clears values (last log in time, etc) for the first Ghost user - if you log in as someone else, you update `stripDBTimes.js`.

**Backup images**
- Maintains a copy of Ghost's `images` folder and uses `rsync` to sync images.
- Only includes images in backup if there are changes.
