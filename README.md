# backup-ghost-site
Shell script to back up a Ghost CMS site (depends on [gdrive-upload](https://github.com/solarfl4re/gdrive-upload) to upload to Google Drive).

## Using
**Change variables in `backup.sh` for your site**
- Replace `backupDir` with the path of the directory where you have the script.
- `domain` should be the address of your site, e.g. `https://davidlane.io`.
- Change `ghostImagesFolder` to the path of your images directory (e.g. /var/www/ghost/content/images/)
- _(Optional)_ Change `backupName` to customize the name of the backup archive

**Fill in your credentials in `credentials.sh`**
````bash
GHOSTUSER="Your username here"
GHOSTPASSWORD="Your password here"
````

### Set up backup to Google Drive or another service

**Custom backup destination**:
`backup.sh` uploads the backup with the line `node $backupDir/backupToDrive.js "$backupDir/$filename"`. Change this to fit your needs.

**Backup to Google Drive**:
I wrote a script to upload a file to Google Drive based on Google's Node.js examples [upload.js](https://github.com/googleapis/google-api-nodejs-client/blob/master/samples/drive/upload.js) and [sampleclient.js](https://github.com/googleapis/google-api-nodejs-client/blob/master/samples/sampleclient.js).

Follow [Node.js Quickstart](https://developers.google.com/drive/api/v3/quickstart/nodejs) to:
- Turn on the Drive API
- Download `credentials.json` (The 'TV' choice let me download the file)

Use `index.js` and `client.js` from [gdrive-upload](https://github.com/solarfl4re/gdrive-upload) instead of the code on the page.
Run `node client.js` (you need `credentials.json` in the same directory). You'll be prompted to visit a link to authorize the app; visit it, authorize, and paste in the code you get. Now `backup.sh` will upload backups to Google Drive.

The script calls `gdrive-upload` with the following code:
````js
const upload = require('gdrive-upload')

upload(process.argv[2]);
````
For this you need `gdrive-upload` installed in the same directory as the backup script; I used `npm link` to symlink my local `gdrive-backup` directory to Node's global `node_modules` folder, then ran `npm link` in the backup script's directory.


## Technical details
**Database backup**
- Using `curl`, saves a JSON dump of the database from the `/ghost/api/v3/admin/db/` endpoint.
- Calls `stripDBTimes.js` to strip values that change whenever we access the API
- This lets us use `diff` and only backup on changes (e.g. a new or updated page). Currently clears values for the first Ghost user - if you log in as someone else, you need to update `stripDBTimes.js`.

**Backup images**
- Maintains a copy of Ghost's `images` folder and uses `rsync` to sync images.
- Only backs up images if they've changed.
