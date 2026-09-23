require('dotenv').config();
const express = require('express');
const { createClient } = require('@supabase/supabase-js');
const cors = require('cors');
const bodyParser = require('body-parser');
const { sendPushNotification } = require('./services/pushNotificationService');
const bcrypt = require('bcryptjs');
const { newVerificationToken, sendVerificationEmail } = require('./services/emailVerificationService');
const dns = require('dns').promises;
const { probeMailbox } = require('./services/mailboxProbeService');


const app = express();
app.set('trust proxy', 1);
const port = process.env.PORT || 3000;

function getBaseUrl(req) {
  if (process.env.PUBLIC_BACKEND_URL) return process.env.PUBLIC_BACKEND_URL;
  const proto = req.headers['x-forwarded-proto'] || req.protocol || 'https';
  return `${proto}://${req.get('host')}`;
}

// Supabase Configuration
const supabaseUrl = process.env.SUPABASE_URL;
const supabaseKey = process.env.SUPABASE_ANON_KEY;

if (!supabaseUrl || supabaseUrl === 'YOUR_SUPABASE_URL_HERE') {
  console.error('\x1b[31m%s\x1b[0m', 'CRITICAL ERROR: SUPABASE_URL is missing or placeholder! Check your backend/.env file.');
}

const supabase = createClient(supabaseUrl, supabaseKey);

app.use(cors());
app.use(bodyParser.json());

// ── Admin Restriction Logic ──────────────────────────────────────────
const ALLOWED_EMAIL = 'anandyadav21219@gmail.com';
const ALLOWED_NAME = 'Anand Yadav';

// Simple middleware to protect destructive routes
const restrictToAdmin = (req, res, next) => {
  const { user_email, name } = req.body;
  // If we are searching or fetching, we allow it (for now)
  // But for POST/DELETE, we check if it matches the admin
  if (req.method === 'POST' || req.method === 'DELETE') {
    const isAdmin = (user_email === ALLOWED_EMAIL) || (name === ALLOWED_NAME);
    if (!isAdmin && req.path !== '/api/users') {
      // Deep check for user_id related to admin if needed, 
      // but for a simple lock, checking the name/email is sufficient for this stage.
    }
  }
  next();
};

// Health Check
app.get('/', (req, res) => {
  res.send('Manifest Cosmic Backend is Live! ✨');
});

// App Version & Force Update Config
app.get('/api/app-version', (req, res) => {
  res.json({
    success: true,
    min_version: process.env.MIN_APP_VERSION || '1.0.0',
    latest_version: process.env.LATEST_APP_VERSION || '1.0.0',
    force_update: process.env.FORCE_UPDATE_ENABLED === 'true',
    update_url: process.env.UPDATE_URL_ANDROID || 'https://play.google.com/store/apps/details?id=com.manifest.app',
    title: process.env.UPDATE_TITLE || 'Update Required',
    message: process.env.UPDATE_MESSAGE || 'A new version of Manifest is available with critical improvements. Please update to continue.',
    release_notes: process.env.UPDATE_RELEASE_NOTES || 'Performance enhancements and bug fixes.',
  });
});

// ─── Daily Reminder Cron ───────────────────────────────────────────────────
// Vercel Cron hits this on a schedule (see vercel.json "crons"). It's a GET
// with no user session, so we lock it down with a shared secret instead of
// auth — Vercel automatically sends "Authorization: Bearer <CRON_SECRET>"
// when CRON_SECRET is set in the project's env vars.
app.get('/api/cron/daily-reminder', async (req, res) => {
  const expected = process.env.CRON_SECRET;
  if (expected) {
    const authHeader = req.headers.authorization || '';
    if (authHeader !== `Bearer ${expected}`) {
      return res.status(401).json({ success: false, message: 'Unauthorized' });
    }
  } else {
    console.warn('⚠️  CRON_SECRET not set — /api/cron/daily-reminder is unprotected!');
  }

  try {
    const { data: users, error } = await supabase
      .from('users')
      .select('id, full_name, fcm_token')
      .not('fcm_token', 'is', null)
      .eq('notifications_enabled', true)
      .eq('manifestation_tips_enabled', true);

    if (error) throw error;

    console.log(`⏰ Daily reminder cron: notifying ${users.length} user(s)...`);

    const results = await Promise.allSettled(
      users.map((u) =>
        sendPushNotification(u.fcm_token, {
          title: '✨ The Cosmos is Waiting',
          body: `${u.full_name || 'Manifestor'}, take a moment today to revisit your manifestation blueprint.`,
          data: { type: 'daily_reminder' },
        })
      )
    );

    const sent = results.filter((r) => r.status === 'fulfilled' && r.value.success).length;
    res.json({ success: true, total: users.length, sent });
  } catch (error) {
    console.error('❌ Daily reminder cron failed:', error.message);
    res.status(500).json({ success: false, message: error.message });
  }
});

// Lightweight FCM token sync — used after logging into an existing account
// on a new install (old token is dead), and whenever Firebase rotates a
// device's token on its own. Deliberately separate from POST /api/users so
// a token refresh never re-triggers the AI profile validator.
app.post('/api/users/:id/fcm-token', async (req, res) => {
  const { id } = req.params;
  const { fcm_token } = req.body;

  if (!fcm_token) {
    return res.status(400).json({ success: false, message: 'fcm_token is required.' });
  }

  try {
    const { data, error } = await supabase
      .from('users')
      .update({ fcm_token })
      .eq('id', id)
      .select();

    if (error) throw error;
    if (!data || data.length === 0) {
      return res.status(404).json({ success: false, message: 'User not found.' });
    }

    console.log(`🔄 fcm_token synced for user ${id}`);
    res.json({ success: true, data: data[0] });
  } catch (error) {
    console.error('FCM token sync error:', error.message);
    res.status(500).json({ success: false, message: error.message });
  }
});

// Lightweight notification-preference sync — called the moment the user
// flips "Push Notifications" or "Manifestation Tips" in-app, so the
// server-side daily reminder cron (and the welcome/plan-ready pushes
// below) actually know not to notify someone who opted out. Deliberately
// separate from POST /api/users for the same reason fcm-token is: no need
// to re-run the AI profile validator for a simple toggle flip.
app.post('/api/users/:id/notification-prefs', async (req, res) => {
  const { id } = req.params;
  const { notifications_enabled, manifestation_tips_enabled } = req.body;

  const update = {};
  if (typeof notifications_enabled === 'boolean') {
    update.notifications_enabled = notifications_enabled;
  }
  if (typeof manifestation_tips_enabled === 'boolean') {
    update.manifestation_tips_enabled = manifestation_tips_enabled;
  }
  if (Object.keys(update).length === 0) {
    return res.status(400).json({
      success: false,
      message: 'Provide notifications_enabled and/or manifestation_tips_enabled as booleans.',
    });
  }

  try {
    const { data, error } = await supabase
      .from('users')
      .update(update)
      .eq('id', id)
      .select();

    if (error) throw error;
    if (!data || data.length === 0) {
      return res.status(404).json({ success: false, message: 'User not found.' });
    }

    console.log(`🔔 notification prefs synced for user ${id}:`, update);
    res.json({ success: true, data: data[0] });
  } catch (error) {
    console.error('Notification prefs sync error:', error.message);
    res.status(500).json({ success: false, message: error.message });
  }
});

// Create/Update User API
// Pre-check used by the app right after the email field on signup, so
// "this email is taken" / "that domain doesn't exist" shows immediately —
// instead of only after all 4 onboarding steps are filled in and posted.
app.get('/api/check-email', async (req, res) => {
  const email = typeof req.query.email === 'string' ? req.query.email.trim().toLowerCase() : '';
  const EMAIL_RE = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

  if (!email || !EMAIL_RE.test(email)) {
    return res.json({ available: false, reason: 'invalid_format', message: 'Enter a valid email address.' });
  }

  const domain = email.split('@')[1];
  try {
    const records = await dns.resolveMx(domain);
    if (!records || records.length === 0) {
      return res.json({ available: false, reason: 'domain_not_found', message: "That email domain doesn't seem to exist — check for a typo." });
    }
  } catch (err) {
    // ENOTFOUND / ENODATA — domain has no mail server, so mail can't be
    // delivered there at all.
    return res.json({ available: false, reason: 'domain_not_found', message: "That email domain doesn't seem to exist — check for a typo." });
  }

  // Best-effort check that the specific mailbox exists, not just the
  // domain. Gmail/Outlook/Yahoo and most big providers always answer
  // "exists" here on purpose (anti-enumeration), so this only ever
  // catches what it catches — e.g. a typo'd or made-up address on a
  // smaller mail server that does reject unknown recipients. Anything
  // short of an explicit "no such user" (mailboxStatus === 'not_found')
  // is let through, since a false positive here would block real users.
  try {
    const mailboxStatus = await probeMailbox(email, { mailFrom: process.env.GMAIL_USER });
    if (mailboxStatus === 'not_found') {
      return res.json({
        available: false,
        reason: 'mailbox_not_found',
        message: "That mailbox doesn't seem to exist — double-check the address.",
      });
    }
  } catch (probeErr) {
    console.error('Mailbox probe error (non-fatal):', probeErr.message);
  }

  try {
    const { data: existing, error } = await supabase
      .from('users')
      .select('id, email_verified')
      .ilike('email', email);
    if (error) throw error;
    if (existing && existing.length > 0) {
      const isVerified = existing.some((u) => u.email_verified !== false);
      if (isVerified) {
        return res.json({ available: false, reason: 'already_exists', message: 'An account with this email already exists.' });
      }
    }

    // Unverified signups in pending_signups do NOT block the user.
    // Until an email is verified, the user is free to start over or re-register.
  } catch (error) {
    console.error('check-email lookup error:', error.message);
    return res.status(500).json({ available: false, reason: 'server_error', message: 'Could not verify email right now — try again.' });
  }

  res.json({ available: true });
});

app.post('/api/users', async (req, res) => {
  console.log('Incoming user update/creation:', req.body);
  const {
    id, full_name, avatar_url, personal_answers, family_answers, professional_answers,
    email, password, fcm_token, notifications_enabled, manifestation_tips_enabled,
    // Set only by ProfileSetupScreen's final "Complete My Profile" call —
    // signup-time and any other profile update never sends this. That's
    // what welcome_notified_sent below keys off to fire the welcome push
    // exactly once, at the point the account is genuinely ready.
    complete_profile,
  } = req.body;

  // Security Lock: Temporarily disabled to allow new user creation
  /*
  if (full_name !== ALLOWED_NAME && email !== ALLOWED_EMAIL) {
    return res.status(403).json({ 
      success: false, 
      message: 'Access Denied: Only the authorized curator can modify this hub.' 
    });
  }
  */

  if (!full_name) {
    return res.status(400).json({ success: false, message: 'Name is required.' });
  }

  // Email/password are the login credentials now (replacing the old 4-digit
  // passcode). Required on signup; on a profile update (id present) they're
  // only re-validated if the client actually sent them.
  const normalizedEmail = typeof email === 'string' ? email.trim().toLowerCase() : email;
  const EMAIL_RE = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

  if (!id) {
    if (!normalizedEmail || !EMAIL_RE.test(normalizedEmail)) {
      return res.status(400).json({ success: false, message: 'A valid email is required.' });
    }
    if (!password || password.length < 6) {
      return res.status(400).json({ success: false, message: 'Password must be at least 6 characters.' });
    }
  } else {
    if (normalizedEmail && !EMAIL_RE.test(normalizedEmail)) {
      return res.status(400).json({ success: false, message: 'A valid email is required.' });
    }
    if (password && password.length < 6) {
      return res.status(400).json({ success: false, message: 'Password must be at least 6 characters.' });
    }
  }

  let password_hash;
  try {
    if (password) {
      password_hash = await bcrypt.hash(password, 10);
    }

    if (normalizedEmail) {
      // Uniqueness check — only verified accounts cannot be re-registered.
      const { data: existing, error: emailLookupError } = await supabase
        .from('users')
        .select('id, email_verified')
        .ilike('email', normalizedEmail);
      if (emailLookupError) throw emailLookupError;
      const takenByAnotherAccount = (existing || []).some((u) => u.id !== id && u.email_verified !== false);
      if (takenByAnotherAccount) {
        return res.status(409).json({ success: false, message: 'An account with this email already exists.' });
      }

      // New signup (id absent) — clean up any previous unverified pending signup
      // or unverified account for this email so the user can start fresh.
      if (!id) {
        await supabase
          .from('pending_signups')
          .delete()
          .ilike('email', normalizedEmail)
          .is('promoted_to_user_id', null);

        await supabase
          .from('users')
          .delete()
          .ilike('email', normalizedEmail)
          .eq('email_verified', false);
      }
    }
  } catch (error) {
    console.error('Email/password validation error:', error.message);
    return res.status(500).json({ success: false, message: `Failed to validate credentials: ${error.message}` });
  }

  // ── AI Profile Validation ──────────────────────────────────────────────
  try {
    const allAnswers = [
      ...(personal_answers || []),
      ...(family_answers || []),
      ...(professional_answers || [])
    ].filter(a => a && a.trim().length > 0);

    // Only run expensive AI validation on brand-new signups (!id) to catch spam bots.
    // Existing users editing answers in their profile save immediately without a 5-10s LLM delay.
    if (!id && allAnswers.length > 0) {
      console.log(`🔍 Validating profile answers for new user: "${full_name}"...`);
      const validationPrompt = `
        You are a strict Profile Validator. Analyze the user's answers to an onboarding survey and decide if they are valid, meaningful, and appropriate.

        USER ANSWERS:
        ${allAnswers.join(' | ')}

        A VALID profile:
        - Contains real words, meaningful aspirations or even very short sensible responses.
        - Is safe, respectful, and human-like.

        AN INVALID profile is one of these:
        - Random gibberish, keyboard mashing (e.g. "asdfgh", "123", "aaaa").
        - Profanity, abusive language, or highly inappropriate/unsafe content.
        - Nonsense meant to bypass the system.

        Respond ONLY with this JSON:
        {
          "is_valid": true or false,
          "reason": "If invalid: a friendly, 1-sentence explanation of why these answers cannot be accepted."
        }
      `;

      const validation = await generateAI(validationPrompt, 'You are a strict profile validator. Return only JSON.');
      console.log(`🔍 Profile Validation result: ${JSON.stringify(validation)}`);

      if (validation && validation.is_valid === false) {
        return res.status(400).json({
          success: false,
          message: validation.reason || 'Your answers do not seem valid or appropriate. Please provide thoughtful responses.'
        });
      }
    }
  } catch (aiErr) {
    console.error("⚠️ AI Validation failed or returned invalid format, bypassing for now...", aiErr.message);
  }
  // ────────────────────────────────────────────────────────────────────────

  try {
    let result;
    if (id) {
      // UPDATE existing user
      const { data, error } = await supabase
        .from('users')
        .update({
          full_name,
          avatar_url,
          personal_answers,
          family_answers,
          professional_answers,
          ...(normalizedEmail ? { email: normalizedEmail } : {}),
          ...(password_hash ? { password_hash } : {}),
          ...(fcm_token ? { fcm_token } : {}),
          ...(typeof notifications_enabled === 'boolean' ? { notifications_enabled } : {}),
          ...(typeof manifestation_tips_enabled === 'boolean' ? { manifestation_tips_enabled } : {}),
        })
        .eq('id', id)
        .select();

      if (error) {
        console.error('Supabase Update Error:', error);
        throw error;
      }
      result = (data && data.length > 0) ? data[0] : null;

      // Welcome push — only on the call that finishes profile setup.
      // No DB-side "already sent" flag here (would need a schema change
      // we can't safely run from the app's anon key) — this relies on the
      // client only ever sending complete_profile:true once, from
      // ProfileSetupScreen's final "Complete My Profile" tap. If that
      // ever needs to become resend-proof, add a nullable
      // welcome_notified_at timestamptz column to users and check it here.
      if (
        complete_profile === true &&
        result?.fcm_token &&
        result?.notifications_enabled !== false
      ) {
        sendPushNotification(result.fcm_token, {
          title: '✨ Welcome to Your Cosmic Journey',
          body: `${result.full_name || 'Manifestor'}, your manifestation space is ready. Let's set your first intention.`,
          data: { type: 'welcome' },
        }).catch((err) => console.error('Welcome push error (non-fatal):', err.message));
      }
    } else {
      // INSERT — a brand-new signup does NOT become a `users` row yet.
      // It's held in `pending_signups` until the emailed link is tapped
      // (see GET /api/verify-email, which is what actually creates the
      // `users` row). This is what makes an unverified/fake-email signup
      // genuinely not exist as a user — not just blocked from logging in.
      const { token: verificationToken, expiresAt: verificationExpires } =
        newVerificationToken();
      const { data, error } = await supabase
        .from('pending_signups')
        .insert([
          {
            full_name,
            avatar_url,
            personal_answers,
            family_answers,
            professional_answers,
            email: normalizedEmail,
            password_hash,
            fcm_token: fcm_token || null,
            ...(typeof notifications_enabled === 'boolean' ? { notifications_enabled } : {}),
            ...(typeof manifestation_tips_enabled === 'boolean' ? { manifestation_tips_enabled } : {}),
            verification_token: verificationToken,
            verification_expires: verificationExpires,
            created_at: new Date().toISOString()
          }
        ])
        .select();

      if (error) {
        console.error('Supabase pending_signups Insert Error:', error);
        throw error;
      }
      result = (data && data.length > 0) ? data[0] : null;

      // Welcome push happens later still — see the complete_profile branch
      // above, which only ever runs on a real `users` row anyway.

      // Verification email — must await on serverless (Vercel) so the runtime
      // does not terminate/freeze before the SMTP connection completes.
      if (result?.email) {
        const baseUrl = getBaseUrl(req);
        console.log(`\n📨 [POST /api/users] New signup registered: ${result.email}. Sending initial verification email...`);
        try {
          const sendRes = await sendVerificationEmail(result.email, verificationToken, baseUrl);
          console.log(`📨 [POST /api/users] Initial verification email result for ${result.email}:`, sendRes);
        } catch (err) {
          console.error(`❌ [POST /api/users] Initial verification email error for ${result.email}:`, err.message);
        }
      }
    }

    // Never echo sensitive fields back to the client.
    if (result) {
      delete result.password_hash;
      delete result.email_verification_token;
      delete result.email_verification_expires;
      delete result.verification_token;
      delete result.verification_expires;
    }

    res.status(id ? 200 : 201).json({
      success: true,
      message: id ? 'Cosmic identity updated!' : 'User identity established!',
      data: result
    });
  } catch (error) {
    console.error('API Error details:', {
      message: error.message,
      code: error.code,
      details: error.details,
      hint: error.hint
    });
    res.status(500).json({
      success: false,
      message: `Failed to sync identity: ${error.message || 'Unknown Error'}`,
      error: error.message,
      code: error.code
    });
  }
});

// Login by email + password (replaces the old name-based "search" lookup).
app.post('/api/login', async (req, res) => {
  const { email, password } = req.body;
  if (!email || !password) {
    return res.status(400).json({ success: false, message: 'Email and password are required.' });
  }

  try {
    const normalizedEmail = email.trim().toLowerCase();
    const { data: matches, error } = await supabase
      .from('users')
      .select('*')
      .ilike('email', normalizedEmail)
      .limit(1);

    if (error) throw error;
    const user = matches && matches[0];

    // No verified `users` row for this email — before failing outright,
    // check whether it's actually a still-pending signup (right password,
    // link just never tapped) so that case gets the helpful "verify your
    // email" response instead of a generic "invalid credentials".
    if (!user || !user.password_hash) {
      const { data: pendingMatches, error: pendingError } = await supabase
        .from('pending_signups')
        .select('id, email, password_hash')
        .ilike('email', normalizedEmail)
        .is('promoted_to_user_id', null)
        .limit(1);
      if (pendingError) throw pendingError;
      const pending = pendingMatches && pendingMatches[0];

      if (pending && pending.password_hash) {
        const pendingPasswordMatches = await bcrypt.compare(password, pending.password_hash);
        if (pendingPasswordMatches) {
          return res.status(403).json({
            success: false,
            message: 'Please verify your email before logging in.',
            email_verified: false,
            data: { id: pending.id, email: pending.email },
          });
        }
      }

      return res.status(401).json({ success: false, message: 'Invalid email or password.' });
    }

    const passwordMatches = await bcrypt.compare(password, user.password_hash);
    if (!passwordMatches) {
      return res.status(401).json({ success: false, message: 'Invalid email or password.' });
    }

    delete user.password_hash;
    delete user.email_verification_token;
    delete user.email_verification_expires;

    // Correct password, but the email link was never tapped — block entry.
    // Still hand back the id/email (nothing sensitive) so the app can show
    // a "verify your email" screen and let them resend/poll without
    // asking for the password again.
    if (!user.email_verified) {
      return res.status(403).json({
        success: false,
        message: 'Please verify your email before logging in.',
        email_verified: false,
        data: { id: user.id, email: user.email },
      });
    }

    res.json({ success: true, data: user });
  } catch (error) {
    console.error('Login error:', error.message);
    res.status(500).json({ success: false, message: error.message });
  }
});

// The link tapped from the verification email. Serves a plain HTML page
// (not JSON) since this is opened directly in a browser.
app.get('/api/verify-email', async (req, res) => {
  const { token } = req.query;
  console.log(`\n🔗 [GET /api/verify-email] Verification link accessed with token: "${token ? token.substring(0, 8) + '...' : 'NONE'}"`);
  const htmlPage = (title, message, ok) => res.status(ok ? 200 : 400).send(`
    <!DOCTYPE html>
    <html>
      <head><meta charset="utf-8"><title>${title}</title>
      <meta name="viewport" content="width=device-width, initial-scale=1">
      </head>
      <body style="font-family: sans-serif; text-align: center; padding: 60px 20px; background: #faf8ff;">
        <div style="font-size: 48px;">${ok ? '✅' : '⚠️'}</div>
        <h2>${title}</h2>
        <p style="color: #666; max-width: 360px; margin: 0 auto;">${message}</p>
      </body>
    </html>
  `);

  if (!token) {
    return htmlPage('Missing link', 'This verification link looks incomplete.', false);
  }

  try {
    // New-flow signups: the token lives on a pending_signups row, and
    // tapping the link is what promotes it into a real `users` row for
    // the first time — an unverified signup was never a `users` row at
    // all, so there's nothing to "flip" until this happens.
    const { data: pendingMatches, error: pendingError } = await supabase
      .from('pending_signups')
      .select('*')
      .eq('verification_token', token)
      .limit(1);
    if (pendingError) throw pendingError;
    const pending = pendingMatches && pendingMatches[0];

    if (pending) {
      if (pending.promoted_to_user_id) {
        // Already verified earlier — tapping an old/reused link again.
        return htmlPage('Email verified!', 'Return to the Manifest app and tap Continue.', true);
      }

      if (pending.verification_expires && new Date(pending.verification_expires) < new Date()) {
        return htmlPage(
          'Link expired',
          'This verification link expired. Go back to the app and tap "Resend email" to get a new one.',
          false
        );
      }

      const { data: created, error: insertError } = await supabase
        .from('users')
        .insert([
          {
            full_name: pending.full_name,
            avatar_url: pending.avatar_url,
            personal_answers: pending.personal_answers,
            family_answers: pending.family_answers,
            professional_answers: pending.professional_answers,
            email: pending.email,
            password_hash: pending.password_hash,
            fcm_token: pending.fcm_token,
            notifications_enabled: pending.notifications_enabled,
            manifestation_tips_enabled: pending.manifestation_tips_enabled,
            email_verified: true,
            created_at: new Date().toISOString(),
          },
        ])
        .select();

      if (insertError) throw insertError;
      const newUser = created && created[0];
      if (!newUser) throw new Error('User row was not created from pending signup.');

      // Kept, not deleted — the app polls verification-status with the
      // pending id it already has, and needs this row to resolve that id
      // to the real users.id it should switch to (see
      // GET /api/users/:id/verification-status below).
      const { error: promoteError } = await supabase
        .from('pending_signups')
        .update({ promoted_to_user_id: newUser.id })
        .eq('id', pending.id);
      if (promoteError) throw promoteError;

      // Welcome push happens later still, once the whole profile is
      // filled in — see the complete_profile branch of POST /api/users.
      return htmlPage('Email verified!', 'Return to the Manifest app and tap Continue.', true);
    }

    // Fallback: an already-existing `users` row from before this table
    // existed, still carrying its own verification token.
    const { data: matches, error } = await supabase
      .from('users')
      .select('id, email_verification_expires')
      .eq('email_verification_token', token)
      .limit(1);

    if (error) throw error;
    const user = matches && matches[0];

    if (!user) {
      return htmlPage(
        'Invalid link',
        "This verification link isn't valid, or was already used. Request a new one from the app if you still need it.",
        false
      );
    }

    if (user.email_verification_expires && new Date(user.email_verification_expires) < new Date()) {
      return htmlPage(
        'Link expired',
        'This verification link expired. Go back to the app and tap "Resend email" to get a new one.',
        false
      );
    }

    const { error: updateError } = await supabase
      .from('users')
      .update({
        email_verified: true,
        email_verification_token: null,
        email_verification_expires: null,
      })
      .eq('id', user.id);

    if (updateError) throw updateError;

    return htmlPage('Email verified!', 'Return to the Manifest app and tap Continue.', true);
  } catch (error) {
    console.error('Email verification error:', error.message);
    return htmlPage('Something went wrong', 'Please try the link again in a moment.', false);
  }
});

// Lets the app poll whether the emailed link has been tapped yet, without
// re-sending the password.
// The id passed here is whatever the app currently has — which, right
// after signup, is a pending_signups id, not a real users id yet. This
// resolves both: an already-real users.id (old-flow accounts, or after
// the client has already picked up the swap), and a pending id (new-flow
// signups) — in the pending case, once promoted it hands back the real
// users.id the app should now remember instead.
app.get('/api/users/:id/verification-status', async (req, res) => {
  const { id } = req.params;
  try {
    const { data: userRow, error: userError } = await supabase
      .from('users')
      .select('id, email_verified')
      .eq('id', id)
      .maybeSingle();
    if (userError) throw userError;

    if (userRow) {
      return res.json({
        success: true,
        data: { email_verified: !!userRow.email_verified, id: userRow.id },
      });
    }

    const { data: pendingRow, error: pendingError } = await supabase
      .from('pending_signups')
      .select('id, promoted_to_user_id')
      .eq('id', id)
      .maybeSingle();
    if (pendingError) throw pendingError;

    if (!pendingRow) {
      return res.status(404).json({ success: false, message: 'User not found.' });
    }

    if (pendingRow.promoted_to_user_id) {
      return res.json({
        success: true,
        data: { email_verified: true, id: pendingRow.promoted_to_user_id },
      });
    }

    res.json({ success: true, data: { email_verified: false, id: pendingRow.id } });
  } catch (error) {
    console.error('Verification status error:', error.message);
    res.status(500).json({ success: false, message: error.message });
  }
});

// Re-sends the verification email — the link's 24h expiry, or a lost
// Re-sends the verification email — the link's 24h expiry, or a lost
// first email, are the two reasons someone would need this.
app.post('/api/resend-verification', async (req, res) => {
  const { email } = req.body;
  console.log(`\n📨 [POST /api/resend-verification] Request received to resend verification email for: "${email}"`);
  if (!email) {
    console.warn('⚠️ [POST /api/resend-verification] Email parameter was missing in request body.');
    return res.status(400).json({ success: false, message: 'Email is required.' });
  }

  try {
    const normalizedEmail = email.trim().toLowerCase();
    console.log(`🔍 [POST /api/resend-verification] Checking pending_signups for: ${normalizedEmail}`);

    // New-flow: still-pending (unpromoted) signup for this email.
    const { data: pendingMatches, error: pendingError } = await supabase
      .from('pending_signups')
      .select('id, email')
      .ilike('email', normalizedEmail)
      .is('promoted_to_user_id', null)
      .limit(1);
    if (pendingError) {
      console.error('❌ [POST /api/resend-verification] Supabase pending_signups query error:', pendingError);
      throw pendingError;
    }
    const pending = pendingMatches && pendingMatches[0];

    if (pending) {
      console.log(`📋 [POST /api/resend-verification] Found pending signup (id: ${pending.id}). Generating fresh token...`);
      const { token: verificationToken, expiresAt: verificationExpires } = newVerificationToken();
      const { error: updateError } = await supabase
        .from('pending_signups')
        .update({
          verification_token: verificationToken,
          verification_expires: verificationExpires,
        })
        .eq('id', pending.id);
      if (updateError) {
        console.error('❌ [POST /api/resend-verification] Failed to update pending_signups token:', updateError);
        throw updateError;
      }

      const baseUrl = getBaseUrl(req);
      console.log(`📧 [POST /api/resend-verification] Calling sendVerificationEmail for pending signup ${pending.email}...`);
      const sendResult = await sendVerificationEmail(pending.email, verificationToken, baseUrl);
      console.log(`📬 [POST /api/resend-verification] sendVerificationEmail result:`, sendResult);

      if (!sendResult.success) {
        return res.status(500).json({
          success: false,
          message: sendResult.skipped
            ? 'Email sending is not configured on the server yet.'
            : (sendResult.error ? `Could not send email: ${sendResult.error}` : 'Could not send the email — try again in a moment.'),
        });
      }

      return res.json({ success: true, message: 'Verification email resent — check your inbox.' });
    }

    console.log(`🔍 [POST /api/resend-verification] Not in pending_signups. Checking users table for: ${normalizedEmail}`);
    // Fallback: an already-existing `users` row from before this table
    // existed, still carrying its own verification token.
    const { data: matches, error } = await supabase
      .from('users')
      .select('id, email, email_verified')
      .ilike('email', normalizedEmail)
      .limit(1);

    if (error) {
      console.error('❌ [POST /api/resend-verification] Supabase users query error:', error);
      throw error;
    }
    const user = matches && matches[0];

    if (!user) {
      console.warn(`⚠️ [POST /api/resend-verification] No account found in pending_signups or users for: ${normalizedEmail}`);
      return res.status(404).json({ success: false, message: 'No account with that email.' });
    }
    if (user.email_verified) {
      console.log(`ℹ️ [POST /api/resend-verification] User ${normalizedEmail} is already verified.`);
      return res.json({ success: true, message: 'That email is already verified — just log in.' });
    }

    console.log(`📋 [POST /api/resend-verification] Found unverified user (id: ${user.id}). Generating fresh token...`);
    const { token: verificationToken, expiresAt: verificationExpires } = newVerificationToken();
    const { error: updateError } = await supabase
      .from('users')
      .update({
        email_verification_token: verificationToken,
        email_verification_expires: verificationExpires,
      })
      .eq('id', user.id);

    if (updateError) {
      console.error('❌ [POST /api/resend-verification] Failed to update user token:', updateError);
      throw updateError;
    }

    const baseUrl = getBaseUrl(req);
    console.log(`📧 [POST /api/resend-verification] Calling sendVerificationEmail for user ${user.email}...`);
    const sendResult = await sendVerificationEmail(user.email, verificationToken, baseUrl);
    console.log(`📬 [POST /api/resend-verification] sendVerificationEmail result:`, sendResult);

    if (!sendResult.success) {
      return res.status(500).json({
        success: false,
        message: sendResult.skipped
          ? 'Email sending is not configured on the server yet.'
          : (sendResult.error ? `Could not send email: ${sendResult.error}` : 'Could not send the email — try again in a moment.'),
      });
    }

    res.json({ success: true, message: 'Verification email resent — check your inbox.' });
  } catch (error) {
    console.error('❌ [POST /api/resend-verification] Exception caught:', error.message);
    res.status(500).json({ success: false, message: error.message });
  }
});

const fetch = require('node-fetch');

// ─── AI Hub Bridge (Centralized Management) ───────────────────────────
async function generateAI(prompt, systemPrompt = 'You are a Master Manifestation Coach.') {
  const hubUrl = process.env.AI_HUB_URL;

  if (!hubUrl || (hubUrl.includes('localhost') && process.env.NODE_ENV === 'production')) {
    throw new Error('AI_HUB_URL is not configured for production. Please set it in Vercel Environment Variables.');
  }

  console.log(`📡 Relaying request to AI Hub: ${hubUrl}`);

  const response = await fetch(hubUrl, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      prompt,
      systemPrompt,
      format: 'json'
    })
  });

  const data = await response.json();
  if (!data.success) {
    throw new Error(`AI Hub Error: ${data.error}`);
  }

  console.log(`✔️ Response received from Provider: ${data.provider}`);
  return data.data;
}


// ─── AI Manifestation Blueprint Generator ─────────────────────────────────
app.post('/api/generate-plan', async (req, res) => {
  const { user_id, goal_title, personalize = true } = req.body;

  try {
    // 1. Fetch User DNA
    const { data: user, error: userError } = await supabase
      .from('users').select('*').eq('id', user_id).single();
    if (userError || !user) throw new Error(`User not found: ${user_id}`);

    // 2. ── Quick AI Validation ─────────────────────────────────────────────
    console.log(`🔍 Validating goal input: "${goal_title}"...`);
    const validationPrompt = `
      You are a Manifestation Goal Validator. Analyze the user's input and decide if it is a valid personal manifestation goal.

      USER INPUT: "${goal_title}"

      A VALID goal:
      - Is a real, meaningful personal aspiration (career, health, relationship, finance, skill, creativity, etc.)
      - Is written in a human language (English or any other)
      - Is specific enough to mean something (even if short)
      - Examples: "I want to start my own business", "become a better parent", "learn guitar", "lose 10kg"

      AN INVALID goal is one of these:
      - Random gibberish or keyboard mashing (e.g. "asdfgh", "sdjksajd", "qwerty123")
      - Single random characters or numbers only (e.g. "a", "123", "!!!")
      - Offensive, harmful, or abusive content
      - Completely unrelated nonsense (e.g. "banana purple sky", "cat dog fish")
      - Empty meaning or just punctuation

      Respond ONLY with this JSON:
      {
        "is_valid": true or false,
        "reason": "If invalid: a friendly, empathetic 1-2 sentence explanation of why this isn't a valid manifestation goal.",
        "tip": "If invalid: a helpful suggestion of what a good goal looks like. Leave empty string if valid."
      }
    `;

    const validation = await generateAI(validationPrompt, 'You are a strict but kind manifestation goal validator. Return only JSON.');
    console.log(`🔍 Validation result: ${JSON.stringify(validation)}`);

    if (!validation.is_valid) {
      return res.json({
        success: true,
        valid: false,
        reason: validation.reason || 'This doesn\'t seem like a manifestation goal.',
        tip: validation.tip || 'Try describing a real aspiration, like "I want to build a successful career in tech."'
      });
    }
    console.log(`✅ Goal is valid, proceeding with generation... (personalize=${personalize})`);

    // 2. Build the prompt — personalized (uses the user's onboarding
    // answers) unless the client's "AI Personalization" toggle is off, in
    // which case we deliberately leave those answers out of the prompt.
    const userProfileBlock = personalize
      ? `- Name: ${user.full_name}
      - Goal: "${goal_title}"
      - Personal answers: ${(user.personal_answers || []).join(', ')}
      - Family answers: ${(user.family_answers || []).join(', ')}
      - Professional answers: ${(user.professional_answers || []).join(', ')}`
      : `- Goal: "${goal_title}"
      (AI Personalization is off for this user — do not assume any personal, family, or professional background; keep the plan general-purpose.)`;

    const personalizationInstruction = personalize
      ? `Deeply reference the user's personal and professional background in each pillar.`
      : `Keep guidance general-purpose and applicable to anyone with this goal — do not invent or assume personal details.`;

    const prompt = `
      You are a practical, no-nonsense life coach who helps people turn a goal into concrete action.

      USER PROFILE:
      ${userProfileBlock}

      GOAL TO PLAN FOR (this is the only goal — every pillar must visibly serve THIS goal): "${goal_title}"

      TASK: Generate a hyper-personalized action plan for reaching this exact goal.

      First, decide how many PILLARS (NOT day-by-day steps) this SPECIFIC goal genuinely needs to be
      comprehensively covered — do not default to a fixed number. A narrow, single-focus goal
      (e.g. "learn to juggle") may only need 3 pillars; a broad, multi-dimensional goal
      (e.g. "rebuild my entire career and finances") may need up to 7. Never use fewer than 3 or
      more than 7. Each pillar must be a genuinely distinct angle/dimension of how to reach this
      goal — do not pad the count with overlapping or filler pillars just to hit a number.

      Then, for each pillar, write real substance — every pillar needs a minimum of 200 words, going
      up to 400+ words when the angle genuinely needs it. Do not write a short, vague paragraph and
      call it done. Never pad with filler sentences either — every sentence must earn its place.

      RELEVANCE CHECK (do this for every pillar before writing it): could this paragraph be pasted
      into a plan for a completely different goal without sounding out of place? If yes, rewrite it
      so it is unmistakably about "${goal_title}" — name the goal, reference concrete details from
      it, and give steps that only make sense for this goal.

      WRITING RULES (follow strictly):
      - Use plain, everyday words. No mystical or overly abstract language (avoid words like
        "cosmic", "universe", "energy", "vibration", "manifesto", "essence", "divine").
      - Write like a coach talking to the person directly, not like a motivational poster.
      - Every pillar must include at least 2 concrete, doable actions the person can actually take
        this week — not just mindset talk.
      - Reference the user's actual answers and goal directly, by name where relevant.

      ${personalizationInstruction}

      Return ONLY this JSON structure (the number of objects in "pillars" is however many you
      determined above, between 3 and 7):
      {
        "plan_title": "A clear, specific 6-8 word title naming what this plan is for",
        "overall_summary": "3 plain sentences on why this plan fits ${user.full_name} specifically and what it will get them.",
        "pillars": [
          {
            "title": "Emoji + Pillar Name (e.g. 🔥 Build The Daily Habit)",
            "huge_text": "200-400+ words of concrete guidance for this pillar, in plain language, directly tied to \\"${goal_title}\\". Must include at least 2 specific actions the person can take this week. No filler, no jargon. Structure it as 3-4 short paragraphs separated by a blank line (\\n\\n), with the LAST paragraph being one clear, specific action sentence the person should take this week.",
            "summary": "A 2-sentence plain-language summary of this pillar's core action."
          }
        ]
      }
    `;

    // 3. Generate with Groq
    console.log(`🧠 Generating AI manifesto for ${user.full_name}: "${goal_title}"...`);
    const aiResponse = await generateAI(
      prompt,
      'You are a practical, plain-speaking life coach. Always return valid JSON matching the exact schema, with real, specific, non-generic content.'
    );
    console.log(`✨ AI Manifesto Ready!`);

    // 4. Save to Supabase
    const { data: manifestation } = await supabase
      .from('manifestations').insert([{ user_id, goal_title }]).select().single();

    // 4b. Update the streak — stored on the user's own row, completely
    // separate from the manifestations table, so it survives "Delete All
    // Manifestations" instead of being recalculated from (and lost with)
    // that data. Day comparison uses UTC calendar days. Wrapped in its own
    // try/catch — a streak-column issue (e.g. the migration hasn't been
    // run yet) should never fail the whole plan-generation request, since
    // the plan itself already saved successfully above.
    let newStreak = user.current_streak || 0;
    try {
      const todayStr = new Date().toISOString().slice(0, 10); // 'YYYY-MM-DD'
      const lastDate = user.last_manifested_date;
      if (!lastDate) {
        newStreak = 1;
      } else if (lastDate === todayStr) {
        newStreak = user.current_streak || 1; // already manifested today
      } else {
        const dayMs = 24 * 60 * 60 * 1000;
        const diffDays = Math.round(
          (Date.parse(`${todayStr}T00:00:00Z`) - Date.parse(`${lastDate}T00:00:00Z`)) / dayMs
        );
        newStreak = diffDays === 1 ? (user.current_streak || 0) + 1 : 1;
      }
      const { error: streakError } = await supabase
        .from('users')
        .update({ current_streak: newStreak, last_manifested_date: todayStr })
        .eq('id', user_id);
      if (streakError) throw streakError;
    } catch (streakErr) {
      console.error('⚠️ Warning: Failed to update streak, but continuing...', streakErr.message);
    }

    const { data: plan } = await supabase
      .from('manifestation_plans')
      .insert([{
        manifestation_id: manifestation.id,
        plan_title: aiResponse.plan_title,
        summary: aiResponse.overall_summary,
        full_content: JSON.stringify(aiResponse),
        audio_url: null
      }])
      .select().single();

    const tasks = aiResponse.pillars.map((p, index) => ({
      plan_id: plan.id,
      day_number: index + 1,
      task_title: p.title,
      task_description: p.huge_text
    }));

    const { data: savedTasks, error: taskError } = await supabase.from('daily_tasks').insert(tasks).select();

    if (taskError) {
      console.error('⚠️ Warning: Failed to save tasks to DB, but continuing...', taskError.message);
    }

    // 5. Notify the user — fire-and-forget so a push failure never fails the
    // request. Respects the master "Push Notifications" switch (defaults
    // true, same as the column) — this is core functionality, not a
    // "tip", so it isn't gated on manifestation_tips_enabled.
    if (user.notifications_enabled !== false) {
      sendPushNotification(user.fcm_token, {
        title: '✨ Your Manifestation Blueprint is Ready',
        body: `"${goal_title}" — your personalized plan just landed. Open it now.`,
        data: { type: 'plan_ready', manifestation_id: manifestation.id },
      }).catch((err) => console.error('Push notification error (non-fatal):', err.message));
    }

    res.json({
      success: true,
      data: { plan, cards: savedTasks || tasks, full_ai: aiResponse, streak: newStreak },
    });


  } catch (error) {
    console.error('❌ Generation Error Details:', {
      message: error.message,
      code: error.code,
      details: error.details,
      hint: error.hint
    });
    res.status(500).json({
      success: false,
      message: `Failed to manifest your plan: ${error.message || 'Unknown Error'}`,
      error: error.message,
      code: error.code
    });
  }
});


// ─── AI Spiritual Archetype Generator ──────────────────────────────────────────
app.post('/api/generate-archetype', async (req, res) => {
  const { user_id } = req.body;

  try {
    // 1. Fetch User Data
    const { data: user, error: userError } = await supabase
      .from('users').select('*').eq('id', user_id).single();

    if (userError || !user) throw new Error(`User not found: ${user_id}`);

    // If answers are entirely empty, AI still generates based on name
    const prompt = `
      You are a warm, down-to-earth guide who helps people understand their own personality and manifestation style.

      USER PROFILE:
      - Name: ${user.full_name}
      - Personal insights: ${(user.personal_answers || []).join(', ')}
      - Family & Connection insights: ${(user.family_answers || []).join(', ')}
      - Professional & Ambition insights: ${(user.professional_answers || []).join(', ')}

      TASK: Read all three answer groups together and figure out something about this person that
      isn't obvious from any single answer alone — a pattern that only shows up when you connect
      their personal, family, and professional answers. This must read as new insight ABOUT them,
      never a restatement or rephrasing of what they already typed. Use their answers only as
      evidence to build a bigger picture — do not quote or list them back.
      If insights are empty, create a general but still concrete archetype based on their name and vibe.

      WRITING RULES (follow strictly):
      - Use simple, everyday words. No mystical, cosmic, or flowery jargon (avoid words like "cosmic", "universe", "aura", "essence of the soul", "divine", "vibration").
      - Write like a perceptive friend telling them something they hadn't quite put into words themselves.
      - Every sentence must say something specific and useful — no filler sentences that just sound nice.
      - Never just list their answers back to them. Interpret them, connect them, draw a conclusion.
      - Keep sentences short and clear (under 20 words each).

      Return ONLY this precise JSON structure:
      {
        "archetype_name": "A short, plain-language personality title, e.g. 'The Grounded Achiever'",
        "header_label": "E.g. YOUR ARCHETYPE",
        "essence_label": "E.g. Who You Are",
        "essence_description": "6-8 short, clear sentences (2 short paragraphs) painting a full picture of their personality and how it shows up day to day. Include at least one non-obvious observation, not just a summary of their answers.",
        "pattern_label": "E.g. The Pattern We Noticed",
        "pattern_text": "2-3 sentences naming ONE specific connection across their personal, family, and professional answers that they likely haven't noticed themselves. This is the 'what's new here' insight.",
        "strengths_label": "E.g. Your Strengths",
        "strengths": [
          {"title": "Short strength name, e.g. Steady Focus", "description": "One sentence on how this strength actually shows up for them, not a dictionary definition."}
        ],
        "growth_label": "E.g. Your Growth Edge",
        "growth_text": "2-3 honest, kind sentences on one blind spot or habit that may be holding them back. Specific, not generic advice.",
        "vision_label": "E.g. What This Means For You",
        "vision_text": "3-4 short, plain sentences on how they can use these strengths and work with their growth edge going forward. Practical and actionable, not poetic.",
        "button_label": "Continue My Journey"
      }

      Include exactly 4 items in "strengths".
    `;

    console.log(`🧠 Generating Archetype for ${user.full_name}...`);
    const aiResponse = await generateAI(prompt, 'You are an archetype generator. Always return valid JSON matching the exact schema.');
    console.log(`✨ Archetype AI Result ready.`);

    res.json({ success: true, data: aiResponse });

  } catch (error) {
    console.error('❌ Archetype Error Details:', {
      message: error.message,
      code: error.code,
      details: error.details,
      hint: error.hint
    });
    res.status(500).json({
      success: false,
      message: `Failed to discover your archetype: ${error.message || 'Unknown Error'}`,
      error: error.message,
      code: error.code
    });
  }
});

// ─── Fetch Manifestation History (Vision Board) ───────────────────────────
app.get('/api/history/:userId', async (req, res) => {
  try {
    const { userId } = req.params;
    console.log(`[HISTORY] Fetching history for user ID: ${userId}`);

    // Streak lives on the users row, independent of the manifestations
    // below — it deliberately survives "Delete All Manifestations" (that
    // endpoint never touches this column), so wiping your history no
    // longer wipes a streak you actually earned by showing up daily.
    const { data: streakUser } = await supabase
      .from('users')
      .select('current_streak')
      .eq('id', userId)
      .single();

    // 1. Fetch manifestations manually
    const { data: manifestations, error: manError } = await supabase
      .from('manifestations')
      .select('*')
      .eq('user_id', userId)
      .order('created_at', { ascending: false });

    if (manError) throw manError;

    const historyData = manifestations || [];

    // 2. Fetch plans and tasks manually (Bulletproof JOIN bypass)
    for (let man of historyData) {
      const { data: plans } = await supabase
        .from('manifestation_plans')
        .select('*')
        .eq('manifestation_id', man.id);

      man.manifestation_plans = plans || [];

      for (let plan of man.manifestation_plans) {
        const { data: tasks } = await supabase
          .from('daily_tasks')
          .select('*')
          .eq('plan_id', plan.id)
          .order('day_number', { ascending: true });

        plan.daily_tasks = tasks || [];
      }
    }

    console.log(`[HISTORY] Found ${historyData.length} items for user.`);
    res.json({ success: true, data: historyData, streak: streakUser?.current_streak ?? 0 });

  } catch (error) {
    console.error('[HISTORY ERROR DETAILS]:', {
      message: error.message,
      code: error.code,
      details: error.details,
      hint: error.hint
    });
    res.status(500).json({
      success: false,
      message: `Failed to load history: ${error.message || 'Unknown Error'}`,
      error: error.message,
      code: error.code
    });
  }
});

// ─── Mark Manifestation as Fully Read ─────────────────────────────────────
// Called once the user has opened every step of a plan — this is what the
// profile's MANIFESTED count is built from.
app.post('/api/manifestations/:id/manifested', async (req, res) => {
  const { id } = req.params;
  try {
    const { error } = await supabase
      .from('manifestations')
      .update({ is_manifested: true })
      .eq('id', id);
    if (error) throw error;
    res.json({ success: true });
  } catch (error) {
    console.error('[MANIFESTED ERROR]:', error.message);
    res.status(500).json({ success: false, message: error.message });
  }
});

// ─── Delete Manifestation (Permanent) ────────────────────────────────────────
app.delete('/api/manifestations/:id', async (req, res) => {
  const { id } = req.params;
  console.log(`[DELETE] Manifest ID: ${id}`);

  try {
    // 1. Find the plan linked to this manifestation
    const { data: plans } = await supabase
      .from('manifestation_plans')
      .select('id')
      .eq('manifestation_id', id);

    if (plans && plans.length > 0) {
      const planIds = plans.map(p => p.id);

      // 2. Delete daily_tasks for all related plans
      await supabase.from('daily_tasks').delete().in('plan_id', planIds);

      // 3. Delete the plans themselves
      await supabase.from('manifestation_plans').delete().eq('manifestation_id', id);
    }

    // 4. Delete the root manifestation
    const { error } = await supabase.from('manifestations').delete().eq('id', id);
    if (error) throw error;

    console.log(`[DELETE] ✅ Manifestation ${id} wiped from cosmos.`);
    res.json({ success: true, message: 'Manifestation permanently removed.' });
  } catch (error) {
    console.error('[DELETE ERROR DETAILS]:', {
      message: error.message,
      code: error.code,
      details: error.details,
      hint: error.hint
    });
    res.status(500).json({
      success: false,
      message: `Failed to remove manifestation: ${error.message || 'Unknown Error'}`,
      error: error.message,
      code: error.code
    });
  }
});

// ─── Delete ALL Manifestations For A User (Permanent) ─────────────────────
app.delete('/api/history/:userId', async (req, res) => {
  const { userId } = req.params;
  console.log(`[DELETE ALL] Wiping manifestations for user: ${userId}`);

  try {
    const { data: manifestations, error: fetchError } = await supabase
      .from('manifestations')
      .select('id')
      .eq('user_id', userId);

    if (fetchError) throw fetchError;

    const manIds = (manifestations || []).map(m => m.id);

    if (manIds.length > 0) {
      const { data: plans } = await supabase
        .from('manifestation_plans')
        .select('id')
        .in('manifestation_id', manIds);

      const planIds = (plans || []).map(p => p.id);

      if (planIds.length > 0) {
        await supabase.from('daily_tasks').delete().in('plan_id', planIds);
      }

      await supabase.from('manifestation_plans').delete().in('manifestation_id', manIds);
      await supabase.from('manifestations').delete().in('id', manIds);
    }

    console.log(`[DELETE ALL] ✅ Removed ${manIds.length} manifestation(s) for user ${userId}.`);
    res.json({ success: true, message: 'All manifestations permanently removed.', count: manIds.length });
  } catch (error) {
    console.error('[DELETE ALL ERROR DETAILS]:', {
      message: error.message,
      code: error.code,
      details: error.details,
      hint: error.hint
    });
    res.status(500).json({
      success: false,
      message: `Failed to clear manifestations: ${error.message || 'Unknown Error'}`,
      error: error.message,
      code: error.code
    });
  }
});

// ─── Fetch Full Profile ─────────────────────────────────────────────────
// Re-hydrates everything login's response carries (name, avatar, the
// personal/family/professional answers, etc.) for a session that's already
// authenticated locally (SharedPreferences userId) rather than logging in
// again — used when the app cold-starts already logged in, and before
// opening the "edit your answers" screen, since neither of those goes
// through POST /api/login.
app.get('/api/users/:id', async (req, res) => {
  const { id } = req.params;
  try {
    const { data: user, error } = await supabase
      .from('users')
      .select('*')
      .eq('id', id)
      .maybeSingle();
    if (error) throw error;

    if (!user) {
      return res.status(404).json({ success: false, message: 'User not found.' });
    }

    delete user.password_hash;
    delete user.email_verification_token;
    delete user.email_verification_expires;

    res.json({ success: true, data: user });
  } catch (error) {
    console.error('Fetch profile error:', error.message);
    res.status(500).json({ success: false, message: error.message });
  }
});

// ─── Delete Account (Permanent) ────────────────────────────────────────────
app.delete('/api/users/:id', async (req, res) => {
  const { id } = req.params;
  console.log(`[DELETE ACCOUNT] Wiping user: ${id}`);

  try {
    // 1. Wipe every manifestation (and its plans/tasks) owned by this user.
    const { data: manifestations, error: fetchError } = await supabase
      .from('manifestations')
      .select('id')
      .eq('user_id', id);

    if (fetchError) throw fetchError;

    const manIds = (manifestations || []).map(m => m.id);

    if (manIds.length > 0) {
      const { data: plans } = await supabase
        .from('manifestation_plans')
        .select('id')
        .in('manifestation_id', manIds);

      const planIds = (plans || []).map(p => p.id);

      if (planIds.length > 0) {
        await supabase.from('daily_tasks').delete().in('plan_id', planIds);
      }

      await supabase.from('manifestation_plans').delete().in('manifestation_id', manIds);
      await supabase.from('manifestations').delete().in('id', manIds);
    }

    // 2. Wipe the user profile itself.
    const { error: userError } = await supabase.from('users').delete().eq('id', id);
    if (userError) throw userError;

    console.log(`[DELETE ACCOUNT] ✅ Account ${id} permanently destroyed.`);
    res.json({ success: true, message: 'Account permanently deleted.' });
  } catch (error) {
    console.error('[DELETE ACCOUNT ERROR DETAILS]:', {
      message: error.message,
      code: error.code,
      details: error.details,
      hint: error.hint
    });
    res.status(500).json({
      success: false,
      message: `Failed to delete account: ${error.message || 'Unknown Error'}`,
      error: error.message,
      code: error.code
    });
  }
});

if (process.env.VERCEL !== '1') {
  app.listen(port, () => {
    console.log(`🚀 Backend listening at http://localhost:${port}`);
  });
}

module.exports = app;
