-- Add email + password_hash columns for the new email/password login.
alter table users add column if not exists email text;
alter table users add column if not exists password_hash text;

-- One account per email.
create unique index if not exists users_email_unique_idx
  on users (lower(email))
  where email is not null;

-- Optional cleanup once everyone has migrated off the old 4-digit passcode:
-- alter table users drop column passcode;
