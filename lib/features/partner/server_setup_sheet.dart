// lib/features/partner/server_setup_sheet.dart
// Modal konfigurasi & panduan Supabase untuk sinkronisasi 2 HP nyata.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_icons/phosphor_icons.dart';

import '../../application/providers.dart';
import '../../core/theme.dart';
import '../../data/local_store.dart';

const kSupabaseSetupSql = r'''-- Jalankan sekali di Supabase SQL Editor (Dashboard > SQL Editor)
create extension if not exists pgcrypto;

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

create table if not exists public.care_progress (
  link_id uuid primary key references public.partner_links(id) on delete cascade,
  checked_ids text[] not null default '{}',
  updated_at timestamptz not null default now()
);

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

revoke all on public.invites, public.partner_links, public.cycle_snapshots, public.love_notes, public.care_progress from anon, public;
grant select, insert, update, delete on public.invites, public.cycle_snapshots, public.love_notes, public.care_progress to authenticated;
grant select, update on public.partner_links to authenticated;

alter table public.invites enable row level security;
alter table public.partner_links enable row level security;
alter table public.cycle_snapshots enable row level security;
alter table public.love_notes enable row level security;
alter table public.care_progress enable row level security;

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
  if v_caller is null then raise exception 'unauthenticated'; end if;
  update public.invites
  set used_at = pg_catalog.now()
  where code = pg_catalog.upper(pg_catalog.trim(p_code))
    and used_at is null
    and expires_at > pg_catalog.now()
  returning * into v_inv;
  if v_inv.owner_id is null then raise exception 'invalid_or_expired'; end if;
  if v_inv.owner_id = v_caller then raise exception 'self_link'; end if;

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
end $$;''';

Future<void> showServerSetupSheet(BuildContext context) => showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => const _ServerSetupSheet(),
    );

class _ServerSetupSheet extends ConsumerStatefulWidget {
  const _ServerSetupSheet();

  @override
  ConsumerState<_ServerSetupSheet> createState() => _ServerSetupSheetState();
}

class _ServerSetupSheetState extends ConsumerState<_ServerSetupSheet> {
  late final TextEditingController _name;
  late final TextEditingController _url;
  late final TextEditingController _key;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final cfg = ref.read(serverConfigProvider);
    _name = TextEditingController(text: cfg.displayName);
    _url = TextEditingController(text: cfg.supabaseUrl);
    _key = TextEditingController(text: cfg.supabaseAnonKey);
  }

  @override
  void dispose() {
    _name.dispose();
    _url.dispose();
    _key.dispose();
    super.dispose();
  }

  Future<void> _connect() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final next = ServerConfig(
        supabaseUrl: _url.text.trim(),
        supabaseAnonKey: _key.text.trim(),
        displayName: _name.text.trim().isEmpty ? 'Pasangan' : _name.text.trim(),
      );
      await ref.read(supabaseConnectedProvider.notifier).connect(next);
      await ref.read(partnerProvider.notifier).syncWithServer();
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sinkronisasi 2 HP nyata aktif! 🌐🎀')),
      );
    } catch (e) {
      final rawMsg = e.toString();
      if (mounted) {
        setState(() => _error = rawMsg.replaceFirst('FormatException: ', ''));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _saveNameOnly() async {
    final next = ref.read(serverConfigProvider).copyWith(
          displayName: _name.text.trim().isEmpty ? 'Pasangan' : _name.text.trim(),
        );
    await ref.read(serverConfigProvider.notifier).save(next);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Nama panggilan disimpan ✨')),
    );
  }

  Future<void> _disconnect() async {
    await ref.read(supabaseConnectedProvider.notifier).disconnect();
    await ref.read(partnerProvider.notifier).resetLocalCache();
    if (!mounted) return;
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Kembali ke mode lokal.')),
    );
  }

  Future<void> _copySql() async {
    await Clipboard.setData(const ClipboardData(text: kSupabaseSetupSql));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Script SQL Supabase disalin! Paste ke SQL Editor Supabase 📋')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final connected = ref.watch(supabaseConnectedProvider);

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(22, 18, 22, 24 + bottomInset),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.ribbon,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text('Sinkronisasi 2 HP Nyata 🌐', style: kHeading.copyWith(fontSize: 20)),
          const SizedBox(height: 6),
          const Text(
            'Hubungkan ke project Supabase gratis agar kamu dan pasangan bisa terhubung antar-HP '
            'secara real-time (termasuk update fase, izin privasi, & surat cinta dua arah).',
            style: kSmall,
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.blush,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.petal),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Langkah cepat (1x saja untuk kedua HP):',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                const SizedBox(height: 6),
                const Text(
                  '1. Buat project gratis di supabase.com\n'
                  '2. Masuk Authentication > Providers > aktifkan "Allow anonymous sign-ins"\n'
                  '3. Masuk SQL Editor > tempel & jalankan SQL Schema di bawah ini\n'
                  '4. Masukkan Project URL & Publishable/Anon Key yang sama di kedua HP',
                  style: kSmall,
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: _copySql,
                  icon: const Icon(PhosphorIconsRegular.copy, size: 16),
                  label: const Text('Salin Script SQL Schema'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _name,
            decoration: InputDecoration(
              labelText: 'Nama panggilanmu (untuk pasangan)',
              hintText: 'Contoh: Ruru atau Sahrul',
              filled: true,
              fillColor: AppColors.blush,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
              suffixIcon: IconButton(
                tooltip: 'Simpan nama saja',
                icon: const Icon(PhosphorIconsRegular.check),
                onPressed: _saveNameOnly,
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _url,
            keyboardType: TextInputType.url,
            decoration: InputDecoration(
              labelText: 'Supabase Project URL',
              hintText: 'https://xxxx.supabase.co',
              filled: true,
              fillColor: AppColors.blush,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _key,
            decoration: InputDecoration(
              labelText: 'Supabase Anon / Publishable Key',
              hintText: 'sb_publishable_... atau eyJ...',
              filled: true,
              fillColor: AppColors.blush,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 10),
            Text(_error!, style: const TextStyle(color: AppColors.danger, fontSize: 12.5)),
          ],
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _loading ? null : _connect,
            child: Text(_loading ? 'Menghubungkan...' : 'Simpan & Aktifkan 2 HP'),
          ),
          if (connected) ...[
            const SizedBox(height: 8),
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.danger,
                side: const BorderSide(color: AppColors.danger),
              ),
              onPressed: _disconnect,
              child: const Text('Putuskan Server & Pakai Mode Lokal'),
            ),
          ],
        ],
      ),
    );
  }
}
