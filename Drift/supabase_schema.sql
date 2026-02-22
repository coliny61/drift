-- Drift — DFW Wellness Event Discovery
-- Supabase PostgreSQL Schema
-- Run this in your Supabase SQL Editor to set up all tables + RLS policies

-- Enable UUID extension
create extension if not exists "uuid-ossp";

-- ============================================================
-- TABLES
-- ============================================================

-- Profiles (extends auth.users)
create table public.profiles (
    id uuid primary key references auth.users(id) on delete cascade,
    username text unique not null,
    display_name text not null,
    bio text,
    avatar_url text,
    interests text[] default '{}',
    location_lat double precision,
    location_lng double precision,
    neighborhood text,
    streak_count integer default 0,
    events_attended integer default 0,
    created_at timestamptz default now()
);

-- Organizers
create table public.organizers (
    id uuid primary key default uuid_generate_v4(),
    profile_id uuid references public.profiles(id) on delete set null,
    name text not null,
    slug text unique not null,
    description text not null default '',
    logo_url text,
    instagram_handle text,
    is_verified boolean default false,
    created_at timestamptz default now()
);

-- Events
create table public.events (
    id uuid primary key default uuid_generate_v4(),
    organizer_id uuid references public.organizers(id) on delete cascade not null,
    title text not null,
    description text not null default '',
    short_description text not null default '',
    cover_image_url text,
    category text not null,
    tags text[] default '{}',
    start_time timestamptz not null,
    end_time timestamptz not null,
    recurrence_rule text,
    location_name text not null,
    location_address text not null default '',
    location_lat double precision not null,
    location_lng double precision not null,
    neighborhood text not null default '',
    max_capacity integer,
    price_cents integer default 0,
    external_url text,
    is_featured boolean default false,
    rsvp_count integer default 0,
    status text default 'upcoming' check (status in ('upcoming', 'live', 'past', 'cancelled')),
    created_at timestamptz default now()
);

-- RSVPs
create table public.rsvps (
    id uuid primary key default uuid_generate_v4(),
    event_id uuid references public.events(id) on delete cascade not null,
    user_id uuid references public.profiles(id) on delete cascade not null,
    status text not null check (status in ('going', 'interested')),
    created_at timestamptz default now(),
    unique(event_id, user_id)
);

-- Follows (user-to-user)
create table public.follows (
    id uuid primary key default uuid_generate_v4(),
    follower_id uuid references public.profiles(id) on delete cascade not null,
    following_id uuid references public.profiles(id) on delete cascade not null,
    created_at timestamptz default now(),
    unique(follower_id, following_id),
    check (follower_id != following_id)
);

-- Organizer Follows
create table public.organizer_follows (
    id uuid primary key default uuid_generate_v4(),
    user_id uuid references public.profiles(id) on delete cascade not null,
    organizer_id uuid references public.organizers(id) on delete cascade not null,
    created_at timestamptz default now(),
    unique(user_id, organizer_id)
);

-- Chat Messages
create table public.chat_messages (
    id uuid primary key default uuid_generate_v4(),
    event_id uuid references public.events(id) on delete cascade not null,
    sender_id uuid references public.profiles(id) on delete cascade not null,
    content text not null,
    created_at timestamptz default now()
);

-- Event Photos
create table public.event_photos (
    id uuid primary key default uuid_generate_v4(),
    event_id uuid references public.events(id) on delete cascade not null,
    uploaded_by uuid references public.profiles(id) on delete cascade not null,
    photo_url text not null,
    caption text,
    created_at timestamptz default now()
);

-- Photo Reactions
create table public.photo_reactions (
    id uuid primary key default uuid_generate_v4(),
    photo_id uuid references public.event_photos(id) on delete cascade not null,
    user_id uuid references public.profiles(id) on delete cascade not null,
    reaction_type text not null check (reaction_type in ('fire', 'heart', 'clap', 'mindblown')),
    created_at timestamptz default now(),
    unique(photo_id, user_id, reaction_type)
);

-- Activity Feed
create table public.activity_feed (
    id uuid primary key default uuid_generate_v4(),
    actor_id uuid references public.profiles(id) on delete cascade not null,
    action_type text not null check (action_type in ('rsvp', 'follow', 'photo_upload', 'new_event')),
    target_event_id uuid references public.events(id) on delete cascade,
    target_user_id uuid references public.profiles(id) on delete cascade,
    metadata jsonb default '{}',
    created_at timestamptz default now()
);

-- ============================================================
-- INDEXES
-- ============================================================

create index idx_events_category on public.events(category);
create index idx_events_status on public.events(status);
create index idx_events_start_time on public.events(start_time);
create index idx_events_neighborhood on public.events(neighborhood);
create index idx_events_organizer on public.events(organizer_id);
create index idx_rsvps_event on public.rsvps(event_id);
create index idx_rsvps_user on public.rsvps(user_id);
create index idx_follows_follower on public.follows(follower_id);
create index idx_follows_following on public.follows(following_id);
create index idx_chat_event on public.chat_messages(event_id);
create index idx_chat_created on public.chat_messages(created_at);
create index idx_activity_actor on public.activity_feed(actor_id);
create index idx_activity_created on public.activity_feed(created_at);
create index idx_photos_event on public.event_photos(event_id);

-- ============================================================
-- ROW LEVEL SECURITY (RLS)
-- ============================================================

alter table public.profiles enable row level security;
alter table public.organizers enable row level security;
alter table public.events enable row level security;
alter table public.rsvps enable row level security;
alter table public.follows enable row level security;
alter table public.organizer_follows enable row level security;
alter table public.chat_messages enable row level security;
alter table public.event_photos enable row level security;
alter table public.photo_reactions enable row level security;
alter table public.activity_feed enable row level security;

-- Profiles: publicly readable, self-editable
create policy "Profiles are publicly readable" on public.profiles
    for select using (true);
create policy "Users can update own profile" on public.profiles
    for update using (auth.uid() = id);
create policy "Users can insert own profile" on public.profiles
    for insert with check (auth.uid() = id);

-- Organizers: publicly readable
create policy "Organizers are publicly readable" on public.organizers
    for select using (true);
create policy "Organizers can update own record" on public.organizers
    for update using (auth.uid() = profile_id);

-- Events: publicly readable, organizer-owner writable
create policy "Events are publicly readable" on public.events
    for select using (true);
create policy "Organizers can insert events" on public.events
    for insert with check (
        exists (select 1 from public.organizers where id = organizer_id and profile_id = auth.uid())
    );
create policy "Organizers can update own events" on public.events
    for update using (
        exists (select 1 from public.organizers where id = organizer_id and profile_id = auth.uid())
    );

-- RSVPs: users manage their own
create policy "RSVPs are publicly readable" on public.rsvps
    for select using (true);
create policy "Users can manage own RSVPs" on public.rsvps
    for insert with check (auth.uid() = user_id);
create policy "Users can update own RSVPs" on public.rsvps
    for update using (auth.uid() = user_id);
create policy "Users can delete own RSVPs" on public.rsvps
    for delete using (auth.uid() = user_id);

-- Follows: users manage their own
create policy "Follows are publicly readable" on public.follows
    for select using (true);
create policy "Users can follow" on public.follows
    for insert with check (auth.uid() = follower_id);
create policy "Users can unfollow" on public.follows
    for delete using (auth.uid() = follower_id);

-- Organizer Follows
create policy "Organizer follows are publicly readable" on public.organizer_follows
    for select using (true);
create policy "Users can follow organizers" on public.organizer_follows
    for insert with check (auth.uid() = user_id);
create policy "Users can unfollow organizers" on public.organizer_follows
    for delete using (auth.uid() = user_id);

-- Chat: readable by RSVPed users, sendable by RSVPed users
create policy "Chat readable by RSVPed users" on public.chat_messages
    for select using (
        exists (select 1 from public.rsvps where event_id = chat_messages.event_id and user_id = auth.uid())
    );
create policy "RSVPed users can send messages" on public.chat_messages
    for insert with check (
        auth.uid() = sender_id and
        exists (select 1 from public.rsvps where event_id = chat_messages.event_id and user_id = auth.uid())
    );

-- Event Photos: publicly readable, uploadable by RSVPed users
create policy "Event photos are publicly readable" on public.event_photos
    for select using (true);
create policy "RSVPed users can upload photos" on public.event_photos
    for insert with check (
        auth.uid() = uploaded_by and
        exists (select 1 from public.rsvps where event_id = event_photos.event_id and user_id = auth.uid())
    );

-- Photo Reactions: publicly readable, users manage own
create policy "Photo reactions are publicly readable" on public.photo_reactions
    for select using (true);
create policy "Users can react to photos" on public.photo_reactions
    for insert with check (auth.uid() = user_id);
create policy "Users can remove own reactions" on public.photo_reactions
    for delete using (auth.uid() = user_id);

-- Activity Feed: publicly readable
create policy "Activity feed is publicly readable" on public.activity_feed
    for select using (true);
create policy "System can insert activity" on public.activity_feed
    for insert with check (auth.uid() = actor_id);

-- ============================================================
-- REALTIME
-- ============================================================

-- Enable realtime for chat messages and activity feed
alter publication supabase_realtime add table public.chat_messages;
alter publication supabase_realtime add table public.activity_feed;
alter publication supabase_realtime add table public.rsvps;

-- ============================================================
-- STORAGE BUCKETS
-- ============================================================

-- Run these in the Supabase Dashboard → Storage, or via SQL:
insert into storage.buckets (id, name, public) values ('avatars', 'avatars', true);
insert into storage.buckets (id, name, public) values ('event-photos', 'event-photos', true);
insert into storage.buckets (id, name, public) values ('cover-images', 'cover-images', true);

-- Storage policies
create policy "Avatar images are publicly readable" on storage.objects
    for select using (bucket_id = 'avatars');
create policy "Users can upload own avatar" on storage.objects
    for insert with check (bucket_id = 'avatars' and auth.uid()::text = (storage.foldername(name))[1]);

create policy "Event photos are publicly readable" on storage.objects
    for select using (bucket_id = 'event-photos');
create policy "Authenticated users can upload event photos" on storage.objects
    for insert with check (bucket_id = 'event-photos' and auth.role() = 'authenticated');

create policy "Cover images are publicly readable" on storage.objects
    for select using (bucket_id = 'cover-images');
