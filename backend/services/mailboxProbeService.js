const net = require('net');
const dns = require('dns').promises;

const PROBE_TIMEOUT_MS = 6000;

/**
 * Best-effort check for whether a specific mailbox exists, by opening an
 * SMTP conversation with the domain's mail server and asking RCPT TO — the
 * same handshake a real send would do, just without DATA/QUIT-committing a
 * message.
 *
 * This can only ever be best-effort: Gmail, Outlook, Yahoo and most large
 * providers deliberately don't reveal per-mailbox existence at RCPT time
 * (anti-enumeration/anti-spam), so they'll answer 250 regardless — this
 * probe can't catch a fake address on those domains, and callers must
 * treat "yes" as "not proven fake", not "confirmed real". Smaller mail
 * servers (a company's own Google Workspace/Zoho/self-hosted MX, for
 * example) often do reject unknown recipients at RCPT — that's the case
 * this actually catches, e.g. a typo'd or made-up address on your own
 * company domain.
 *
 * Returns:
 *   'exists'      — server explicitly accepted the recipient (2xx on RCPT)
 *   'not_found'   — server explicitly rejected the recipient (550/551/553
 *                    "no such user" family)
 *   'inconclusive' — anything else: connection refused, timeout, greylist,
 *                    auth-required relay, unexpected response, etc. Do NOT
 *                    treat this as proof of anything either way.
 */
async function probeMailbox(email, { mailFrom } = {}) {
  const atIndex = email.lastIndexOf('@');
  if (atIndex === -1) return 'inconclusive';
  const domain = email.slice(atIndex + 1);
  const from = mailFrom || `verify@${domain}`;

  let mxHost;
  try {
    const records = await dns.resolveMx(domain);
    if (!records || records.length === 0) return 'inconclusive';
    records.sort((a, b) => a.priority - b.priority);
    mxHost = records[0].exchange;
  } catch {
    return 'inconclusive';
  }

  return new Promise((resolve) => {
    let settled = false;
    let buffer = '';
    let step = 0; // 0=banner,1=EHLO,2=MAIL FROM,3=RCPT TO

    const finish = (result) => {
      if (settled) return;
      settled = true;
      try {
        socket.write('QUIT\r\n');
      } catch {
        /* ignore */
      }
      socket.destroy();
      resolve(result);
    };

    const socket = net.createConnection({ host: mxHost, port: 25 });
    socket.setTimeout(PROBE_TIMEOUT_MS);

    socket.on('timeout', () => finish('inconclusive'));
    socket.on('error', () => finish('inconclusive'));

    socket.on('data', (chunk) => {
      buffer += chunk.toString('utf8');
      // Wait for a full reply line (SMTP multi-line replies use "250-" for
      // continuation and "250 " for the final line).
      const lines = buffer.split('\r\n').filter(Boolean);
      const last = lines[lines.length - 1];
      if (!last || /^\d{3}-/.test(last)) return; // more lines coming
      const code = parseInt(last.slice(0, 3), 10);
      buffer = '';

      if (step === 0) {
        if (code !== 220) return finish('inconclusive');
        socket.write(`EHLO ${domain}\r\n`);
        step = 1;
      } else if (step === 1) {
        if (code >= 400) return finish('inconclusive');
        socket.write(`MAIL FROM:<${from}>\r\n`);
        step = 2;
      } else if (step === 2) {
        if (code >= 400) return finish('inconclusive');
        socket.write(`RCPT TO:<${email}>\r\n`);
        step = 3;
      } else if (step === 3) {
        if (code >= 200 && code < 300) return finish('exists');
        if (code === 550 || code === 551 || code === 553) return finish('not_found');
        return finish('inconclusive');
      }
    });
  });
}

module.exports = { probeMailbox };
