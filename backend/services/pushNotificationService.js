const admin = require('firebase-admin');
const path = require('path');
const fs = require('fs');
const { createClient } = require('@supabase/supabase-js');

let initialized = false;

function loadServiceAccount() {
  try {
    // Preferred: a path to the downloaded service-account JSON file (local dev).
    if (process.env.FIREBASE_SERVICE_ACCOUNT_PATH) {
      const resolved = path.resolve(__dirname, '..', process.env.FIREBASE_SERVICE_ACCOUNT_PATH);
      if (fs.existsSync(resolved)) {
        return JSON.parse(fs.readFileSync(resolved, 'utf8'));
      }
    }
    // Alternative: paste the whole JSON into one env var (handy on Vercel).
    if (process.env.FIREBASE_SERVICE_ACCOUNT_JSON) {
      return JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT_JSON);
    }
    // Alternative: base64-encoded JSON (avoids quoting issues in some env UIs).
    if (process.env.FIREBASE_SERVICE_ACCOUNT_BASE64) {
      const decoded = Buffer.from(process.env.FIREBASE_SERVICE_ACCOUNT_BASE64.trim(), 'base64').toString('utf8');
      return JSON.parse(decoded);
    }
  } catch (err) {
    console.error('❌ Failed to parse Firebase service account credentials:', err.message);
  }
  return null;
}

function initFirebaseAdmin() {
  if (initialized) return;

  const serviceAccount = loadServiceAccount();
  if (!serviceAccount) {
    console.warn('⚠️  No Firebase service account configured — push notifications are disabled.');
    return;
  }

  try {
    admin.initializeApp({
      credential: admin.credential.cert(serviceAccount),
    });
    initialized = true;
  } catch (err) {
    console.error('❌ Failed to initialize Firebase Admin:', err.message);
  }
}

/**
 * Sends one FCM push and, on a dead token, clears it from Supabase so we
 * stop retrying it.
 */
async function sendPushNotification(fcmToken, { title, body, data = {} }) {
  if (!fcmToken) {
    console.warn('⚠️  sendPushNotification: no fcm_token on this user, skipping.');
    return { success: false, skipped: true };
  }

  initFirebaseAdmin();
  if (!initialized) return { success: false, skipped: true };

  try {
    const messageId = await admin.messaging().send({
      token: fcmToken,
      notification: { title, body },
      // FCM data payloads must be flat string maps.
      data: Object.fromEntries(Object.entries(data).map(([k, v]) => [k, String(v)])),
      android: { priority: 'high' },
      apns: { payload: { aps: { sound: 'default' } } },
    });
    console.log(`🔔 Push sent (${messageId}) → "${title}"`);
    return { success: true, messageId };
  } catch (error) {
    console.error('❌ Push notification failed:', error.message);
    if (error.code === 'messaging/registration-token-not-registered') {
      await clearStaleToken(fcmToken);
    }
    return { success: false, error: error.message };
  }
}

async function clearStaleToken(fcmToken) {
  const supabase = createClient(process.env.SUPABASE_URL, process.env.SUPABASE_ANON_KEY);
  await supabase.from('users').update({ fcm_token: null }).eq('fcm_token', fcmToken);
  console.log('🧹 Cleared stale fcm_token from Supabase.');
}

module.exports = { sendPushNotification };
