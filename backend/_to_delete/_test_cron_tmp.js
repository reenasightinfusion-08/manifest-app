require('dotenv').config();
const { createClient } = require('@supabase/supabase-js');
const { sendPushNotification } = require('./services/pushNotificationService');

(async () => {
  const supabase = createClient(process.env.SUPABASE_URL, process.env.SUPABASE_ANON_KEY);
  const { data: users, error } = await supabase
    .from('users')
    .select('id, full_name, fcm_token')
    .not('fcm_token', 'is', null);

  if (error) { console.log('QUERY_FAILED', error.message); return; }
  console.log(`Found ${users.length} user(s) with a token.`);

  const results = await Promise.allSettled(
    users.map((u) =>
      sendPushNotification(u.fcm_token, {
        title: '✨ The Cosmos is Waiting',
        body: `${u.full_name || 'Manifestor'}, take a moment today to revisit your manifestation blueprint.`,
        data: { type: 'daily_reminder_test' },
      })
    )
  );
  const sent = results.filter(r => r.status === 'fulfilled' && r.value.success).length;
  console.log(`CRON_LOGIC_RESULT sent=${sent}/${users.length}`);
})();
