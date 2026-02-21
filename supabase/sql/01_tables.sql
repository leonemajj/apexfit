-- APEXFIT tables

create table if not exists public.users (
  id uuid primary key references auth.users(id) on delete cascade,
  email text,
  username text,
  target_calories integer,
  target_weight numeric,
  height integer,
  gender text,
  avatar_url text,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

create table if not exists public.weights (
  id bigserial primary key,
  user_id uuid not null references auth.users(id) on delete cascade,
  date date not null,
  weight_kg numeric not null,
  created_at timestamptz default now(),
  updated_at timestamptz default now(),
  unique(user_id, date)
);

create table if not exists public.workouts (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  workout_type text not null,
  workout_date timestamptz not null,
  duration_minutes integer not null,
  total_calories_burned integer not null,
  notes text,
  created_at timestamptz default now()
);

create table if not exists public.meals (
  id bigserial primary key,
  user_id uuid not null references auth.users(id) on delete cascade,
  meal_type text not null,
  meal_date timestamptz not null,
  total_calories integer not null,
  notes text,
  created_at timestamptz default now()
);
