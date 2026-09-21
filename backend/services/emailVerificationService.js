const crypto = require('crypto');
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
 * Sends email via Gmail SMTP (Nodemailer).
 */
async function sendViaGmail(toEmail, subject, htmlContent) {
  const user = process.env.GMAIL_USER;
  const pass = process.env.GMAIL_APP_PASSWORD;
  if (!user || !pass) {
    throw new Error('GMAIL_USER or GMAIL_APP_PASSWORD not set in environment.');
  }

  const transporter = nodemailer.createTransport({
    host: 'smtp.gmail.com',
    port: 465,
    secure: true,
    auth: { user, pass },
    connectionTimeout: 10000,
    greetingTimeout: 5000,
    socketTimeout: 15000,
  });

  const info = await transporter.sendMail({
    from: `"Manifest" <${user}>`,
    to: toEmail,
    subject,
    html: htmlContent,
  });

  console.log(`📧 Verification email delivered via Gmail SMTP to ${toEmail} (ID: ${info.messageId})`);
  return { success: true, method: 'gmail' };
}

/**
 * Sends email via Resend HTTPS API.
 */
async function sendViaResend(toEmail, subject, htmlContent) {
  const apiKey = process.env.RESEND_API_KEY;
  const fromAddress = process.env.RESEND_FROM || 'Manifest <onboarding@resend.dev>';

  if (!apiKey) {
    throw new Error('RESEND_API_KEY not set.');
  }

  const response = await fetch(RESEND_API_URL, {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${apiKey}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      from: fromAddress,
      to: toEmail,
      subject,
      html: htmlContent,
    }),
  });

  if (!response.ok) {
    const errText = await response.text();
    throw new Error(`Resend API ${response.status}: ${errText}`);
  }

  console.log(`📧 Verification email delivered via Resend to ${toEmail}`);
  return { success: true, method: 'resend' };
}

/**
 * Sends the "confirm your email" message. Tries Gmail SMTP or Resend
 * with automatic fallback so emails are reliably delivered to any address.
 */
async function sendVerificationEmail(toEmail, token, baseUrl) {
  const link = `${baseUrl}/api/verify-email?token=${token}`;
  const subject = 'Verify your email — Manifest';
  const html = `
    <div style="font-family: sans-serif; max-width: 480px; margin: 0 auto; padding: 20px; color: #333;">
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

  const isResendSandbox = !process.env.RESEND_FROM || process.env.RESEND_FROM.includes('resend.dev');
  const errors = [];

  // If Resend is configured with a verified custom domain, try Resend first.
  // If Resend is on default test sandbox (resend.dev), try Gmail first because
  // Resend sandbox will reject any recipient except the Resend account owner.
  if (!isResendSandbox && process.env.RESEND_API_KEY) {
    try {
      return await sendViaResend(toEmail, subject, html);
    } catch (resendErr) {
      console.warn('⚠️ Resend failed, attempting Gmail SMTP fallback:', resendErr.message);
      errors.push(`Resend: ${resendErr.message}`);
    }
  }

  // Try Gmail SMTP
  if (process.env.GMAIL_USER && process.env.GMAIL_APP_PASSWORD) {
    try {
      return await sendViaGmail(toEmail, subject, html);
    } catch (gmailErr) {
      console.warn('⚠️ Gmail SMTP failed:', gmailErr.message);
      errors.push(`Gmail: ${gmailErr.message}`);
    }
  }

  // If Gmail failed or wasn't configured, try Resend as a last resort
  if (isResendSandbox && process.env.RESEND_API_KEY) {
    try {
      return await sendViaResend(toEmail, subject, html);
    } catch (resendErr) {
      console.warn('⚠️ Resend failed:', resendErr.message);
      errors.push(`Resend: ${resendErr.message}`);
    }
  }

  const finalError = errors.length > 0 ? errors.join(' | ') : 'No email provider configured';
  console.error('❌ Failed to send verification email:', finalError);
  return { success: false, error: finalError };
}

module.exports = { newVerificationToken, sendVerificationEmail };

