-- Marco Polo Core MVP schema
-- Run in Supabase SQL editor or with the Supabase CLI.

create extension if not exists pgcrypto;

create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  display_name text,
  handle text unique,
  avatar_url text,
  phone_private text,
  role text not null default 'tutor' check (role in ('admin', 'tutor', 'veterinarian', 'service', 'rescuer')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create or replace function public.is_admin()
returns boolean
language sql
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.profiles
    where id = auth.uid()
      and role = 'admin'
  );
$$;

create or replace function public.is_pet_member(target_pet_id uuid)
returns boolean
language sql
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.pet_members
    where pet_id = target_pet_id
      and user_id = auth.uid()
      and status = 'active'
  );
$$;

create or replace function public.is_pet_owner(target_pet_id uuid)
returns boolean
language sql
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.pets
    where id = target_pet_id
      and primary_tutor_id = auth.uid()
  );
$$;

create or replace function public.can_edit_pet(target_pet_id uuid)
returns boolean
language sql
security definer
set search_path = public
as $$
  select public.is_admin()
    or public.is_pet_owner(target_pet_id)
    or exists (
      select 1
      from public.pet_members
      where pet_id = target_pet_id
        and user_id = auth.uid()
        and status = 'active'
        and coalesce((permissions->>'can_edit_profile')::boolean, false)
    );
$$;

create table if not exists public.themes (
  id text primary key,
  label text not null,
  product_color text not null,
  accent text not null,
  accent_2 text not null,
  warm text,
  logo_asset text,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create table if not exists public.pets (
  id uuid primary key default gen_random_uuid(),
  public_slug text not null unique,
  name text not null,
  species text,
  breed text,
  birthday_date date,
  birthday_precision text check (birthday_precision in ('exact', 'month_year', 'year', 'unknown')),
  age_label text,
  color_marks text,
  temperament text,
  likes text,
  avoid_notes text,
  important_notes text,
  photo_url text,
  profile_type text not null default 'private' check (profile_type in ('private', 'community', 'rescue', 'veterinary_case')),
  status text not null default 'draft' check (status in ('draft', 'private', 'community', 'active_rescue', 'emergency', 'lost_mode', 'archived')),
  primary_tutor_id uuid references public.profiles(id) on delete set null,
  theme_id text references public.themes(id),
  public_visibility jsonb not null default '{
    "photo": true,
    "temperament": true,
    "important_notes": true,
    "health_summary": false,
    "food": false,
    "veterinarian": false,
    "contacts": false
  }'::jsonb,
  custom_fields jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.pet_members (
  id uuid primary key default gen_random_uuid(),
  pet_id uuid not null references public.pets(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  role text not null default 'tutor',
  status text not null default 'active' check (status in ('pending', 'active', 'revoked')),
  permissions jsonb not null default '{
    "can_edit_profile": false,
    "can_write_diary": true,
    "can_manage_members": false,
    "can_view_private_contacts": false,
    "can_view_medical_history": false
  }'::jsonb,
  created_at timestamptz not null default now(),
  unique (pet_id, user_id)
);

create table if not exists public.journals (
  id uuid primary key default gen_random_uuid(),
  pet_id uuid not null references public.pets(id) on delete cascade,
  key text not null,
  label text not null,
  created_at timestamptz not null default now(),
  unique (pet_id, key)
);

create table if not exists public.journal_entries (
  id uuid primary key default gen_random_uuid(),
  pet_id uuid not null references public.pets(id) on delete cascade,
  journal_id uuid references public.journals(id) on delete set null,
  author_id uuid references public.profiles(id) on delete set null,
  body text not null,
  category text,
  priority text check (priority in ('normal', 'important', 'urgent')),
  visibility text not null default 'private' check (visibility in ('private', 'members', 'public_safe')),
  happened_at timestamptz not null default now(),
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create table if not exists public.timeline_events (
  id uuid primary key default gen_random_uuid(),
  pet_id uuid not null references public.pets(id) on delete cascade,
  actor_id uuid references public.profiles(id) on delete set null,
  source_type text not null,
  source_id uuid,
  title text not null,
  body text,
  visibility text not null default 'private' check (visibility in ('private', 'members', 'public_safe')),
  occurred_at timestamptz not null default now(),
  created_at timestamptz not null default now()
);

create table if not exists public.reminders (
  id uuid primary key default gen_random_uuid(),
  pet_id uuid not null references public.pets(id) on delete cascade,
  created_by uuid references public.profiles(id) on delete set null,
  title text not null,
  description text,
  reminder_at timestamptz,
  repeat_rule text,
  status text not null default 'open' check (status in ('open', 'completed', 'archived')),
  completed_at timestamptz,
  created_at timestamptz not null default now()
);

create table if not exists public.external_interactions (
  id uuid primary key default gen_random_uuid(),
  pet_id uuid not null references public.pets(id) on delete cascade,
  message text not null,
  visitor_name text,
  visitor_contact text,
  approximate_location text,
  happened_at timestamptz,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create table if not exists public.care_mailbox (
  id uuid primary key default gen_random_uuid(),
  pet_id uuid references public.pets(id) on delete cascade,
  recipient_user_id uuid references public.profiles(id) on delete cascade,
  sender_user_id uuid references public.profiles(id) on delete set null,
  source_type text not null,
  source_id uuid,
  message_type text not null,
  title text not null,
  body text,
  status text not null default 'pending' check (status in ('pending', 'read', 'archived', 'accepted', 'rejected')),
  action_suggestion text,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create table if not exists public.care_invitations (
  id uuid primary key default gen_random_uuid(),
  pet_id uuid not null references public.pets(id) on delete cascade,
  invited_by uuid not null references public.profiles(id) on delete cascade,
  invite_token text not null unique default encode(gen_random_bytes(18), 'hex'),
  intended_role text,
  status text not null default 'pending' check (status in ('pending', 'accepted', 'expired', 'revoked')),
  expires_at timestamptz,
  created_at timestamptz not null default now()
);

create table if not exists public.care_link_requests (
  id uuid primary key default gen_random_uuid(),
  pet_id uuid references public.pets(id) on delete cascade,
  requested_by uuid references public.profiles(id) on delete cascade,
  requested_role text,
  offered_help jsonb not null default '[]'::jsonb,
  message text,
  status text not null default 'pending' check (status in ('pending', 'accepted', 'rejected', 'archived')),
  created_at timestamptz not null default now()
);

create table if not exists public.responsibility_notes (
  id uuid primary key default gen_random_uuid(),
  pet_id uuid not null references public.pets(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  role text,
  can_help_with jsonb not null default '[]'::jsonb,
  notes text,
  emergency_available boolean not null default false,
  created_at timestamptz not null default now()
);

create table if not exists public.service_profiles (
  id uuid primary key default gen_random_uuid(),
  owner_user_id uuid references public.profiles(id) on delete set null,
  public_token text not null unique default encode(gen_random_bytes(18), 'hex'),
  service_type text not null default 'veterinarian',
  name text not null,
  contact_name text,
  whatsapp text,
  email text,
  address text,
  policy jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.pet_service_links (
  id uuid primary key default gen_random_uuid(),
  pet_id uuid not null references public.pets(id) on delete cascade,
  service_id uuid not null references public.service_profiles(id) on delete cascade,
  linked_by uuid references public.profiles(id) on delete set null,
  status text not null default 'pending' check (status in ('pending', 'active', 'revoked')),
  permissions jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  unique (pet_id, service_id)
);

create table if not exists public.products (
  id uuid primary key default gen_random_uuid(),
  sku text not null unique,
  name text not null,
  product_type text not null check (product_type in ('pet_tag', 'tutor_tag', 'multi_pet_tag', 'rescue_tag', 'kit')),
  description text,
  price_amount numeric(10, 2),
  currency text not null default 'GTQ',
  active boolean not null default true,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.draft_profiles (
  id uuid primary key default gen_random_uuid(),
  created_by uuid references public.profiles(id) on delete set null,
  product_type text not null,
  profile_kind text not null default 'pet',
  profile_name text,
  theme_id text references public.themes(id),
  setup_answers jsonb not null default '{}'::jsonb,
  state text not null default 'draft' check (state in ('draft', 'pending_payment', 'paid', 'tag_assigned', 'activated', 'public', 'lost_mode', 'archived')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.orders (
  id uuid primary key default gen_random_uuid(),
  order_number text not null unique default ('MP-' || upper(substr(encode(gen_random_bytes(6), 'hex'), 1, 8))),
  user_id uuid references public.profiles(id) on delete set null,
  draft_profile_id uuid references public.draft_profiles(id) on delete set null,
  product_id uuid references public.products(id) on delete set null,
  status text not null default 'pending_payment' check (status in ('draft', 'pending_payment', 'paid', 'preparing', 'tag_assigned', 'shipped', 'delivered', 'activated', 'cancelled')),
  payment_method text,
  delivery_notes text,
  estimated_ready_at timestamptz,
  progress integer not null default 20 check (progress between 0 and 100),
  total_amount numeric(10, 2),
  currency text not null default 'GTQ',
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.tags (
  id uuid primary key default gen_random_uuid(),
  tag_code text not null unique,
  nfc_uid text unique,
  qr_payload text,
  product_id uuid references public.products(id) on delete set null,
  order_id uuid references public.orders(id) on delete set null,
  linked_pet_id uuid references public.pets(id) on delete set null,
  linked_user_id uuid references public.profiles(id) on delete set null,
  status text not null default 'unassigned' check (status in ('unassigned', 'reserved', 'assigned', 'activated', 'lost', 'disabled')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.tag_activations (
  id uuid primary key default gen_random_uuid(),
  tag_id uuid not null references public.tags(id) on delete cascade,
  activated_by uuid references public.profiles(id) on delete set null,
  pet_id uuid references public.pets(id) on delete set null,
  draft_profile_id uuid references public.draft_profiles(id) on delete set null,
  activated_at timestamptz not null default now(),
  metadata jsonb not null default '{}'::jsonb
);

create table if not exists public.public_views (
  pet_id uuid primary key references public.pets(id) on delete cascade,
  public_slug text not null unique,
  display_name text not null,
  photo_url text,
  public_payload jsonb not null default '{}'::jsonb,
  status text not null default 'public',
  updated_at timestamptz not null default now()
);

create table if not exists public.scan_logs (
  id uuid primary key default gen_random_uuid(),
  pet_id uuid references public.pets(id) on delete set null,
  tag_id uuid references public.tags(id) on delete set null,
  source text,
  approximate_location text,
  user_agent text,
  created_at timestamptz not null default now()
);

create index if not exists pets_primary_tutor_id_idx on public.pets(primary_tutor_id);
create index if not exists pet_members_user_id_idx on public.pet_members(user_id);
create index if not exists journal_entries_pet_id_created_at_idx on public.journal_entries(pet_id, created_at desc);
create index if not exists timeline_events_pet_id_occurred_at_idx on public.timeline_events(pet_id, occurred_at desc);
create index if not exists care_mailbox_recipient_status_idx on public.care_mailbox(recipient_user_id, status);
create index if not exists orders_user_id_idx on public.orders(user_id);
create index if not exists tags_tag_code_idx on public.tags(tag_code);

drop trigger if exists profiles_set_updated_at on public.profiles;
create trigger profiles_set_updated_at
before update on public.profiles
for each row execute function public.set_updated_at();

drop trigger if exists pets_set_updated_at on public.pets;
create trigger pets_set_updated_at
before update on public.pets
for each row execute function public.set_updated_at();

drop trigger if exists service_profiles_set_updated_at on public.service_profiles;
create trigger service_profiles_set_updated_at
before update on public.service_profiles
for each row execute function public.set_updated_at();

drop trigger if exists products_set_updated_at on public.products;
create trigger products_set_updated_at
before update on public.products
for each row execute function public.set_updated_at();

drop trigger if exists draft_profiles_set_updated_at on public.draft_profiles;
create trigger draft_profiles_set_updated_at
before update on public.draft_profiles
for each row execute function public.set_updated_at();

drop trigger if exists orders_set_updated_at on public.orders;
create trigger orders_set_updated_at
before update on public.orders
for each row execute function public.set_updated_at();

drop trigger if exists tags_set_updated_at on public.tags;
create trigger tags_set_updated_at
before update on public.tags
for each row execute function public.set_updated_at();

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (id, display_name, handle)
  values (
    new.id,
    coalesce(new.raw_user_meta_data->>'display_name', split_part(new.email, '@', 1)),
    lower(regexp_replace(coalesce(new.raw_user_meta_data->>'handle', split_part(new.email, '@', 1)), '[^a-zA-Z0-9_]+', '-', 'g'))
      || '-' || substr(new.id::text, 1, 6)
  )
  on conflict (id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
after insert on auth.users
for each row execute function public.handle_new_user();

alter table public.profiles enable row level security;
alter table public.themes enable row level security;
alter table public.pets enable row level security;
alter table public.pet_members enable row level security;
alter table public.journals enable row level security;
alter table public.journal_entries enable row level security;
alter table public.timeline_events enable row level security;
alter table public.reminders enable row level security;
alter table public.external_interactions enable row level security;
alter table public.care_mailbox enable row level security;
alter table public.care_invitations enable row level security;
alter table public.care_link_requests enable row level security;
alter table public.responsibility_notes enable row level security;
alter table public.service_profiles enable row level security;
alter table public.pet_service_links enable row level security;
alter table public.products enable row level security;
alter table public.draft_profiles enable row level security;
alter table public.orders enable row level security;
alter table public.tags enable row level security;
alter table public.tag_activations enable row level security;
alter table public.public_views enable row level security;
alter table public.scan_logs enable row level security;

create policy "profiles own select"
on public.profiles for select
using (id = auth.uid() or public.is_admin());

create policy "profiles own update"
on public.profiles for update
using (id = auth.uid() or public.is_admin())
with check (id = auth.uid() or public.is_admin());

create policy "themes public read"
on public.themes for select
using (true);

create policy "themes admin write"
on public.themes for all
using (public.is_admin())
with check (public.is_admin());

create policy "pets member select"
on public.pets for select
using (
  public.is_admin()
  or primary_tutor_id = auth.uid()
  or public.is_pet_member(pets.id)
);

create policy "pets authenticated create"
on public.pets for insert
with check (auth.uid() is not null and (primary_tutor_id = auth.uid() or public.is_admin()));

create policy "pets owner update"
on public.pets for update
using (public.can_edit_pet(pets.id))
with check (public.can_edit_pet(pets.id));

create policy "pet members visible to members"
on public.pet_members for select
using (
  public.is_admin()
  or user_id = auth.uid()
  or public.is_pet_member(pet_members.pet_id)
);

create policy "pet members owner write"
on public.pet_members for all
using (public.is_admin() or public.is_pet_owner(pet_members.pet_id))
with check (public.is_admin() or public.is_pet_owner(pet_members.pet_id));

create policy "journals member all"
on public.journals for all
using (public.is_admin() or public.is_pet_owner(journals.pet_id) or public.is_pet_member(journals.pet_id))
with check (public.is_admin() or public.is_pet_owner(journals.pet_id) or public.is_pet_member(journals.pet_id));

create policy "journal entries member all"
on public.journal_entries for all
using (public.is_admin() or public.is_pet_owner(journal_entries.pet_id) or public.is_pet_member(journal_entries.pet_id))
with check (public.is_admin() or public.is_pet_owner(journal_entries.pet_id) or public.is_pet_member(journal_entries.pet_id));

create policy "timeline member read"
on public.timeline_events for select
using (public.is_admin() or public.is_pet_owner(timeline_events.pet_id) or public.is_pet_member(timeline_events.pet_id));

create policy "timeline member insert"
on public.timeline_events for insert
with check (public.is_admin() or public.is_pet_owner(timeline_events.pet_id) or public.is_pet_member(timeline_events.pet_id));

create policy "reminders member all"
on public.reminders for all
using (public.is_admin() or public.is_pet_owner(reminders.pet_id) or public.is_pet_member(reminders.pet_id))
with check (public.is_admin() or public.is_pet_owner(reminders.pet_id) or public.is_pet_member(reminders.pet_id));

create policy "external interactions public insert"
on public.external_interactions for insert
with check (true);

create policy "external interactions member read"
on public.external_interactions for select
using (public.is_admin() or public.is_pet_owner(external_interactions.pet_id) or public.is_pet_member(external_interactions.pet_id));

create policy "care mailbox participant read"
on public.care_mailbox for select
using (
  public.is_admin()
  or recipient_user_id = auth.uid()
  or sender_user_id = auth.uid()
  or public.is_pet_member(care_mailbox.pet_id)
  or public.is_pet_owner(care_mailbox.pet_id)
);

create policy "care mailbox authenticated insert"
on public.care_mailbox for insert
with check (auth.uid() is not null or source_type = 'public_profile');

create policy "care mailbox recipient update"
on public.care_mailbox for update
using (
  public.is_admin()
  or recipient_user_id = auth.uid()
  or public.is_pet_member(care_mailbox.pet_id)
  or public.is_pet_owner(care_mailbox.pet_id)
)
with check (
  public.is_admin()
  or recipient_user_id = auth.uid()
  or public.is_pet_member(care_mailbox.pet_id)
  or public.is_pet_owner(care_mailbox.pet_id)
);

create policy "care invitations member all"
on public.care_invitations for all
using (
  public.is_admin()
  or invited_by = auth.uid()
  or public.is_pet_owner(care_invitations.pet_id)
  or public.is_pet_member(care_invitations.pet_id)
)
with check (
  public.is_admin()
  or invited_by = auth.uid()
  or public.is_pet_owner(care_invitations.pet_id)
  or public.is_pet_member(care_invitations.pet_id)
);

create policy "care link requests own or pet member"
on public.care_link_requests for all
using (
  public.is_admin()
  or requested_by = auth.uid()
  or public.is_pet_owner(care_link_requests.pet_id)
  or public.is_pet_member(care_link_requests.pet_id)
)
with check (auth.uid() is not null or public.is_admin());

create policy "responsibility notes own or pet member"
on public.responsibility_notes for all
using (
  public.is_admin()
  or user_id = auth.uid()
  or public.is_pet_owner(responsibility_notes.pet_id)
  or public.is_pet_member(responsibility_notes.pet_id)
)
with check (auth.uid() is not null or public.is_admin());

create policy "service profiles public read"
on public.service_profiles for select
using (true);

create policy "service profiles owner write"
on public.service_profiles for all
using (public.is_admin() or owner_user_id = auth.uid())
with check (public.is_admin() or owner_user_id = auth.uid());

create policy "pet service links member all"
on public.pet_service_links for all
using (
  public.is_admin()
  or public.is_pet_owner(pet_service_links.pet_id)
  or public.is_pet_member(pet_service_links.pet_id)
  or exists (
    select 1 from public.service_profiles
    where service_profiles.id = pet_service_links.service_id
      and service_profiles.owner_user_id = auth.uid()
  )
)
with check (
  public.is_admin()
  or public.is_pet_owner(pet_service_links.pet_id)
  or public.is_pet_member(pet_service_links.pet_id)
  or exists (
    select 1 from public.service_profiles
    where service_profiles.id = pet_service_links.service_id
      and service_profiles.owner_user_id = auth.uid()
  )
);

create policy "products public read"
on public.products for select
using (active = true or public.is_admin());

create policy "products admin write"
on public.products for all
using (public.is_admin())
with check (public.is_admin());

create policy "draft profiles owner all"
on public.draft_profiles for all
using (public.is_admin() or created_by = auth.uid())
with check (public.is_admin() or created_by = auth.uid());

create policy "orders owner all"
on public.orders for all
using (public.is_admin() or user_id = auth.uid())
with check (public.is_admin() or user_id = auth.uid());

create policy "tags owner/admin read"
on public.tags for select
using (
  public.is_admin()
  or linked_user_id = auth.uid()
  or exists (
    select 1 from public.orders
    where orders.id = tags.order_id
      and orders.user_id = auth.uid()
  )
);

create policy "tags admin write"
on public.tags for all
using (public.is_admin())
with check (public.is_admin());

create policy "tag activations participant read"
on public.tag_activations for select
using (public.is_admin() or activated_by = auth.uid());

create policy "tag activations authenticated insert"
on public.tag_activations for insert
with check (auth.uid() is not null);

create policy "public views public read"
on public.public_views for select
using (status in ('public', 'lost_mode', 'emergency'));

create policy "public views member write"
on public.public_views for all
using (public.is_admin() or public.is_pet_owner(public_views.pet_id))
with check (public.is_admin() or public.is_pet_owner(public_views.pet_id));

create policy "scan logs public insert"
on public.scan_logs for insert
with check (true);

create policy "scan logs admin read"
on public.scan_logs for select
using (public.is_admin());

insert into public.themes (id, label, product_color, accent, accent_2, warm, logo_asset, metadata)
values
  ('pink-glow', 'Pink Glow', 'pink', '#f472b6', '#38bdf8', '#facc15', '/assets/marco-polo-tag-logo.png', '{"animation":"pulse"}'),
  ('black-panther', 'Black Panther', 'black', '#60a5fa', '#93c5fd', '#f6c85f', '/assets/logo-tech.png', '{"animation":"scan"}'),
  ('ocean', 'Ocean', 'blue', '#38bdf8', '#0f766e', '#f6c85f', '/assets/logo-tech.png', '{"animation":"scan"}'),
  ('rescue-nature', 'Rescue Nature', 'green', '#34d399', '#38bdf8', '#f6c85f', '/assets/logo-normal.png', '{"animation":"float"}'),
  ('royal-gold', 'Royal Gold', 'gold', '#f6c85f', '#d97706', '#ef4444', '/assets/logo-normal.png', '{"animation":"gold"}'),
  ('mystic-night', 'Mystic Night', 'purple', '#a78bfa', '#38bdf8', '#f472b6', '/assets/logo-tech.png', '{"animation":"scan"}')
on conflict (id) do update set
  label = excluded.label,
  product_color = excluded.product_color,
  accent = excluded.accent,
  accent_2 = excluded.accent_2,
  warm = excluded.warm,
  logo_asset = excluded.logo_asset,
  metadata = excluded.metadata;

insert into public.products (sku, name, product_type, description, price_amount, currency, metadata)
values
  ('MP-PET-TAG-001', 'Tag mascota Marco Polo', 'pet_tag', 'Tag físico para perfil público seguro de mascota.', 149.00, 'GTQ', '{"theme_enabled":true}'),
  ('MP-TUTOR-TAG-001', 'Tag tutor Marco Polo', 'tutor_tag', 'Tag físico para acceso rápido al perfil del tutor y red de cuidado.', 129.00, 'GTQ', '{"theme_enabled":true}'),
  ('MP-MULTI-TAG-001', 'Tag multi-mascota', 'multi_pet_tag', 'Tag para familias, rescatistas o cuidadores con varias mascotas.', 169.00, 'GTQ', '{"theme_enabled":true}'),
  ('MP-RESCUE-TAG-001', 'Tag rescate temporal', 'rescue_tag', 'Tag para casos comunitarios, rescate o perro sin tutor formal.', 119.00, 'GTQ', '{"theme_enabled":true}')
on conflict (sku) do update set
  name = excluded.name,
  product_type = excluded.product_type,
  description = excluded.description,
  price_amount = excluded.price_amount,
  currency = excluded.currency,
  metadata = excluded.metadata,
  active = true;
