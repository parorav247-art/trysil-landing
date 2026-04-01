-- Trysil.AI — Supabase Schema
-- Run this in your Supabase SQL Editor after creating your project

-- Enable UUID extension
create extension if not exists "uuid-ossp";

-- Users / signups
create table public.users (
  id uuid primary key default uuid_generate_v4(),
  email text unique not null,
  name text,
  partner_name text,
  partner_email text,
  created_at timestamptz default now()
);

-- Pulse sessions (one per family, per attempt)
create table public.pulse_sessions (
  id uuid primary key default uuid_generate_v4(),
  user_id uuid references public.users(id) on delete cascade,
  status text default 'in_progress', -- in_progress | complete
  created_at timestamptz default now(),
  completed_at timestamptz
);

-- Q1: Who's in your world
create table public.q1_answers (
  id uuid primary key default uuid_generate_v4(),
  session_id uuid references public.pulse_sessions(id) on delete cascade,
  has_kids boolean default false,
  kid_ages text[], -- ['Under 5', '5-10', etc.]
  has_pets boolean default false,
  has_aging_parents boolean default false,
  has_other boolean default false,
  created_at timestamptz default now()
);

-- Q2: Who handles what (one row per category)
create table public.q2_answers (
  id uuid primary key default uuid_generate_v4(),
  session_id uuid references public.pulse_sessions(id) on delete cascade,
  category text not null, -- school | meals | sports | health | home | finances
  load_pct integer not null, -- 0-100 (partner A's percentage)
  sentiment integer not null default 1, -- 2=happy 1=neutral 0=stressed
  tools text[], -- selected tool chips
  created_at timestamptz default now()
);

-- Q3: Biggest stress source (private per partner)
create table public.q3_answers (
  id uuid primary key default uuid_generate_v4(),
  session_id uuid references public.pulse_sessions(id) on delete cascade,
  responder text not null, -- 'partner_a' | 'partner_b'
  stress_type text not null,
  stress_text text, -- free text if 'other'
  created_at timestamptz default now()
);

-- Q4: 30-day win (private per partner)
create table public.q4_answers (
  id uuid primary key default uuid_generate_v4(),
  session_id uuid references public.pulse_sessions(id) on delete cascade,
  responder text not null,
  win_type text not null,
  win_text text,
  created_at timestamptz default now()
);

-- Pulse results (computed output)
create table public.pulse_results (
  id uuid primary key default uuid_generate_v4(),
  session_id uuid references public.pulse_sessions(id) on delete cascade,
  avg_load_pct integer, -- partner A's average load across all categories
  top_priorities jsonb, -- [{cat, load, sentiment, label}]
  alignment_data jsonb, -- [{cat, status: 'balanced'|'slight-lean'|'imbalanced'}]
  created_at timestamptz default now()
);

-- Row Level Security (enable after testing)
-- alter table public.users enable row level security;
-- alter table public.pulse_sessions enable row level security;
-- alter table public.q1_answers enable row level security;
-- alter table public.q2_answers enable row level security;
-- alter table public.q3_answers enable row level security;
-- alter table public.q4_answers enable row level security;
-- alter table public.pulse_results enable row level security;
