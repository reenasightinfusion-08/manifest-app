// OpenAPI 3 spec, served at /api/docs (UI) and /api/docs.json (raw).
// Keep in sync with the routes in server.js.
// Most responses are { success, message, data }. Exceptions are noted per endpoint
// (check-email returns { available }, history adds `streak`, manifested returns only { success }).

const json = (schema, example) => ({ 'application/json': { schema, ...(example && { example }) } });
const body = (schema, example) => ({ required: true, content: json(schema, example) });
const res = (description, schema, example) => ({ description, content: json(schema, example) });
const ref = (name) => ({ $ref: `#/components/schemas/${name}` });

const err = (description, message) =>
  res(description, ref('Error'), { success: false, message });
const serverErr = err('Server error', 'Something went wrong');
const notFound = err('User not found', 'User not found.');

const idParam = (name, description) => ({
  name,
  in: 'path',
  required: true,
  description,
  schema: { type: 'string', format: 'uuid' },
});

const uuid = { type: 'string', format: 'uuid', example: '3f2a9c1e-5b7d-4e8a-9c21-7d4e5f6a8b90' };
const email = { type: 'string', format: 'email', example: 'user@example.com' };
const okOnly = (message) =>
  res('Done', { type: 'object', properties: { success: { type: 'boolean', example: true }, message: { type: 'string' } } },
    { success: true, message });

module.exports = {
  openapi: '3.0.3',
  info: {
    title: 'Manifest API',
    version: '1.0.0',
    description:
      'Backend for the Manifest app (Express on Vercel, Supabase database).\n\n' +
      '**Authentication:** there is no token or session. Endpoints identify the user by the `id` in the URL. ' +
      'Only `/api/cron/daily-reminder` is protected, with `Authorization: Bearer <CRON_SECRET>`.\n\n' +
      '**Responses:** most use `{ success, message, data }`. Errors return `success: false` and a `message`.',
  },
  servers: [
    { url: 'https://backend-mu-tawny-16.vercel.app', description: 'Production' },
    { url: 'http://localhost:3000', description: 'Local' },
  ],
  tags: [
    { name: 'Health' },
    { name: 'Auth' },
    { name: 'Users' },
    { name: 'Manifestations' },
    { name: 'AI' },
    { name: 'Notifications' },
  ],
  components: {
    securitySchemes: { cronSecret: { type: 'http', scheme: 'bearer', description: 'The CRON_SECRET env value. Vercel Cron sends it automatically.' } },
    schemas: {
      Error: {
        type: 'object',
        properties: {
          success: { type: 'boolean', example: false },
          message: { type: 'string', example: 'Something went wrong' },
        },
      },
      User: {
        type: 'object',
        description: 'Password hash and verification tokens are never returned. Other stored columns may also appear.',
        additionalProperties: true,
        properties: {
          id: uuid,
          full_name: { type: 'string', example: 'Asha Rao' },
          email,
          avatar_url: { type: 'string', nullable: true },
          personal_answers: { type: 'array', items: { type: 'string' } },
          family_answers: { type: 'array', items: { type: 'string' } },
          professional_answers: { type: 'array', items: { type: 'string' } },
          fcm_token: { type: 'string', nullable: true },
          notifications_enabled: { type: 'boolean' },
          manifestation_tips_enabled: { type: 'boolean' },
          email_verified: { type: 'boolean' },
          current_streak: { type: 'integer' },
        },
      },
      DailyTask: {
        type: 'object',
        additionalProperties: true,
        properties: {
          id: uuid,
          plan_id: uuid,
          day_number: { type: 'integer', example: 1 },
          task_title: { type: 'string', example: 'Define your first week' },
          task_description: { type: 'string' },
        },
      },
      Plan: {
        type: 'object',
        additionalProperties: true,
        properties: {
          id: uuid,
          manifestation_id: uuid,
          plan_title: { type: 'string' },
          summary: { type: 'string' },
          full_content: { type: 'string', description: 'The full AI response as a JSON string.' },
          audio_url: { type: 'string', nullable: true },
          daily_tasks: { type: 'array', items: ref('DailyTask'), description: 'Only present on history items.' },
        },
      },
      Manifestation: {
        type: 'object',
        additionalProperties: true,
        properties: {
          id: uuid,
          user_id: uuid,
          goal_title: { type: 'string', example: 'Learn guitar' },
          is_manifested: { type: 'boolean' },
          created_at: { type: 'string', format: 'date-time' },
          manifestation_plans: { type: 'array', items: ref('Plan') },
        },
      },
      Archetype: {
        type: 'object',
        description: 'AI-written profile. Labels can vary; the fields below are always requested.',
        additionalProperties: true,
        properties: {
          archetype_name: { type: 'string', example: 'The Grounded Achiever' },
          header_label: { type: 'string' },
          essence_label: { type: 'string' },
          essence_description: { type: 'string' },
          pattern_label: { type: 'string' },
          pattern_text: { type: 'string' },
          strengths_label: { type: 'string' },
          strengths: {
            type: 'array',
            description: 'Exactly 4 items.',
            items: { type: 'object', properties: { title: { type: 'string' }, description: { type: 'string' } } },
          },
          growth_label: { type: 'string' },
          growth_text: { type: 'string' },
          vision_label: { type: 'string' },
          vision_text: { type: 'string' },
          button_label: { type: 'string' },
        },
      },
    },
  },
  paths: {
    '/': {
      get: {
        tags: ['Health'],
        summary: 'Health check',
        responses: { 200: { description: 'Plain text', content: { 'text/html': { schema: { type: 'string', example: 'Manifest Cosmic Backend is Live! ✨' } } } } },
      },
    },
    '/api/app-version': {
      get: {
        tags: ['Health'],
        summary: 'Latest and minimum app versions',
        description: 'Used by the app to show an update prompt or force an update. Values come from env vars.',
        responses: {
          200: res('Version info', {
            type: 'object',
            properties: {
              success: { type: 'boolean' },
              min_version: { type: 'string', example: '1.0.0' },
              latest_version: { type: 'string', example: '1.0.0' },
              force_update: { type: 'boolean', example: false },
              update_url: { type: 'string' },
              title: { type: 'string' },
              message: { type: 'string' },
              release_notes: { type: 'string' },
            },
          }),
        },
      },
    },
    '/api/cron/daily-reminder': {
      get: {
        tags: ['Notifications'],
        summary: 'Send the daily reminder push',
        description: 'Run by Vercel Cron at 12:30 UTC. Notifies users who have a push token and both notification switches on.',
        security: [{ cronSecret: [] }],
        responses: {
          200: res('Sent', { type: 'object', properties: { success: { type: 'boolean' }, total: { type: 'integer' }, sent: { type: 'integer' } } }, { success: true, total: 12, sent: 11 }),
          401: err('Missing or wrong secret', 'Unauthorized'),
          500: serverErr,
        },
      },
    },
    '/api/check-email': {
      get: {
        tags: ['Auth'],
        summary: 'Check whether an email can be used to sign up',
        description: 'Checks format, that the domain exists, that the mailbox exists and that no account uses it. Always answers with `available`.',
        parameters: [{ name: 'email', in: 'query', required: true, schema: email }],
        responses: {
          200: res('Result', {
            type: 'object',
            properties: {
              available: { type: 'boolean' },
              reason: { type: 'string', enum: ['invalid_format', 'domain_not_found', 'mailbox_not_found', 'already_exists'], description: 'Only when available is false.' },
              message: { type: 'string' },
            },
          }, { available: false, reason: 'already_exists', message: 'An account with this email already exists.' }),
          500: res('Could not check', { type: 'object', properties: { available: { type: 'boolean', example: false }, reason: { type: 'string', example: 'server_error' }, message: { type: 'string' } } }),
        },
      },
    },
    '/api/users': {
      post: {
        tags: ['Users'],
        summary: 'Sign up, or update a profile',
        description:
          'Without `id`: creates a pending sign-up (email and password required) and sends a verification email; returns 201. ' +
          'With `id`: updates that profile; returns 200. Profile answers are checked by the AI and may be rejected with 400. ' +
          'Send `complete_profile: true` once, from the last onboarding step, to trigger the welcome push.',
        requestBody: body({
          type: 'object',
          required: ['full_name'],
          properties: {
            id: { ...uuid, description: 'Set to update an existing profile.' },
            full_name: { type: 'string', example: 'Asha Rao' },
            email,
            password: { type: 'string', minLength: 6, example: 'secret123', description: 'Required on sign-up. At least 6 characters.' },
            avatar_url: { type: 'string' },
            personal_answers: { type: 'array', items: { type: 'string' } },
            family_answers: { type: 'array', items: { type: 'string' } },
            professional_answers: { type: 'array', items: { type: 'string' } },
            fcm_token: { type: 'string' },
            notifications_enabled: { type: 'boolean' },
            manifestation_tips_enabled: { type: 'boolean' },
            complete_profile: { type: 'boolean' },
          },
        }),
        responses: {
          200: res('Profile updated', { type: 'object', properties: { success: { type: 'boolean' }, message: { type: 'string' }, data: ref('User') } }, { success: true, message: 'Cosmic identity updated!' }),
          201: res('Sign-up created; verification email sent', { type: 'object', properties: { success: { type: 'boolean' }, message: { type: 'string' }, data: ref('User') } }, { success: true, message: 'User identity established!' }),
          400: err('Missing name, invalid email, short password, or answers rejected by the AI', 'Password must be at least 6 characters.'),
          409: err('Email already registered', 'An account with this email already exists.'),
          500: serverErr,
        },
      },
    },
    '/api/login': {
      post: {
        tags: ['Auth'],
        summary: 'Log in with email and password',
        description: 'Returns the user. There is no token. An unverified account gets 403 with `email_verified: false`.',
        requestBody: body({ type: 'object', required: ['email', 'password'], properties: { email, password: { type: 'string', example: 'secret123' } } }),
        responses: {
          200: res('Logged in', { type: 'object', properties: { success: { type: 'boolean' }, data: ref('User') } }),
          400: err('Email or password missing', 'Email and password are required.'),
          401: err('Wrong email or password', 'Invalid email or password.'),
          403: res('Email not verified yet', {
            type: 'object',
            properties: { success: { type: 'boolean', example: false }, message: { type: 'string' }, email_verified: { type: 'boolean', example: false }, data: { type: 'object', properties: { id: uuid, email } } },
          }, { success: false, message: 'Please verify your email before logging in.', email_verified: false }),
          500: serverErr,
        },
      },
    },
    '/api/verify-email': {
      get: {
        tags: ['Auth'],
        summary: 'Confirm an email address',
        description: 'Opened from the link in the verification email. Returns a small HTML page, and turns the pending sign-up into a real user.',
        parameters: [{ name: 'token', in: 'query', required: true, schema: { type: 'string' } }],
        responses: {
          200: { description: 'HTML page saying the email is verified', content: { 'text/html': { schema: { type: 'string' } } } },
          400: { description: 'HTML page: missing, invalid or expired link', content: { 'text/html': { schema: { type: 'string' } } } },
        },
      },
    },
    '/api/users/{id}/verification-status': {
      get: {
        tags: ['Auth'],
        summary: 'Has this account verified its email yet',
        description: 'The app polls this. `id` can be a user id or a pending sign-up id; once verified, `data.id` is the real user id.',
        parameters: [idParam('id', 'User or pending sign-up id')],
        responses: {
          200: res('Status', { type: 'object', properties: { success: { type: 'boolean' }, data: { type: 'object', properties: { email_verified: { type: 'boolean' }, id: uuid } } } }),
          404: notFound,
          500: serverErr,
        },
      },
    },
    '/api/resend-verification': {
      post: {
        tags: ['Auth'],
        summary: 'Send the verification email again',
        requestBody: body({ type: 'object', required: ['email'], properties: { email } }),
        responses: {
          200: okOnly('Verification email resent — check your inbox.'),
          400: err('Email missing', 'Email is required.'),
          404: err('No account with that email', 'No account with that email.'),
          500: err('Email could not be sent', 'Could not send the email — try again in a moment.'),
        },
      },
    },
    '/api/users/{id}': {
      get: {
        tags: ['Users'],
        summary: 'Read a profile',
        parameters: [idParam('id', 'User id')],
        responses: {
          200: res('The user', { type: 'object', properties: { success: { type: 'boolean' }, data: ref('User') } }),
          404: notFound,
          500: serverErr,
        },
      },
      delete: {
        tags: ['Users'],
        summary: 'Delete an account and everything it owns',
        description: 'Permanent.',
        parameters: [idParam('id', 'User id')],
        responses: { 200: okOnly('Account permanently deleted.'), 500: serverErr },
      },
    },
    '/api/users/{id}/fcm-token': {
      post: {
        tags: ['Notifications'],
        summary: 'Save the device push token',
        description: 'Called after login on a new install, and whenever Firebase rotates the token.',
        parameters: [idParam('id', 'User id')],
        requestBody: body({ type: 'object', required: ['fcm_token'], properties: { fcm_token: { type: 'string' } } }),
        responses: {
          200: res('Saved', { type: 'object', properties: { success: { type: 'boolean' }, data: ref('User') } }),
          400: err('Token missing', 'fcm_token is required.'),
          404: notFound,
          500: serverErr,
        },
      },
    },
    '/api/users/{id}/notification-prefs': {
      post: {
        tags: ['Notifications'],
        summary: 'Save the notification switches',
        parameters: [idParam('id', 'User id')],
        requestBody: body({
          type: 'object',
          properties: { notifications_enabled: { type: 'boolean' }, manifestation_tips_enabled: { type: 'boolean' } },
        }),
        responses: {
          200: res('Saved', { type: 'object', properties: { success: { type: 'boolean' }, data: ref('User') } }),
          400: err('Nothing valid to update', 'Provide notifications_enabled and/or manifestation_tips_enabled as booleans.'),
          404: notFound,
          500: serverErr,
        },
      },
    },
    '/api/generate-plan': {
      post: {
        tags: ['AI'],
        summary: 'Check a goal and generate its plan',
        description:
          'The AI first checks that the goal is meaningful. If not, the response is 200 with `valid: false`, a reason and a tip. ' +
          'If it is, the goal, plan and daily tasks are saved and returned, and the streak is updated. ' +
          'With `personalize: false` the user\'s profile answers are not sent to the AI.',
        requestBody: body({
          type: 'object',
          required: ['user_id', 'goal_title'],
          properties: {
            user_id: uuid,
            goal_title: { type: 'string', example: 'Learn guitar' },
            personalize: { type: 'boolean', default: true },
          },
        }),
        responses: {
          200: {
            description: 'Either a rejected goal or the generated plan',
            content: json({
              oneOf: [
                {
                  type: 'object',
                  properties: {
                    success: { type: 'boolean' },
                    data: {
                      type: 'object',
                      properties: {
                        plan: ref('Plan'),
                        cards: { type: 'array', items: ref('DailyTask') },
                        full_ai: { type: 'object', additionalProperties: true, description: 'The raw AI response.' },
                        streak: { type: 'integer' },
                      },
                    },
                  },
                },
                {
                  type: 'object',
                  properties: { success: { type: 'boolean' }, valid: { type: 'boolean', example: false }, reason: { type: 'string' }, tip: { type: 'string' } },
                },
              ],
            }),
          },
          500: serverErr,
        },
      },
    },
    '/api/generate-archetype': {
      post: {
        tags: ['AI'],
        summary: 'Generate the Spiritual Archetype',
        description: 'Built by the AI from the user\'s profile answers. Not saved.',
        requestBody: body({ type: 'object', required: ['user_id'], properties: { user_id: uuid } }),
        responses: {
          200: res('Archetype', { type: 'object', properties: { success: { type: 'boolean' }, data: ref('Archetype') } }),
          500: serverErr,
        },
      },
    },
    '/api/history/{userId}': {
      get: {
        tags: ['Manifestations'],
        summary: 'List a user\'s manifestations with their plans and tasks',
        description: 'Newest first. `streak` is the user\'s current streak.',
        parameters: [idParam('userId', 'User id')],
        responses: {
          200: res('History', { type: 'object', properties: { success: { type: 'boolean' }, data: { type: 'array', items: ref('Manifestation') }, streak: { type: 'integer' } } }),
          500: serverErr,
        },
      },
      delete: {
        tags: ['Manifestations'],
        summary: 'Delete all of a user\'s manifestations',
        description: 'Permanent. The streak is kept.',
        parameters: [idParam('userId', 'User id')],
        responses: {
          200: res('Deleted', { type: 'object', properties: { success: { type: 'boolean' }, message: { type: 'string' }, count: { type: 'integer' } } }, { success: true, message: 'All manifestations permanently removed.', count: 3 }),
          500: serverErr,
        },
      },
    },
    '/api/manifestations/{id}/manifested': {
      post: {
        tags: ['Manifestations'],
        summary: 'Mark a goal as manifested',
        parameters: [idParam('id', 'Manifestation id')],
        responses: { 200: res('Marked', { type: 'object', properties: { success: { type: 'boolean', example: true } } }), 500: serverErr },
      },
    },
    '/api/manifestations/{id}': {
      delete: {
        tags: ['Manifestations'],
        summary: 'Release (delete) one manifestation',
        description: 'Permanent. Its plan and tasks go with it.',
        parameters: [idParam('id', 'Manifestation id')],
        responses: { 200: okOnly('Manifestation permanently removed.'), 500: serverErr },
      },
    },
  },
};
