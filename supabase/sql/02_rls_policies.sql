-- Enable RLS
alter table public.users enable row level security;
alter table public.weights enable row level security;
alter table public.workouts enable row level security;
alter table public.meals enable row level security;

-- users: read/update own
drop policy if exists "users_select_own" on public.users;
create policy "users_select_own" on public.users
for select using (auth.uid() = id);

drop policy if exists "users_update_own" on public.users;
create policy "users_update_own" on public.users
for update using (auth.uid() = id);

drop policy if exists "users_insert_own" on public.users;
create policy "users_insert_own" on public.users
for insert with check (auth.uid() = id);

-- weights
drop policy if exists "weights_all_own" on public.weights;
create policy "weights_all_own" on public.weights
for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

-- workouts
drop policy if exists "workouts_all_own" on public.workouts;
create policy "workouts_all_own" on public.workouts
for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

-- meals
drop policy if exists "meals_all_own" on public.meals;
create policy "meals_all_own" on public.meals
for all using (auth.uid() = user_id) with check (auth.uid() = user_id);
