const admin = require('firebase-admin');
const path = require('path');
const fs = require('fs');

const serviceAccountPath = path.join(__dirname, 'serviceAccountKey.json');
if (!fs.existsSync(serviceAccountPath)) {
  console.error('Missing service account file at', serviceAccountPath);
  process.exit(1);
}

const serviceAccount = require(serviceAccountPath);
admin.initializeApp({ credential: admin.credential.cert(serviceAccount) });
const db = admin.firestore();

function normalize(value) {
  return (value || '').toString().trim().toUpperCase();
}

function normalizeLevel(key) {
  const metadataLevel = normalize(key.metadata?.level);
  if (metadataLevel) return metadataLevel;
  const rollerLevel = normalize(key.metadata?.rollerLevelNo);
  if (rollerLevel) return rollerLevel;
  const zoneValue = normalize(key.zone);
  const match = zoneValue.match(/B2|B1|L\d{1,2}|LEVEL\s*\d{1,2}/);
  if (match) return match[0].replace('LEVEL ', 'L');
  return '';
}

function normalizeZone(key) {
  const metadataZone = normalize(key.metadata?.zone);
  if (metadataZone) return metadataZone;
  return normalize(key.zone);
}

function logicalIdentity(key) {
  const keyId = normalize(key.keyId);
  const category = normalize(key.category);
  const name = normalize(key.keyName);
  const level = normalizeLevel(key);
  const zone = normalizeZone(key);
  return `${keyId}|${category}|${level}|${zone}|${name}`;
}

(async () => {
  const snapshot = await db.collection('keys').get();
  console.log('Total key docs:', snapshot.size);
  const entries = [];
  snapshot.forEach((doc) => {
    const data = doc.data();
    entries.push({
      docId: doc.id,
      keyId: data.keyId || '',
      keyName: data.keyName || '',
      category: data.category || '',
      zone: data.zone || '',
      status: data.status || '',
      level: data.metadata?.level || '',
      lotKey: data.metadata?.lotKey || '',
      masterKey: data.metadata?.masterKey || '',
      rollerLevelNo: data.metadata?.rollerLevelNo || '',
      rollerNumber: data.metadata?.rollerNumber || '',
      raw: data,
      identity: logicalIdentity(data),
    });
  });

  const byIdentity = new Map();
  for (const entry of entries) {
    const list = byIdentity.get(entry.identity) || [];
    list.push(entry);
    byIdentity.set(entry.identity, list);
  }

  const duplicates = [...byIdentity.entries()].filter(([, list]) => list.length > 1);
  console.log('Duplicate logical identities:', duplicates.length);
  for (const [identity, list] of duplicates) {
    console.log('\nIDENTITY:', identity);
    list.forEach((entry) => {
      console.log('  docId=', entry.docId, 'keyId=', entry.keyId, 'status=', entry.status, 'keyName=', entry.keyName, 'category=', entry.category, 'zone=', entry.zone, 'level=', entry.level, 'lot=', entry.lotKey, 'master=', entry.masterKey, 'roller=', entry.rollerLevelNo, entry.rollerNumber);
    });
  }
})();
