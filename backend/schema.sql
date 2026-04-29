-- GoaGreen Supabase Schema
-- Run this in Supabase SQL Editor (Dashboard > SQL Editor > New Query)
-- This creates all tables needed by the GoaGreen backend.

-- ── Users ──────────────────────────────────────────────────────────

create table if not exists users (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  avatar_initials text not null,
  green_coins numeric default 0,
  total_co2_saved numeric default 0,
  streak_days integer default 0,
  city text,
  created_at timestamptz default now()
);

-- ── Activities ─────────────────────────────────────────────────────

create table if not exists activities (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references users(id) on delete cascade,
  title text not null,
  category text check (category in ('transport', 'food', 'energy', 'waste')),
  co2_kg numeric not null,
  is_saving boolean default true,
  analogy text,
  logged_at timestamptz default now()
);

-- ── Businesses ─────────────────────────────────────────────────────

create table if not exists businesses (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  sector text check (sector in ('tourism', 'cashew', 'farmer', 'bakery')),
  owner_id uuid references users(id) unique,
  emissions_kg numeric default 0,
  peer_avg_kg numeric default 0,
  created_at timestamptz default now()
);

create table if not exists business_suggestions (
  id uuid primary key default gen_random_uuid(),
  business_id uuid references businesses(id) on delete cascade,
  suggestion text not null,
  applied boolean default false
);

create table if not exists business_badges (
  id uuid primary key default gen_random_uuid(),
  business_id uuid references businesses(id) on delete cascade,
  badge_name text not null,
  earned_at timestamptz default now()
);

-- ── House Game ─────────────────────────────────────────────────────

create table if not exists house_items (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references users(id) on delete cascade,
  item_key text not null,
  item_name text not null,
  cost integer not null,
  purchased_at timestamptz default now()
);

-- ── Subsidies ──────────────────────────────────────────────────────

create table if not exists subsidies (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  description text,
  amount text,
  deadline text,
  eligible_sectors text[] default '{}'
);

-- ── Exchange ───────────────────────────────────────────────────────

create table if not exists exchange_listings (
  id uuid primary key default gen_random_uuid(),
  business_id uuid references businesses(id) on delete cascade,
  title text not null,
  description text,
  sector text,
  active boolean default true,
  created_at timestamptz default now()
);

-- ── Row Level Security ─────────────────────────────────────────────
-- The backend uses the service role key (bypasses RLS).
-- These policies are for direct Supabase client access from the Flutter app.

alter table users enable row level security;
alter table activities enable row level security;
alter table house_items enable row level security;

create policy "Users can read their own data" on users for select using (auth.uid() = id);
create policy "Users can update own data" on users for update using (auth.uid() = id);
create policy "Users can insert own activities" on activities for insert with check (auth.uid() = user_id);
create policy "Users can read own activities" on activities for select using (auth.uid() = user_id);
create policy "Users can manage own house items" on house_items for all using (auth.uid() = user_id);

-- ── Public read access for shared data ─────────────────────────────

alter table businesses enable row level security;
create policy "Anyone can read businesses" on businesses for select using (true);

alter table subsidies enable row level security;
create policy "Anyone can read subsidies" on subsidies for select using (true);

alter table exchange_listings enable row level security;
create policy "Anyone can read exchange listings" on exchange_listings for select using (true);

alter table business_suggestions enable row level security;
create policy "Anyone can read suggestions" on business_suggestions for select using (true);

alter table business_badges enable row level security;
create policy "Anyone can read badges" on business_badges for select using (true);
