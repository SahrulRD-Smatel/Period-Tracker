-- supabase/schema.sql
-- Skema database & Row Level Security (RLS) untuk sinkronisasi 2 HP Siklusku.
-- Sudah terpasang pada project Supabase "Period Tracker".

create extension if not exists pgcrypto;

-- 1. Kode undangan 8 karakter (sekali pakai, berlaku 24 jam)
create table if not exists public.invites (
  code text primary key,
  owner_id uuid not null references auth.users(id) on delete cascade,
  owner_name text not null default 'Pasangan',
  expires_at timestamptz not null,
  used_at timestamptz,
  created_at timestamptz not null default now()
);

create index if not exists invites_owner_expires_idx
  on public.invites (owner_id, expires_at desc);

-- 2. Tautan aktif antara pemilik data & pasangan + izin berbagi per kolom
create table if not exists public.partner_links (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references auth.users(id) on delete cascade,
  partner_id uuid not null references auth.users(id) on delete cascade,
  owner_name text not null default 'Pasangan',
  partner_name text not null default 'Pasangan',
  share_phase boolean not null default true,
  share_fertile boolean not null default true,
  share_next_period boolean not null default true,
  status text not null default 'active' check (status in ('active', 'revoked')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (owner_id, partner_id)
);

create index if not exists partner_links_owner_status_idx
  on public.partner_links (owner_id, status);
create index if not exists partner_links_partner_status_idx
  on public.partner_links (partner_id, status);

-- 3. Snapshot siklus tersaring (TIDAK pernah berisi gejala, mood, atau catatan diary)
create table if not exists public.cycle_snapshots (
  owner_id uuid primary key references auth.users(id) on delete cascade,
  phase text,
  cycle_day int,
  lateness text,
  next_period date,
  fertile_start date,
  fertile_end date,
  ovulation date,
  updated_at timestamptz not null default now()
);

-- 4. Surat cinta & reaksi dua arah antar pasangan
create table if not exists public.love_notes (
  id text primary key,
  link_id uuid not null references public.partner_links(id) on delete cascade,
  sender_id uuid not null references auth.users(id) on delete cascade,
  sender_name text not null default 'Pasangan',
  message text not null,
  trigger text not null default 'anytime' check (trigger in ('menstrual', 'luteal', 'anytime')),
  reaction text,
  is_read boolean not null default false,
  created_at timestamptz not null default now()
);

create index if not exists love_notes_link_created_idx
  on public.love_notes (link_id, created_at desc);
create index if not exists love_notes_sender_id_idx
  on public.love_notes (sender_id);

-- 5. Progres checklist perhatian pasangan (tersinkron)
create table if not exists public.care_progress (
  link_id uuid primary key references public.partner_links(id) on delete cascade,
  checked_ids text[] not null default '{}',
  updated_at timestamptz not null default now()
);

-- Triggers anti-tampering
create or replace function public.guard_partner_link_update()
returns trigger
language plpgsql
security invoker
set search_path = ''
as $$
declare
  v_uid uuid := (select auth.uid());
begin
  if new.owner_id is distinct from old.owner_id or new.partner_id is distinct from old.partner_id then
    raise exception 'cannot_change_link_members';
  end if;

  if v_uid is not null and v_uid = old.partner_id and v_uid <> old.owner_id then
    if new.share_phase is distinct from old.share_phase
       or new.share_fertile is distinct from old.share_fertile
       or new.share_next_period is distinct from old.share_next_period
       or new.owner_name is distinct from old.owner_name then
      raise exception 'only_owner_can_change_share_flags';
    end if;
    if new.status not in ('active', 'revoked') or (old.status = 'revoked' and new.status = 'active') then
      raise exception 'invalid_status_transition';
    end if;
  end if;
  return new;
end $$;

drop trigger if exists trg_guard_partner_link_update on public.partner_links;
create trigger trg_guard_partner_link_update
  before update on public.partner_links
  for each row execute function public.guard_partner_link_update();

create or replace function public.guard_love_note_update()
returns trigger
language plpgsql
security invoker
set search_path = ''
as $$
begin
  if new.id is distinct from old.id
     or new.link_id is distinct from old.link_id
     or new.sender_id is distinct from old.sender_id
     or new.sender_name is distinct from old.sender_name
     or new.message is distinct from old.message
     or new.trigger is distinct from old.trigger then
    raise exception 'only_read_and_reaction_can_be_updated';
  end if;
  return new;
end $$;

drop trigger if exists trg_guard_love_note_update on public.love_notes;
create trigger trg_guard_love_note_update
  before update on public.love_notes
  for each row execute function public.guard_love_note_update();

-- Cabut anon, beri grant hanya untuk authenticated
revoke all on public.invites, public.partner_links, public.cycle_snapshots, public.love_notes, public.care_progress from anon, public;
grant select, insert, update, delete on public.invites, public.cycle_snapshots, public.love_notes, public.care_progress to authenticated;
grant select, update on public.partner_links to authenticated;

-- Aktifkan RLS di semua tabel
alter table public.invites enable row level security;
alter table public.partner_links enable row level security;
alter table public.cycle_snapshots enable row level security;
alter table public.love_notes enable row level security;
alter table public.care_progress enable row level security;

-- Policies
drop policy if exists invites_owner on public.invites;
create policy invites_owner on public.invites for all to authenticated
  using ((select auth.uid()) = owner_id)
  with check ((select auth.uid()) = owner_id);

drop policy if exists links_read_member on public.partner_links;
create policy links_read_member on public.partner_links for select to authenticated
  using ((select auth.uid()) = owner_id or (select auth.uid()) = partner_id);

drop policy if exists links_update_member on public.partner_links;
create policy links_update_member on public.partner_links for update to authenticated
  using ((select auth.uid()) = owner_id or (select auth.uid()) = partner_id)
  with check ((select auth.uid()) = owner_id or (select auth.uid()) = partner_id);

drop policy if exists snap_owner on public.cycle_snapshots;
create policy snap_owner on public.cycle_snapshots for all to authenticated
  using ((select auth.uid()) = owner_id)
  with check ((select auth.uid()) = owner_id);

drop policy if exists snap_partner_read on public.cycle_snapshots;
create policy snap_partner_read on public.cycle_snapshots for select to authenticated
  using (exists (
    select 1 from public.partner_links l
    where l.owner_id = cycle_snapshots.owner_id
      and l.partner_id = (select auth.uid())
      and l.status = 'active'
  ));

drop policy if exists love_notes_member_select on public.love_notes;
create policy love_notes_member_select on public.love_notes for select to authenticated
  using (exists (
    select 1 from public.partner_links l
    where l.id = love_notes.link_id and l.status = 'active'
      and ((select auth.uid()) = l.owner_id or (select auth.uid()) = l.partner_id)
  ));

drop policy if exists love_notes_member_insert on public.love_notes;
create policy love_notes_member_insert on public.love_notes for insert to authenticated
  with check (sender_id = (select auth.uid()) and exists (
    select 1 from public.partner_links l
    where l.id = love_notes.link_id and l.status = 'active'
      and ((select auth.uid()) = l.owner_id or (select auth.uid()) = l.partner_id)
  ));

drop policy if exists love_notes_member_update on public.love_notes;
create policy love_notes_member_update on public.love_notes for update to authenticated
  using (exists (
    select 1 from public.partner_links l
    where l.id = love_notes.link_id and l.status = 'active'
      and ((select auth.uid()) = l.owner_id or (select auth.uid()) = l.partner_id)
  ))
  with check (exists (
    select 1 from public.partner_links l
    where l.id = love_notes.link_id and l.status = 'active'
      and ((select auth.uid()) = l.owner_id or (select auth.uid()) = l.partner_id)
  ));

drop policy if exists love_notes_member_delete on public.love_notes;
create policy love_notes_member_delete on public.love_notes for delete to authenticated
  using (sender_id = (select auth.uid()) and exists (
    select 1 from public.partner_links l
    where l.id = love_notes.link_id and l.status = 'active'
      and ((select auth.uid()) = l.owner_id or (select auth.uid()) = l.partner_id)
  ));

drop policy if exists care_progress_member_all on public.care_progress;
create policy care_progress_member_all on public.care_progress for all to authenticated
  using (exists (
    select 1 from public.partner_links l
    where l.id = care_progress.link_id and l.status = 'active'
      and ((select auth.uid()) = l.owner_id or (select auth.uid()) = l.partner_id)
  ))
  with check (exists (
    select 1 from public.partner_links l
    where l.id = care_progress.link_id and l.status = 'active'
      and ((select auth.uid()) = l.owner_id or (select auth.uid()) = l.partner_id)
  ));

-- Fungsi atomik menerima kode undangan
create or replace function public.accept_invite(p_code text, p_partner_name text default 'Pasangan')
returns public.partner_links
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_inv public.invites%rowtype;
  v_link public.partner_links%rowtype;
  v_caller uuid := (select auth.uid());
begin
  if v_caller is null then
    raise exception 'unauthenticated';
  end if;

  update public.invites
  set used_at = pg_catalog.now()
  where code = pg_catalog.upper(pg_catalog.trim(p_code))
    and used_at is null
    and expires_at > pg_catalog.now()
  returning * into v_inv;

  if v_inv.owner_id is null then
    raise exception 'invalid_or_expired';
  end if;

  if v_inv.owner_id = v_caller then
    raise exception 'self_link';
  end if;

  update public.partner_links
  set status = 'revoked', updated_at = pg_catalog.now()
  where status = 'active'
    and (owner_id = v_inv.owner_id or partner_id = v_caller or owner_id = v_caller or partner_id = v_inv.owner_id)
    and not (owner_id = v_inv.owner_id and partner_id = v_caller);

  insert into public.partner_links (owner_id, partner_id, owner_name, partner_name, status, updated_at)
  values (
    v_inv.owner_id,
    v_caller,
    pg_catalog.coalesce(pg_catalog.nullif(pg_catalog.trim(v_inv.owner_name), ''), 'Pasangan'),
    pg_catalog.coalesce(pg_catalog.nullif(pg_catalog.trim(p_partner_name), ''), 'Pasangan'),
    'active',
    pg_catalog.now()
  )
  on conflict (owner_id, partner_id) do update
  set status = 'active',
      owner_name = pg_catalog.coalesce(pg_catalog.nullif(pg_catalog.trim(v_inv.owner_name), ''), 'Pasangan'),
      partner_name = pg_catalog.coalesce(pg_catalog.nullif(pg_catalog.trim(p_partner_name), ''), 'Pasangan'),
      updated_at = pg_catalog.now()
  returning * into v_link;

  return v_link;
end $$;

revoke all on function public.accept_invite(text, text) from public, anon;
grant execute on function public.accept_invite(text, text) to authenticated;

alter table public.partner_links replica identity full;
alter table public.cycle_snapshots replica identity full;
alter table public.love_notes replica identity full;
alter table public.care_progress replica identity full;

do $$
begin
  if not exists (select 1 from pg_publication_tables where pubname = 'supabase_realtime' and tablename = 'partner_links') then
    alter publication supabase_realtime add table public.partner_links;
  end if;
  if not exists (select 1 from pg_publication_tables where pubname = 'supabase_realtime' and tablename = 'cycle_snapshots') then
    alter publication supabase_realtime add table public.cycle_snapshots;
  end if;
  if not exists (select 1 from pg_publication_tables where pubname = 'supabase_realtime' and tablename = 'love_notes') then
    alter publication supabase_realtime add table public.love_notes;
  end if;
  if not exists (select 1 from pg_publication_tables where pubname = 'supabase_realtime' and tablename = 'care_progress') then
    alter publication supabase_realtime add table public.care_progress;
  end if;
end $$;
