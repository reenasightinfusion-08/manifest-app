-- New signups live here until the verification link is tapped. Only a
-- verified signup ever becomes a real row in `users`. No RLS here, to
-- match the rest of this project's tables (the backend's anon key needs
-- full access since there's no separate service-role key configured).

create table if not exists public.pending_signups (
  id uuid primary key default gen_random_uuid(),
  full_name text,
  avatar_url text,
  personal_answers text[],
  family_answers text[],
  professional_answers text[],
  email text not null,
  password_hash text not null,
  fcm_token text,
  notifications_enabled boolean not null default true,
  manifestation_tips_enabled boolean not null default true,
  verification_token text not null unique,
  verification_expires timestamptz not null,
  -- Set once this signup is verified and promoted into `users` — the row
  -- is kept (not deleted) so the app can resolve "what's my real user id
  -- now" by polling with the pending id it already has.
  promoted_to_user_id uuid references public.users(id),
  created_at timestamptz not null default now()
);

-- Only one *active* (not yet promoted) pending signup per email at a time.
-- An expired-and-abandoned one is deleted by the backend before a retry
-- is allowed, so this doesn't block someone from trying again.
create unique index if not exists pending_signups_active_email_idx
  on public.pending_signups (lower(email))
  where promoted_to_user_id is null;

create index if not exists pending_signups_token_idx
  on public.pending_signups (verification_token);
