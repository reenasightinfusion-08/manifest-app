const crypto = require('crypto');
const nodemailer = require('nodemailer');

const TOKEN_TTL_MS = 24 * 60 * 60 * 1000; // 24 hours

let transporter = null;

function getTransporter() {
  if (transporter) return transporter;

  const user = process.env.GMAIL_USER;
  const pass = process.env.GMAIL_APP_PASSWORD;

  if (!user || !pass) {
    console.warn(
      '⚠️  GMAIL_USER / GMAIL_APP_PASSWORD not set — verification emails are disabled. ' +
      'See backend/.env.'
    );
    return null;
  }

  // Zoho's free plan turned out to block third-party SMTP/IMAP access
  // entirely (535 Authentication Failed, no way around it without a paid
  // plan) — back to Gmail, which allows this on a free account via an
  // app-specific password.
  transporter = nodemailer.createTransport({
    service: 'gmail',
    auth: { user, pass },
  });
  return transporter;
}

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
  const t = getTransporter();
  if (!t) return { success: false, skipped: true };

  const link = `${baseUrl}/api/verify-email?token=${token}`;

  try {
    await t.sendMail({
      from: `"Manifest" <${process.env.GMAIL_USER}>`,
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
    });
    console.log(`📧 Verification email sent to ${toEmail}`);
    return { success: true };
  } catch (error) {
    console.error('❌ Failed to send verification email:', error.message);
    return { success: false, error: error.message };
  }
}

module.exports = { newVerificationToken, sendVerificationEmail };
