const fs = require('fs')

// -> path to db -> temp db

inPath = process.argv[2]
outPath = process.argv[3]


db = JSON.parse(fs.readFileSync(inPath, 'utf-8'))

// These values update with every db backup,
// and prevent us from diffing the dbs to see
// if they changed
db.db[0].meta.exported_on = "0"
db.db[0].data.users[0].last_seen = '0'
db.db[0].data.users[0].updated_at = '0'
db.db[0].data.brute = '0'

fs.writeFileSync(outPath, JSON.stringify(db, null, 2))

/** Diff:
 * 1258,1260c1258,1260 data > actions > brute
 * <             "lastRequest": 1586964718352,
 * <             "lifetime": 1586968318354,
 * <             "count": 3
 * ---
 *  >             "lastRequest": 1586964677860,
 *  >             "lifetime": 1586968277862,
 *  >             "count": 2
 *  4406c4406 (users[0] ('David'))
 *  <             "last_seen": "2020-04-15T15:31:58.000Z",
 *  ---
 *  >             "last_seen": "2020-04-15T15:31:17.000Z",
 *  4408c4408
 *  <             "updated_at": "2020-04-15T15:31:58.000Z"
 *  ---
 *  >             "updated_at": "2020-04-15T15:31:17.000Z"
 */
