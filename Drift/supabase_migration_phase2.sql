-- Drift — Phase 2 Migration
-- Run AFTER supabase_schema.sql has been applied
-- Adds: approval/vetting, featured plumbing, check-ins, boost requests,
--        city-based geography, notification tokens, expanded activity types

-- ============================================================
-- ALTER EXISTING TABLES
-- ============================================================

-- Events: approval, featured plumbing, city, submitted_by
alter table public.events
    add column if not exists approval_status text default 'approved'
        check (approval_status in ('pending', 'approved', 'rejected')),
    add column if not exists featured_until timestamptz,
    add column if not exists sponsor_label text,
    add column if not exists submitted_by uuid references public.profiles(id) on delete set null,
    add column if not exists city text default '',
    add column if not exists ticket_url text;

-- Backfill city from neighborhood for existing events
update public.events set city = 'Dallas' where city = '' and neighborhood != 'Fort Worth' and neighborhood != 'Frisco';
update public.events set city = 'Fort Worth' where city = '' and neighborhood = 'Fort Worth';
update public.events set city = 'Frisco' where city = '' and neighborhood = 'Frisco';

-- Mark all existing events as approved
update public.events set approval_status = 'approved' where approval_status is null;

-- Organizers: vetting, featured, expanded profile
alter table public.organizers
    add column if not exists verification_status text default 'verified'
        check (verification_status in ('pending', 'verified', 'rejected', 'suspended')),
    add column if not exists is_featured boolean default false,
    add column if not exists featured_until timestamptz,
    add column if not exists website text,
    add column if not exists contact_email text,
    add column if not exists city text default '';

-- Backfill: existing organizers are verified (they're system-seeded)
update public.organizers set verification_status = 'verified' where verification_status is null;

-- Profiles: city-based geography (alongside existing neighborhood)
alter table public.profiles
    add column if not exists city text default '';

-- ============================================================
-- NEW TABLES
-- ============================================================

-- Check-ins (hybrid: implicit + proximity)
create table if not exists public.check_ins (
    id uuid primary key default uuid_generate_v4(),
    event_id uuid references public.events(id) on delete cascade not null,
    user_id uuid references public.profiles(id) on delete cascade not null,
    method text not null check (method in ('implicit', 'proximity')),
    is_verified boolean default false,
    checked_in_at timestamptz default now(),
    unique(event_id, user_id)
);

-- Boost requests (organizer requests featured placement)
create table if not exists public.boost_requests (
    id uuid primary key default uuid_generate_v4(),
    event_id uuid references public.events(id) on delete cascade not null,
    organizer_id uuid references public.organizers(id) on delete cascade not null,
    contact_email text not null,
    message text,
    status text default 'pending' check (status in ('pending', 'approved', 'rejected', 'expired')),
    created_at timestamptz default now()
);

-- Device tokens (for push notification infrastructure)
create table if not exists public.device_tokens (
    id uuid primary key default uuid_generate_v4(),
    user_id uuid references public.profiles(id) on delete cascade not null,
    token text not null,
    platform text not null check (platform in ('ios', 'android')),
    is_active boolean default true,
    created_at timestamptz default now(),
    updated_at timestamptz default now(),
    unique(user_id, token)
);

-- Notification preferences
create table if not exists public.notification_preferences (
    id uuid primary key default uuid_generate_v4(),
    user_id uuid references public.profiles(id) on delete cascade not null unique,
    event_reminders boolean default true,
    new_events_from_followed boolean default true,
    rsvp_confirmations boolean default true,
    check_in_reminders boolean default true,
    chat_messages boolean default true,
    submission_updates boolean default true,
    created_at timestamptz default now()
);

-- ============================================================
-- UPDATE ACTIVITY FEED ACTION TYPES
-- ============================================================

-- Drop and recreate the check constraint to allow new action types
alter table public.activity_feed
    drop constraint if exists activity_feed_action_type_check;
alter table public.activity_feed
    add constraint activity_feed_action_type_check
    check (action_type in (
        'rsvp', 'follow', 'photo_upload', 'new_event',
        'check_in', 'event_approved', 'event_rejected',
        'organizer_verified', 'boost_approved'
    ));

-- ============================================================
-- NEW INDEXES
-- ============================================================

create index if not exists idx_events_approval on public.events(approval_status);
create index if not exists idx_events_city on public.events(city);
create index if not exists idx_events_featured_until on public.events(featured_until);
create index if not exists idx_events_submitted_by on public.events(submitted_by);
create index if not exists idx_organizers_verification on public.organizers(verification_status);
create index if not exists idx_organizers_profile on public.organizers(profile_id);
create index if not exists idx_check_ins_event on public.check_ins(event_id);
create index if not exists idx_check_ins_user on public.check_ins(user_id);
create index if not exists idx_boost_requests_event on public.boost_requests(event_id);
create index if not exists idx_boost_requests_status on public.boost_requests(status);
create index if not exists idx_device_tokens_user on public.device_tokens(user_id);
create index if not exists idx_profiles_city on public.profiles(city);

-- ============================================================
-- ROW LEVEL SECURITY — NEW TABLES
-- ============================================================

alter table public.check_ins enable row level security;
alter table public.boost_requests enable row level security;
alter table public.device_tokens enable row level security;
alter table public.notification_preferences enable row level security;

-- Check-ins: publicly readable, users manage own
create policy "Check-ins are publicly readable" on public.check_ins
    for select using (true);
create policy "Users can check in" on public.check_ins
    for insert with check (auth.uid() = user_id);
create policy "Users can update own check-in" on public.check_ins
    for update using (auth.uid() = user_id);

-- Boost requests: organizer can view own, insert own
create policy "Organizers can view own boost requests" on public.boost_requests
    for select using (
        exists (select 1 from public.organizers where id = organizer_id and profile_id = auth.uid())
    );
create policy "Organizers can create boost requests" on public.boost_requests
    for insert with check (
        exists (select 1 from public.organizers where id = organizer_id and profile_id = auth.uid())
    );

-- Device tokens: users manage own
create policy "Users can view own tokens" on public.device_tokens
    for select using (auth.uid() = user_id);
create policy "Users can insert own tokens" on public.device_tokens
    for insert with check (auth.uid() = user_id);
create policy "Users can update own tokens" on public.device_tokens
    for update using (auth.uid() = user_id);
create policy "Users can delete own tokens" on public.device_tokens
    for delete using (auth.uid() = user_id);

-- Notification preferences: users manage own
create policy "Users can view own notification prefs" on public.notification_preferences
    for select using (auth.uid() = user_id);
create policy "Users can insert own notification prefs" on public.notification_preferences
    for insert with check (auth.uid() = user_id);
create policy "Users can update own notification prefs" on public.notification_preferences
    for update using (auth.uid() = user_id);

-- Organizers: allow authenticated users to insert (for registration)
create policy "Authenticated users can register as organizer" on public.organizers
    for insert with check (auth.uid() = profile_id);

-- Events: expand insert policy to include submitted_by
-- (existing policy uses organizer_id; keep it, add submitted_by tracking)

-- ============================================================
-- REALTIME — NEW TABLES
-- ============================================================

alter publication supabase_realtime add table public.check_ins;
alter publication supabase_realtime add table public.boost_requests;

-- ============================================================
-- STORAGE — COVER IMAGE UPLOAD POLICY
-- ============================================================

-- Allow authenticated users to upload cover images (for event submissions)
create policy "Authenticated users can upload cover images" on storage.objects
    for insert with check (bucket_id = 'cover-images' and auth.role() = 'authenticated');
