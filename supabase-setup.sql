-- ============================================================================
--  NEON PORTFOLIO — Supabase setup
--  Run once:  Supabase Dashboard → SQL Editor → New query → paste → Run
-- ============================================================================
--  Creates:
--    portfolio_public   public content  (world-readable, owner-writable)
--    portfolio_private  private details (owner-readable ONLY)
--    certificates       storage bucket for certificate images
--
--  SECURITY MODEL
--  Public signup is currently ENABLED on this project, so "any logged-in user"
--  would NOT be safe. Every write policy below is pinned to one email address.
--  If you change your email, update OWNER_EMAIL here and in index.html.
-- ============================================================================

-- ---------------------------------------------------------------- owner check
create or replace function public.is_owner()
returns boolean
language sql
stable
as $$
  select coalesce(auth.jwt() ->> 'email', '') = 'bharathk9828@gmail.com'
$$;

-- ---------------------------------------------------------------------- tables
create table if not exists public.portfolio_public (
  id         text primary key default 'main',
  data       jsonb       not null default '{}'::jsonb,
  updated_at timestamptz not null default now()
);

create table if not exists public.portfolio_private (
  id         text primary key default 'main',
  data       jsonb       not null default '{}'::jsonb,
  updated_at timestamptz not null default now()
);

-- keep updated_at honest
create or replace function public.touch_updated_at()
returns trigger language plpgsql as $$
begin new.updated_at = now(); return new; end $$;

drop trigger if exists trg_touch_public on public.portfolio_public;
create trigger trg_touch_public before insert or update on public.portfolio_public
  for each row execute function public.touch_updated_at();

drop trigger if exists trg_touch_private on public.portfolio_private;
create trigger trg_touch_private before insert or update on public.portfolio_private
  for each row execute function public.touch_updated_at();

-- ------------------------------------------------------------------------ RLS
alter table public.portfolio_public  enable row level security;
alter table public.portfolio_private enable row level security;

-- PUBLIC table: anyone may read, only the owner may write.
drop policy if exists "portfolio_public read"  on public.portfolio_public;
create policy "portfolio_public read" on public.portfolio_public
  for select using (true);

drop policy if exists "portfolio_public write" on public.portfolio_public;
create policy "portfolio_public write" on public.portfolio_public
  for all to authenticated
  using (public.is_owner())
  with check (public.is_owner());

-- PRIVATE table: owner only, for reads AND writes. No anonymous access at all.
drop policy if exists "portfolio_private owner" on public.portfolio_private;
create policy "portfolio_private owner" on public.portfolio_private
  for all to authenticated
  using (public.is_owner())
  with check (public.is_owner());

-- -------------------------------------------------------------- storage bucket
insert into storage.buckets (id, name, public)
values ('certificates', 'certificates', true)
on conflict (id) do nothing;

drop policy if exists "certs public read" on storage.objects;
create policy "certs public read" on storage.objects
  for select using (bucket_id = 'certificates');

drop policy if exists "certs owner insert" on storage.objects;
create policy "certs owner insert" on storage.objects
  for insert to authenticated
  with check (bucket_id = 'certificates' and public.is_owner());

drop policy if exists "certs owner update" on storage.objects;
create policy "certs owner update" on storage.objects
  for update to authenticated
  using (bucket_id = 'certificates' and public.is_owner())
  with check (bucket_id = 'certificates' and public.is_owner());

drop policy if exists "certs owner delete" on storage.objects;
create policy "certs owner delete" on storage.objects
  for delete to authenticated
  using (bucket_id = 'certificates' and public.is_owner());

-- ---------------------------------------------------------------------- verify
-- Should list both tables with rowsecurity = true
select tablename, rowsecurity
from pg_tables
where schemaname = 'public'
  and tablename in ('portfolio_public','portfolio_private');
