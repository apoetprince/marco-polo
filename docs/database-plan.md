# Marco Polo data plan

Recommendation: use Supabase for the pilot, but keep the schema as Marco Polo's domain model.

Supabase gives the MVP auth, Postgres, storage, row-level security, realtime notifications, edge functions, and a fast admin panel. The important choice is to avoid building the app around Supabase-specific shortcuts. Treat Supabase as managed Postgres first.

## Core entities

- `profiles`: app users and people responsible for care.
- `pets`: the central entity.
- `pet_members`: relationship between pets and people.
- `journals`: base spaces like health, food, medicine, behavior, emergencies, general.
- `journal_entries`: free-form memory notes.
- `timeline_events`: denormalized event stream for the pet.
- `reminders`: permissive follow-ups and alerts.
- `nfc_tags`: physical tag inventory and binding state.
- `scan_logs`: NFC public profile scans.
- `external_interactions`: public messages from visitors.
- `service_profiles`: veterinarians, grooming, walkers, pharmacies, rescue, daycare.
- `pet_service_links`: service-to-pet permissions.
- `service_requests`: tutor requests for help.
- `service_responses`: structured replies from a service.
- `consultation_offers`: paid consultation proposals.
- `consultation_agreements`: tutor acceptance and payment/promise state.
- `notifications`: in-app notification queue.
- `care_invitations`: invitation links for responsible people.
- `care_link_requests`: requests created after pasting a public link.
- `care_mailbox`: unified care inbox for tutors/responsibles.
- `responsibility_notes`: what a linked person can help with.
- `products`: physical products sold in the store.
- `orders`: commercial checkout/order records.
- `tags`: physical QR/NFC/tag inventory and binding state.
- `tag_activations`: activation events that bind tags to profiles.
- `themes`: visual themes mapped from product color.
- `draft_profiles`: preliminary profiles created before payment/activation.
- `public_views`: public-safe profile projection.
- `ai_sessions`: structured Setup Agent sessions.

## MVP tables first

Start with:

1. `profiles`
2. `pets`
3. `pet_members`
4. `journals`
5. `journal_entries`
6. `timeline_events`
7. `reminders`
8. `external_interactions`
9. `care_mailbox`
10. `care_invitations`
11. `care_link_requests`
12. `responsibility_notes`
13. `products`
14. `orders`
15. `tags`
16. `tag_activations`
17. `themes`
18. `draft_profiles`

Then add service and payment flows once the tutor/NFC experience feels right.

## Store to app lifecycle

The store creates a draft profile, not a final public profile:

```txt
draft -> pending_payment -> paid -> tag_assigned -> activated -> public
```

Commercial records and profile records stay separate:

```txt
order = purchase
draft_profile = preliminary setup
tag = physical object
tag_activation = binding between tag and profile
pet_profile = operational profile
```

## Public URL strategy

- Pet profile: `/p/{public_slug}`
- Tutor profile: `/t/{tutor_public_token}`
- Service profile: `/s/{service_public_token}`
- Invitation: `/invite/{invite_token}`
- Physical tag redirect: `/nfc/{token}`

Use opaque tokens or slugs with a random suffix. Never expose sequential IDs in public routes.

## Link resolver

The app should resolve pasted links contextually:

- `/p/{slug}` = pet/case profile
- `/t/{token}` = tutor profile
- `/s/{token}` = service profile
- `/invite/{token}` = invitation
- `/nfc/{token}` = physical tag redirect

Resolving a link does not grant access. It creates either a request, notification, or invitation acceptance flow.

## RLS direction

- Tutors can read/write pets through `pet_members`.
- Visitors can read only `pets.public_profile` fields exposed through a safe view or RPC.
- Visitors can insert into `external_interactions`, but cannot read the table.
- Services can read pets only through approved `pet_service_links`.
- Timeline entries inherit visibility from their source record.
- Pasted links create `care_link_requests`, visible to the receiving tutor/owner/responsible.
- Invitation links create pending relationship requests, not automatic full access.

## Care access tables

### care_invitations

- `id`
- `pet_id`
- `invited_by`
- `invite_token`
- `intended_role`
- `status`
- `expires_at`
- `created_at`

### care_link_requests

- `id`
- `pet_id`
- `requested_by`
- `requested_role`
- `offered_help`
- `message`
- `status`
- `created_at`

### care_mailbox

- `id`
- `pet_id`
- `recipient_user_id`
- `sender_user_id`
- `source_type`
- `source_id`
- `message_type`
- `title`
- `body`
- `status`
- `created_at`

### responsibility_notes

- `id`
- `pet_id`
- `user_id`
- `role`
- `can_help_with jsonb`
- `notes`
- `emergency_available boolean`
- `created_at`

## Storage

Use Supabase Storage buckets:

- `pet-photos`
- `service-assets`
- `nfc-artifacts`

Keep buckets private and serve signed URLs where needed. Public NFC pages should read only approved public image variants.
