# Marco Polo Pilot

Marco Polo is a progressive web app pilot for pet and community animal care: identity, public profile links, diary entries, tasks, emergency contacts, public visitor notifications, and future veterinarian workflows.

## Current prototype

The active browser preview is served from:

- `preview.html`

The React app base lives in:

- `src/main.jsx`
- `src/styles.css`

## Product direction

- Always starts from authentication.
- Account creation is progressive.
- Profiles can start from a pet/case, tutor, or veterinarian.
- Public profile links are safe, limited views.
- Visitors who are not linked can leave notifications, not edit private data.
- The dashboard grows from user-entered data, with examples only as placeholders.

## Local run

When Node/npm are available:

```bash
npm install
npm run dev
```

## Important MVP flows

- Auth: create account, login, recover password, admin login.
- Onboarding: choose pet-first, tutor-first, or veterinarian path.
- Profile: age, breed/mix, species, zone, type, status, critical public notes.
- Diary: free-form notes, optional alerts, chronological history.
- Health: add multiple veterinarians.
- Tasks: add task, optional date/time, notes for the person assuming it.
- Directory: add name, role, and WhatsApp/phone/email.
- Public profile: visitor message, suggestions, optional contact, login with another user.

## Data plan

See `docs/database-plan.md`.

## Supabase backend

The first Supabase migration and setup notes are in:

- `supabase/migrations/20260520010000_marco_polo_core.sql`
- `docs/supabase-setup.md`

Create `.env.local` from `.env.example` before connecting the app to a real Supabase project.
