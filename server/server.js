const admin = require('firebase-admin');
const path = require('path');
const fs = require('fs');

const serviceAccountPath = path.join(__dirname, 'serviceAccountKey.json');

if (!fs.existsSync(serviceAccountPath)) {
  console.error(`Missing service account file at ${serviceAccountPath}`);
  console.error('Place your Firebase serviceAccountKey.json in the server folder and restart the server.');
  process.exit(1);
}

const serviceAccount = require(serviceAccountPath);

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

const db = admin.firestore();
const messaging = admin.messaging();
const topicName = 'security_all';
const tokensCollectionName = 'fcmTokens';

function buildNotificationMessage({ notificationId, title, body, type, createdAt }) {
  return {
    notification: { title, body },
    data: {
      notificationId,
      type,
      createdAt,
    },
    android: {
      priority: 'high',
      notification: {
        channelId: 'security_alerts',
        sound: 'default',
      },
    },
    apns: {
      payload: {
        aps: {
          sound: 'default',
        },
      },
    },
  };
}

function extractActiveTokens(snapshotDocs) {
  return snapshotDocs
    .map((doc) => {
      if (!doc || typeof doc.data !== 'function') {
        return null;
      }

      const data = doc.data();
      if (!data || data.active !== true) {
        return null;
      }

      const token = typeof data.token === 'string' ? data.token.trim() : '';
      return token || null;
    })
    .filter(Boolean);
}

async function getActiveTokens() {
  const snapshot = await db.collection(tokensCollectionName).where('active', '==', true).get();
  return extractActiveTokens(snapshot.docs);
}

async function sendNotification(doc) {
  const data = doc.data();
  if (!data) {
    console.error('Notification document has no data', doc.id);
    return false;
  }

  if (data.fcmSent === true) {
    return false;
  }

  const title = data.title ? String(data.title) : 'Key Record Alert';
  const body = data.body ? String(data.body) : 'You have a new notification.';
  const type = data.type ? String(data.type) : 'general';
  const createdAt = data.createdAt && typeof data.createdAt.toDate === 'function'
    ? data.createdAt.toDate().toISOString()
    : (data.createdAt ? String(data.createdAt) : new Date().toISOString());

  const message = buildNotificationMessage({
    notificationId: doc.id,
    title,
    body,
    type,
    createdAt,
  });

  try {
    const tokens = await getActiveTokens();

    if (tokens.length > 0) {
      const multicastMessage = {
        tokens,
        ...message,
      };
      const response = await messaging.sendEachForMulticast(multicastMessage);
      console.log(`FCM multicast sent for ${doc.id}:`, response);
    } else {
      const response = await messaging.send({
        ...message,
        topic: topicName,
      });
      console.log(`FCM topic fallback sent for ${doc.id}:`, response);
    }

    await doc.ref.update({
      fcmSent: true,
      fcmSentAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    return true;
  } catch (error) {
    console.error(`Failed to send FCM for ${doc.id}:`, error);
    return false;
  }
}

async function startListener() {
  console.log('Listening for new Firestore notifications...');
  db.collection('notifications')
    .where('fcmSent', '!=', true)
    .orderBy('createdAt', 'asc')
    .onSnapshot(async (snapshot) => {
      for (const change of snapshot.docChanges()) {
        if (change.type !== 'added') {
          continue;
        }

        const doc = change.doc;
        if (doc.exists) {
          await sendNotification(doc);
        }
      }
    }, (error) => {
      console.error('Firestore listener error:', error);
    });
}

if (require.main === module) {
  (async function main() {
    try {
      await startListener();
    } catch (error) {
      console.error('Server startup failed:', error);
      process.exit(1);
    }
  })();
}

module.exports = {
  buildNotificationMessage,
  extractActiveTokens,
  getActiveTokens,
  sendNotification,
  startListener,
};
