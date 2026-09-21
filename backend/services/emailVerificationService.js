const crypto = require('crypto');
const nodemailer = require('nodemailer');

const TOKEN_TTL_MS = 24 * 60 * 60 * 1000; // 24 hours

/** A random hex token + its expiry timestamp (ISO string), for a fresh link. */
function newVerificationToken() {
  return {
    token: crypto.randomBytes(32).toString('hex'),
    expiresAt: new Date(Date.now() + TOKEN_TTL_MS).toISOString(),
  };
}

/**
 * Sends the "confirm your email" message via Gmail SMTP (Nodemailer).
 * Used for both the initial signup verification email and resends
 * (POST /api/resend-verification).
 */
async function sendVerificationEmail(toEmail, token, baseUrl) {
  const gmailUser = process.env.GMAIL_USER;
  const gmailPass = process.env.GMAIL_APP_PASSWORD;

  const link = `${baseUrl}/api/verify-email?token=${token}`;

  const htmlContent = `
    <div style="font-family: sans-serif; max-width: 480px; margin: 0 auto; color: #1a1a1a; padding: 20px;">
      <h2 style="color: #7B2FF7;">✨ Verify your email</h2>
      <p>Tap the button below to confirm <strong>${toEmail}</strong> and finish setting up your Manifest account.</p>
      <p style="margin: 32px 0;">
        <a href="${link}" style="background:#7B2FF7;color:#ffffff;padding:14px 28px;border-radius:10px;text-decoration:none;font-weight:bold;display:inline-block;">
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
  console.log(`   - Provider: Gmail SMTP (${gmailUser || 'Not configured'})`);
  console.log(`   - Link: ${link}`);
  console.log('========================================\n');

  if (!gmailUser || !gmailPass) {
    console.error('❌ [Email Service] GMAIL_USER or GMAIL_APP_PASSWORD not configured.');
    return { success: false, skipped: true, error: 'Gmail SMTP credentials not configured in .env' };
  }

  try {
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

    console.log(`✅ [Email Service] Verification email sent successfully via Gmail SMTP to ${toEmail}`);
    console.log(`📬 [Email Service] Message ID: ${info.messageId}`);
    return { success: true, provider: 'gmail', messageId: info.messageId };
  } catch (error) {
    console.error(`❌ [Email Service] Gmail SMTP failed: ${error.message}`);
    return { success: false, error: error.message };
  }
}

module.exports = { newVerificationToken, sendVerificationEmail };
