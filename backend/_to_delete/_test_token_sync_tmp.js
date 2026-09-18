require('dotenv').config();
const { createClient } = require('@supabase/supabase-js');
const app = require('./server.js');
const http = require('http');

const supabase = createClient(process.env.SUPABASE_URL, process.env.SUPABASE_ANON_KEY);

(async () => {
  const { data: user } = await supabase
    .from('users').select('id, fcm_token').order('created_at', { ascending: false }).limit(1).single();

  const server = http.createServer(app).listen(0, async () => {
    const port = server.address().port;
    const fakeNewToken = 'TEST_TOKEN_' + Date.now();

    const res = await fetch(`http://localhost:${port}/api/users/${user.id}/fcm-token`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ fcm_token: fakeNewToken }),
    });
    const body = await res.json();
    console.log('RESPONSE', res.status, JSON.stringify(body));

    const { data: check } = await supabase.from('users').select('fcm_token').eq('id', user.id).single();
    console.log('DB_NOW_HAS', check.fcm_token === fakeNewToken ? 'MATCH OK' : 'MISMATCH -> ' + check.fcm_token);

    await supabase.from('users').update({ fcm_token: user.fcm_token }).eq('id', user.id);
    console.log('RESTORED original token');

    server.close(() => process.exit(0));
  });
})();
