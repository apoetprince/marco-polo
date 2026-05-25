# Production MVP plan

## Goal

Publish a minimal but useful Marco Polo web app that can support a real pet/case profile quickly and safely.

## Product architecture

Marco Polo should be split into two connected products:

```txt
Landing / Storefront
  -> Setup Agent
  -> Checkout / order
  -> Draft profile
  -> Marco Polo App
  -> QR / tag activation
```

Suggested domains:

- `marcopolo.pet` for landing, store, product selection, setup and checkout.
- `app.marcopolo.pet` for authentication, profiles, diary, links, mailbox and activation.

Both share the same Supabase backend.

## Phase 1: protect the prototype

- Keep `preview.html` as the visual/product reference.
- Convert the stable flows into React components.
- Keep all copy and flow decisions documented.

## Phase 2: real app structure

Suggested React structure:

```txt
src/
  main.jsx
  styles.css
  store/
    Storefront.jsx
    ProductSelection.jsx
    ColorThemeSelection.jsx
    SetupAgent.jsx
    DraftPreview.jsx
    CheckoutBridge.jsx
    ActivationEntry.jsx
  app/
    AuthFlow.jsx
    TutorHome.jsx
    PetDashboard.jsx
    PublicProfile.jsx
    CareMailbox.jsx
    LinkResolver.jsx
    ProfileEditor.jsx
    DiaryPanel.jsx
    Directory.jsx
    Tasks.jsx
    History.jsx
  data/
    mockData.js
  components/
    BrandMark.jsx
```

## Storefront MVP flow

```txt
Landing
  -> product type
  -> color / theme
  -> Setup Agent
  -> public preview
  -> checkout
  -> draft_profile saved
  -> payment confirmed
  -> tag assigned
  -> activation
  -> final profile
```

Products:

- Pet Tag
- Tutor Tag
- Multi-pet Tutor Tag
- Rescue / Street Dog Tag

The Setup Agent is a structured conversational form. It asks one question at a time, allows skip/add later, and creates a draft profile. It does not provide veterinary diagnosis.

## Profile states

```txt
draft
pending_payment
paid
tag_assigned
activated
public
lost_mode
archived
```

## Privacy rule

The public profile must not expose the tutor phone number, legal name, private address, or full medical history.

Public users can:

- see public-safe pet/case data
- press `Avisar a mi humano`
- leave a note
- optionally leave their own contact/location/time

Trusted roles can be granted explicit permissions:

- view phone
- call directly
- view medical history
- edit profile
- manage links and contacts

## Phase 3: Supabase

Use Supabase for:

- auth
- password recovery
- profile data
- pet/case profiles
- photos
- diary entries
- tasks
- directory contacts
- public visitor notifications
- public profile links
- draft profiles
- products and orders
- tags and tag activations
- themes
- care mailbox
- link requests and invitations

## Phase 4: first deploy

Use Vercel for the frontend and Supabase for backend/auth/storage.

Critical first public route:

```txt
/p/{public_slug}
```

This route must be safe for visitors:

- read public fields only
- allow external notification insert
- include `Soy tutor`
- include `Avisar a mi humano`
- never expose private diary or contacts unless permitted
