require('dotenv').config();
const { createClient } = require('@supabase/supabase-js');
const { sendPushNotification } = require('./services/pushNotificationService');

(async () => {
  const supabase = createClient(process.env.SUPABASE_URL, process.env.SUPABASE_ANON_KEY);
  const { data, error } = await supabase
    .from('users')
    .select('id, full_name, fcm_token, created_at')
    .order('created_at', { ascending: false })
    .limit(1)
    .single();

  if (error || !data) {
    console.log('LOOKUP_FAILED', error?.message);
    return;
  }
  console.log('Latest user:', data.full_name, '| has token:', !!data.fcm_token);

  if (!data.fcm_token) {
    console.log('NO_TOKEN_ON_LATEST_USER');
    return;
  }

  const result = await sendPushNotification(data.fcm_token, {
    title: '🔔 Test Notification',
    body: 'If you can see this, Supabase → backend → FCM → your phone all works!',
    data: { type: 'test' },
  });
  console.log('SEND_RESULT', JSON.stringify(result));
})();
