const crypto = require('crypto');
const fetch = require('node-fetch');

const nodemailer = require('nodemailer');

const TOKEN_TTL_MS = 24 * 60 * 60 * 1000; // 24 hours
const RESEND_API_URL = 'https://api.resend.com/emails';

/** A random hex token + its expiry timestamp (ISO string), for a fresh link. */
function newVerificationToken() {
  return {
    token: crypto.randomBytes(32).toString('hex'),
    expiresAt: new Date(Date.now() + TOKEN_TTL_MS).toISOString(),
  };
}

/**
 * Sends the "confirm your email" message.
 * First tries Gmail SMTP (free, sends to ANY recipient with no domain verification).
 * If Gmail is not configured or fails, falls back to Resend API.
 */
async function sendVerificationEmail(toEmail, token, baseUrl) {
  const gmailUser = process.env.GMAIL_USER;
  const gmailPass = process.env.GMAIL_APP_PASSWORD;
  const resendApiKey = process.env.RESEND_API_KEY;
  const resendFrom = process.env.RESEND_FROM || 'Manifest <onboarding@resend.dev>';

  const link = `${baseUrl}/api/verify-email?token=${token}`;

  const htmlContent = `
    <div style="font-family: sans-serif; max-width: 480px; margin: 0 auto; color: #1a1a1a;">
      <h2 style="color: #7B2FF7;">✨ Verify your email</h2>
      <p>Tap the button below to confirm <strong>${toEmail}</strong> and finish setting up your Manifest account.</p>
      <p style="margin: 32px 0;">
        <a href="${link}" style="background:#7B2FF7;color:#fff;padding:14px 28px;border-radius:10px;text-decoration:none;font-weight:bold;display:inline-block;">
          Verify Email
        </a>
      </p>
      <p style="color:#888;font-size:13px;">This link expires in 24 hours. If the button doesn't work, paste this into your browser:<br><a href="${link}" style="color:#7B2FF7;">${link}</a></p>
      <p style="color:#888;font-size:13px;">Didn't sign up for this? You can ignore this email.</p>
    </div>
  `;

  console.log('\n========================================');
  console.log(`📧 [Email Service] Attempting to send verification email:`);
  console.log(`   - To: ${toEmail}`);
  console.log(`   - Gmail Configured: ${Boolean(gmailUser && gmailPass)} (${gmailUser || 'NONE'})`);
  console.log(`   - Resend Configured: ${Boolean(resendApiKey)}`);
  console.log(`   - Link: ${link}`);
  console.log('========================================\n');

  // Strategy 1: Gmail SMTP via Nodemailer (Free, delivers to any address)
  if (gmailUser && gmailPass) {
    try {
      console.log(`🚀 [Email Service] Trying Gmail SMTP (${gmailUser})...`);
      const transporter = nodemailer.createTransport({
        service: 'gmail',
        auth: {
          user: gmailUser,
          pass: gmailPass,
        },
      });

      const info = await transporter.sendMail({
        from: `"Manifest" <${gmailUser}>`,
        to: toEmail,
        subject: 'Verify your email — Manifest',
        html: htmlContent,
      });

      console.log(`✅ [Email Service] Verification email sent successfully via Gmail SMTP to ${toEmail}: ${info.messageId}`);
      return { success: true, provider: 'gmail', messageId: info.messageId };
    } catch (gmailError) {
      console.error(`⚠️ [Email Service] Gmail SMTP failed: ${gmailError.message}. Trying Resend fallback...`);
    }
  }

  // Strategy 2: Resend API (HTTPS REST)
  if (resendApiKey) {
    try {
      console.log(`🚀 [Email Service] Trying Resend API (${resendFrom})...`);
      const response = await fetch(RESEND_API_URL, {
        method: 'POST',
        headers: {
          Authorization: `Bearer ${resendApiKey}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          from: resendFrom,
          to: toEmail,
          subject: 'Verify your email — Manifest',
          html: htmlContent,
        }),
      });

      const responseText = await response.text();
      console.log(`📬 [Email Service] Resend Status: ${response.status}`);

      if (!response.ok) {
        console.error(`❌ [Email Service] Resend rejected: ${responseText}`);
        throw new Error(`Resend API ${response.status}: ${responseText}`);
      }

      console.log(`✅ [Email Service] Verification email sent successfully via Resend to ${toEmail}`);
      return { success: true, provider: 'resend', data: responseText };
    } catch (resendError) {
      console.error(`❌ [Email Service] Resend API failed: ${resendError.message}`);
      return { success: false, error: resendError.message };
    }
  }

  console.error('❌ [Email Service] No email provider configured (both Gmail and Resend are unavailable).');
  return { success: false, skipped: true, error: 'No email service credentials configured.' };
}

module.exports = { newVerificationToken, sendVerificationEmail };
