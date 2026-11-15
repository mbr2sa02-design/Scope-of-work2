-- MBR2 Scope of Works FY27 — Supabase schema. Run once in: Dashboard > SQL Editor.

create table if not exists public.profiles (
  id    uuid primary key references auth.users(id) on delete cascade,
  name  text not null,                       -- must match a staff name in the app, or 'Manager'
  role  text not null default 'staff' check (role in ('staff','manager'))
);

create table if not exists public.records (
  k          text primary key,               -- JSON key array, e.g. ["a","Name","code","desc","month"]
  staff      text not null,                  -- owner staff name (= k[1])
  v          jsonb,
  updated_by text,
  updated_at timestamptz not null default now()
);
create index if not exists records_updated_idx on public.records (updated_at desc);

-- helper functions (security definer so RLS on profiles doesn't recurse)
create or replace function public.my_name() returns text
language sql stable security definer set search_path = public as
$$ select name from public.profiles where id = auth.uid() $$;

create or replace function public.is_manager() returns boolean
language sql stable security definer set search_path = public as
$$ select coalesce((select role = 'manager' from public.profiles where id = auth.uid()), false) $$;

-- stamp who/when on the server so it cannot be spoofed
create or replace function public.stamp_record() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  new.updated_by := public.my_name();
  new.updated_at := now();
  return new;
end $$;

drop trigger if exists records_stamp on public.records;
create trigger records_stamp before insert or update on public.records
  for each row execute function public.stamp_record();

-- Row Level Security
alter table public.profiles enable row level security;
alter table public.records  enable row level security;

drop policy if exists profiles_read_own on public.profiles;
create policy profiles_read_own on public.profiles for select to authenticated
  using (id = auth.uid() or public.is_manager());

drop policy if exists records_read on public.records;
create policy records_read on public.records for select to authenticated using (true);

drop policy if exists records_insert on public.records;
create policy records_insert on public.records for insert to authenticated
  with check (public.is_manager() or staff = public.my_name());

drop policy if exists records_update on public.records;
create policy records_update on public.records for update to authenticated
  using (public.is_manager() or staff = public.my_name())
  with check (public.is_manager() or staff = public.my_name());

drop policy if exists records_delete on public.records;
create policy records_delete on public.records for delete to authenticated
  using (public.is_manager() or staff = public.my_name());

-- Realtime
alter table public.records replica identity full;
do $$ begin
  alter publication supabase_realtime add table public.records;
exception when duplicate_object then null; end $$;

-- ---------------------------------------------------------------
-- ADD USERS: 1) Authentication > Users > Add user (email + password, tick "Auto confirm")
--            2) then link each to a staff name (name must match the app exactly):
--
-- insert into public.profiles (id, name, role)
--   select id, 'Manager', 'manager' from auth.users where email = 'manager@example.org';
-- insert into public.profiles (id, name, role)
--   select id, 'STAFF NAME HERE', 'staff' from auth.users where email = 'staff1@example.org';
