# Supabase setup for Marco Polo

This repo now has the first backend contract for the Marco Polo MVP.

## What Codex can prepare

Codex can prepare and maintain:

- SQL migrations
- table design
- RLS policies
- seed data for products and themes
- frontend Supabase client
- API wrapper functions
- environment variable templates
- integration code for auth, profiles, orders, notes and mailbox

## What must exist in Supabase

The project owner must create or provide access to a Supabase project. Codex needs these frontend-safe values:

```txt
VITE_SUPABASE_URL
VITE_SUPABASE_ANON_KEY
```

Do not paste the service role key into frontend code.

## Create the Supabase project

1. Create a new Supabase project.
2. Open the SQL editor.
3. Run:

```txt
supabase/migrations/20260520010000_marco_polo_core.sql
```

4. In Supabase Auth, enable email/password login.
5. Add the local URL to allowed redirect URLs:

```txt
http://localhost:4173
http://127.0.0.1:4173
```

6. Add the future production URLs later:

```txt
https://marcopolo.pet
https://app.marcopolo.pet
```

## Local environment

Create `.env.local` from `.env.example`:

```txt
VITE_SUPABASE_URL=https://your-project-ref.supabase.co
VITE_SUPABASE_ANON_KEY=your-public-anon-key
```

Then install dependencies and run the app:

```bash
npm install
npm run dev
```

## MVP backend modules included

The first migration creates:

- `profiles`
- `themes`
- `pets`
- `pet_members`
- `journals`
- `journal_entries`
- `timeline_events`
- `reminders`
- `external_interactions`
- `care_mailbox`
- `care_invitations`
- `care_link_requests`
- `responsibility_notes`
- `service_profiles`
- `pet_service_links`
- `products`
- `draft_profiles`
- `orders`
- `tags`
- `tag_activations`
- `public_views`
- `scan_logs`

It also seeds the first themes and products.

## First integration target

Do not connect every UI element at once. The first safe production path should be:

```txt
create account
  -> create draft profile / order
  -> login
  -> create pet profile
  -> generate public view
  -> public visitor leaves note
  -> tutor sees note in mailbox
```

After that:

```txt
tag assigned
  -> QR/NFC activation
  -> profile state changes from draft to activated
```

## Security rules

Public users can:

- read only `public_views`
- insert `external_interactions`
- insert scan logs

Public users cannot:

- read tutor phone numbers
- read private diary
- read care mailbox
- read full pet records
- edit profiles

Tutors and members access pets through `pet_members`.

Admins are controlled by `profiles.role = 'admin'`.
