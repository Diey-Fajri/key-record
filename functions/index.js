const functions = require('firebase-functions');
const admin = require('firebase-admin');

admin.initializeApp();

const messaging = admin.messaging();
const tokensCollectionName = 'fcmTokens';

function buildMessagePayload({ notificationId, title, body, type, createdAt }) {
  return {
    notification: {
      title,
      body,
    },
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

async function getActiveTokens() {
  const snapshot = await admin.firestore().collection(tokensCollectionName).where('active', '==', true).get();
  return snapshot.docs
    .map((doc) => {
      const data = doc.data();
      if (!data || data.active !== true) {
        return null;
      }
      const token = typeof data.token === 'string' ? data.token.trim() : '';
      return token || null;
    })
    .filter(Boolean);
}

exports.sendNotificationOnCreate = functions.firestore
  .document('notifications/{notificationId}')
  .onCreate(async (snapshot, context) => {
    const notificationId = context.params.notificationId;
    const data = snapshot.data();

    if (!data) {
      functions.logger.error('Notification document data is missing.', { notificationId });
      return null;
    }

    if (data.fcmSent === true) {
      functions.logger.info('Notification already sent, skipping duplicate.', { notificationId });
      return null;
    }

    const title = data.title ? String(data.title) : 'Key Record Alert';
    const body = data.body ? String(data.body) : 'You have a new notification.';
    const type = data.type ? String(data.type) : 'general';
    const createdAt = data.createdAt ? data.createdAt.toDate?.()?.toISOString?.() ?? String(data.createdAt) : new Date().toISOString();

    const message = buildMessagePayload({ notificationId, title, body, type, createdAt });

    functions.logger.info('Sending FCM notification.', { notificationId, title, body, type, createdAt });

    try {
      const tokens = await getActiveTokens();

      if (tokens.length > 0) {
        const response = await messaging.sendEachForMulticast({
          tokens,
          ...message,
        });
        functions.logger.info('FCM multicast sent successfully.', { notificationId, response });
      } else {
        const response = await messaging.send({
          topic: 'security_all',
          ...message,
        });
        functions.logger.info('FCM topic fallback sent successfully.', { notificationId, response });
      }

      await snapshot.ref.update({
        fcmSent: true,
        fcmSentAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      return null;
    } catch (error) {
      functions.logger.error('Failed to send FCM message.', { notificationId, error });
      return null;
    }
  });
