-- supabase/schema.sql
-- Skema database & Row Level Security (RLS) untuk sinkronisasi 2 HP Siklusku.
-- Jalankan seluruh script ini satu kali di Supabase SQL Editor.

create extension if not exists pgcrypto;

-- 1. Kode undangan 8 karakter (sekali pakai, berlaku 24 jam)
create table if not exists public.invites (
  code text primary key,
  owner_id uuid not null references auth.users(id) on delete cascade,
  owner_name text not null default 'Pasangan',
  expires_at timestamptz not null,
  created_at timestamptz not null default now()
);

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

-- 3. Snapshot siklus tersaring (TIDAK pernah berisi catatan pribadi, gejala, atau mood)
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

-- 5. Progres checklist perhatian pasangan (tersinkron)
create table if not exists public.care_progress (
  link_id uuid primary key references public.partner_links(id) on delete cascade,
  checked_ids text[] not null default '{}',
  updated_at timestamptz not null default now()
);

-- Aktifkan Row Level Security di semua tabel
alter table public.invites enable row level security;
alter table public.partner_links enable row level security;
alter table public.cycle_snapshots enable row level security;
alter table public.love_notes enable row level security;
alter table public.care_progress enable row level security;

-- Policies: invites
drop policy if exists invites_owner on public.invites;
create policy invites_owner on public.invites
  for all using (owner_id = auth.uid()) with check (owner_id = auth.uid());

-- Policies: partner_links
drop policy if exists links_read_member on public.partner_links;
create policy links_read_member on public.partner_links
  for select using (owner_id = auth.uid() or partner_id = auth.uid());

drop policy if exists links_update_owner on public.partner_links;
create policy links_update_owner on public.partner_links
  for update using (owner_id = auth.uid() or partner_id = auth.uid())
  with check (owner_id = auth.uid() or partner_id = auth.uid());

-- Policies: cycle_snapshots
drop policy if exists snap_owner on public.cycle_snapshots;
create policy snap_owner on public.cycle_snapshots
  for all using (owner_id = auth.uid()) with check (owner_id = auth.uid());

drop policy if exists snap_partner_read on public.cycle_snapshots;
create policy snap_partner_read on public.cycle_snapshots
  for select using (
    exists (
      select 1 from public.partner_links l
      where l.owner_id = cycle_snapshots.owner_id
        and l.partner_id = auth.uid()
        and l.status = 'active'
    )
  );

-- Policies: love_notes
drop policy if exists love_notes_member_all on public.love_notes;
create policy love_notes_member_all on public.love_notes
  for all using (
    exists (
      select 1 from public.partner_links l
      where l.id = love_notes.link_id
        and l.status = 'active'
        and (l.owner_id = auth.uid() or l.partner_id = auth.uid())
    )
  )
  with check (
    exists (
      select 1 from public.partner_links l
      where l.id = love_notes.link_id
        and l.status = 'active'
        and (l.owner_id = auth.uid() or l.partner_id = auth.uid())
    )
  );

-- Policies: care_progress
drop policy if exists care_progress_member_all on public.care_progress;
create policy care_progress_member_all on public.care_progress
  for all using (
    exists (
      select 1 from public.partner_links l
      where l.id = care_progress.link_id
        and l.status = 'active'
        and (l.owner_id = auth.uid() or l.partner_id = auth.uid())
    )
  )
  with check (
    exists (
      select 1 from public.partner_links l
      where l.id = care_progress.link_id
        and l.status = 'active'
        and (l.owner_id = auth.uid() or l.partner_id = auth.uid())
    )
  );

-- Fungsi atomik menerima kode undangan (sekali pakai, cek kedaluwarsa, cegah tautan ke diri sendiri)
create or replace function public.accept_invite(p_code text, p_partner_name text default 'Pasangan')
returns public.partner_links
language plpgsql
security definer
set search_path = public
as $$
declare
  v_inv public.invites%rowtype;
  v_link public.partner_links%rowtype;
  v_caller uuid := auth.uid();
begin
  if v_caller is null then
    raise exception 'unauthenticated';
  end if;

  delete from public.invites
  where code = upper(trim(p_code)) and expires_at > now()
  returning * into v_inv;

  if v_inv.owner_id is null then
    raise exception 'invalid_or_expired';
  end if;

  if v_inv.owner_id = v_caller then
    raise exception 'self_link';
  end if;

  -- Putuskan link aktif lama (MVP: 1 pasangan aktif per pengguna)
  update public.partner_links
  set status = 'revoked', updated_at = now()
  where status = 'active'
    and (owner_id = v_inv.owner_id or partner_id = v_caller or owner_id = v_caller or partner_id = v_inv.owner_id)
    and not (owner_id = v_inv.owner_id and partner_id = v_caller);

  insert into public.partner_links (owner_id, partner_id, owner_name, partner_name, status, updated_at)
  values (v_inv.owner_id, v_caller, coalesce(nullif(trim(v_inv.owner_name), ''), 'Pasangan'), coalesce(nullif(trim(p_partner_name), ''), 'Pasangan'), 'active', now())
  on conflict (owner_id, partner_id) do update
  set status = 'active',
      owner_name = coalesce(nullif(trim(v_inv.owner_name), ''), 'Pasangan'),
      partner_name = coalesce(nullif(trim(p_partner_name), ''), 'Pasangan'),
      updated_at = now()
  returning * into v_link;

  return v_link;
end $$;

grant execute on function public.accept_invite(text, text) to authenticated;

-- Aktifkan Realtime untuk pembaruan instan antar 2 HP
do $$
begin
  if not exists (
    select 1 from pg_publication_tables where pubname = 'supabase_realtime' and tablename = 'partner_links'
  ) then
    alter publication supabase_realtime add table public.partner_links;
  end if;
  if not exists (
    select 1 from pg_publication_tables where pubname = 'supabase_realtime' and tablename = 'cycle_snapshots'
  ) then
    alter publication supabase_realtime add table public.cycle_snapshots;
  end if;
  if not exists (
    select 1 from pg_publication_tables where pubname = 'supabase_realtime' and tablename = 'love_notes'
  ) then
    alter publication supabase_realtime add table public.love_notes;
  end if;
  if not exists (
    select 1 from pg_publication_tables where pubname = 'supabase_realtime' and tablename = 'care_progress'
  ) then
    alter publication supabase_realtime add table public.care_progress;
  end if;
end $$;
