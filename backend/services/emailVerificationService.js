const crypto = require('crypto');
const fetch = require('node-fetch');

const TOKEN_TTL_MS = 24 * 60 * 60 * 1000; // 24 hours

// Vercel's serverless functions don't reliably hold a raw SMTP/TLS socket
// open long enough to talk to Gmail (nodemailer + Gmail SMTP was failing
// with "Client network socket disconnected before secure TLS connection
// was established"). Resend sends over a plain HTTPS POST instead, which
// works fine from serverless. See https://resend.com/docs/api-reference/emails/send-email
const RESEND_API_URL = 'https://api.resend.com/emails';

/** A random hex token + its expiry timestamp (ISO string), for a fresh link. */
function newVerificationToken() {
  return {
    token: crypto.randomBytes(32).toString('hex'),
    expiresAt: new Date(Date.now() + TOKEN_TTL_MS).toISOString(),
  };
}

/**
 * Sends the "confirm your email" message. `baseUrl` is this backend's own
 * publicly-reachable origin (e.g. http://192.168.29.88:3000 on a LAN dev
 * setup, or your Vercel URL in production) — the link just hits this same
 * server's GET /api/verify-email endpoint below.
 */
async function sendVerificationEmail(toEmail, token, baseUrl) {
  const apiKey = process.env.RESEND_API_KEY;
  // RESEND_FROM must be either "onboarding@resend.dev" (Resend's shared
  // test sender — only delivers to the email address your Resend account
  // itself is registered with) or an address on a domain you've verified
  // in the Resend dashboard (Domains -> Add Domain -> add the DNS records).
  const fromAddress = process.env.RESEND_FROM || 'Manifest <onboarding@resend.dev>';

  if (!apiKey) {
    console.warn(
      '⚠️  RESEND_API_KEY not set — verification emails are disabled. ' +
      'See backend/.env.'
    );
    return { success: false, skipped: true };
  }

  const link = `${baseUrl}/api/verify-email?token=${token}`;

  try {
    const response = await fetch(RESEND_API_URL, {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${apiKey}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        from: fromAddress,
        to: toEmail,
        subject: 'Verify your email — Manifest',
        html: `
          <div style="font-family: sans-serif; max-width: 480px; margin: 0 auto;">
            <h2>✨ Verify your email</h2>
            <p>Tap the button below to confirm <strong>${toEmail}</strong> and finish setting up your Manifest account.</p>
            <p style="margin: 32px 0;">
              <a href="${link}" style="background:#7B2FF7;color:#fff;padding:14px 28px;border-radius:10px;text-decoration:none;font-weight:bold;">
                Verify Email
              </a>
            </p>
            <p style="color:#888;font-size:13px;">This link expires in 24 hours. If the button doesn't work, paste this into your browser:<br>${link}</p>
            <p style="color:#888;font-size:13px;">Didn't sign up for this? You can ignore this email.</p>
          </div>
        `,
      }),
    });

    if (!response.ok) {
      const errText = await response.text();
      throw new Error(`Resend API ${response.status}: ${errText}`);
    }

    console.log(`📧 Verification email sent to ${toEmail}`);
    return { success: true };
  } catch (error) {
    console.error('❌ Failed to send verification email:', error.message);
    return { success: false, error: error.message };
  }
}

module.exports = { newVerificationToken, sendVerificationEmail };
