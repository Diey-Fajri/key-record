const admin = require('firebase-admin');
const path = require('path');
const fs = require('fs');

const serviceAccountPath = path.join(__dirname, 'serviceAccountKey.json');
if (!fs.existsSync(serviceAccountPath)) {
  console.error(`Missing service account file at ${serviceAccountPath}`);
  process.exit(1);
}

const serviceAccount = require(serviceAccountPath);
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

const db = admin.firestore();

async function deleteCollection(collectionPath) {
  const collectionRef = db.collection(collectionPath);
  let deletedCount = 0;
  let query = collectionRef.limit(500);

  while (true) {
    const snapshot = await query.get();
    if (snapshot.empty) {
      break;
    }

    const batch = db.batch();
    snapshot.docs.forEach((doc) => batch.delete(doc.ref));
    await batch.commit();
    deletedCount += snapshot.docs.length;

    if (snapshot.size < 500) {
      break;
    }

    const lastDoc = snapshot.docs[snapshot.docs.length - 1];
    query = collectionRef.startAfter(lastDoc).limit(500);
  }

  return deletedCount;
}

(async () => {
  try {
    const notificationsDeleted = await deleteCollection('notifications');
    const eventLogDeleted = await deleteCollection('event_log');

    console.log(`Notifications cleared: ${notificationsDeleted}`);
    console.log(`Event log entries cleared: ${eventLogDeleted}`);
    process.exit(0);
  } catch (error) {
    console.error('Cleanup failed:', error);
    process.exit(1);
  }
})();
