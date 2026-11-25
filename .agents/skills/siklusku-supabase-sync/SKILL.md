---
name: siklusku-supabase-sync
description: >-
  Use when modifying or debugging real-time 2-phone Partner Sync, Supabase tables,
  RLS policies, triggers, Edge/RPC functions, Love Notes, or Care Progress sync
  in Siklusku / Period Tracker.
---

# Runbook Sinkronisasi 2 HP & Supabase (`Period Tracker`)

Gunakan skill ini saat mengubah fitur tab **Pasangan**, struktur Supabase, atau aliran data antar-HP.

## 1. Informasi Project & Konfigurasi
- **Project Supabase**: `Period Tracker` (ref: `cmkhribdlgcqmchommke`, region `ap-southeast-2`).
- **Endpoint**: `https://cmkhribdlgcqmchommke.supabase.co`
- **Konfigurasi Klien**: `kDefaultSupabaseUrl` & `kDefaultSupabaseAnonKey` di `lib/data/local_store.dart` (memakai **Publishable Key** + dukungan override `--dart-define` maupun form *Setup 2 HP* di `lib/features/partner/server_setup_sheet.dart`).
- **Skema Sumber**: `supabase/schema.sql` (selalu jaga agar isi `supabase/schema.sql` dan `kSupabaseSetupSql` di `server_setup_sheet.dart` identik).

## 2. Arsitektur Tabel & Aturan Keamanan Wajib

| Tabel | Fungsi | Aturan RLS & Trigger |
|---|---|---|
| `public.invites` | Kode undangan 8 huruf (berlaku 24 jam, pakai `used_at`) | Hanya `owner_id = (select auth.uid())` (`to authenticated`) |
| `public.partner_links` | Tautan aktif pemilik ↔ pasangan + izin `share_*` | Hanya anggota link (`select`/`update`); trigger `guard_partner_link_update` melarang pasangan mengubah `share_*`, `owner_id`, `partner_id` |
| `public.cycle_snapshots` | Ringkasan fase tersaring dari `buildSnapshot()` | Pemilik `for all`; pasangan hanya `for select` bila `status = 'active'` |
| `public.love_notes` | Surat cinta & reaksi dua arah | `select`/`insert`/`update`/`delete` anggota link aktif; trigger `guard_love_note_update` membatasi penerima hanya boleh update `is_read` & `reaction` |
| `public.care_progress` | Progres checklist perhatian | Anggota link aktif (`for all`) |

### Aturan Kritis Saat Mengubah SQL / Repo Supabase
1. **Jangan pernah beri izin ke role `anon`**: seluruh tabel hanya untuk `authenticated` (pengguna login lewat Anonymous Sign-Ins `signInAnonymously()` tetap ber-role `authenticated` dengan UUID `auth.uid()` permanen per instalasi).
2. **Bungkus `auth.uid()` dalam `(select auth.uid())`** di semua RLS policy dan trigger untuk kinerja optimal (*initPlan*).
3. **Pastikan `accept_invite(p_code, p_partner_name)`** selalu:
   - `SECURITY DEFINER` dengan `set search_path = ''` dan nama tabel/fungsi terkualifikasi penuh (`public.*`, `pg_catalog.*`).
   - Memeriksa `(select auth.uid()) is not null` & melarang `self_link`.
   - `revoke all ... from public, anon;` + `grant execute ... to authenticated;`.
4. **Realtime**: setiap tabel yang disinkronkan real-time wajib memiliki `replica identity full` dan terdaftar di publikasi `supabase_realtime`.
5. **Mode Offline & Test Isolation**:
   - Widget test di `test/` tidak menjalankan `main()`, sehingga `SupabaseService.isInitialized == false` dan tes otomatis memakai `DemoPartnerRepository` tanpa menyentuh jaringan. Jangan memanggil `Supabase.instance` tanpa mengecek `SupabaseService.isInitialized`.

## 3. Verifikasi Perubahan Supabase
1. Setelah mengubah SQL di project `cmkhribdlgcqmchommke`, selalu jalankan `get_advisors` (`type: "security"` dan `type: "performance"`) lewat `supabase_mcp`.
2. Pastikan skema lokal di `supabase/schema.sql` dan `kSupabaseSetupSql` di `lib/features/partner/server_setup_sheet.dart` tetap sinkron.
3. Jalankan `flutter analyze` dan `flutter test` setelah perubahan klien di `lib/data/supabase_partner_repository.dart` atau `lib/application/providers.dart`.
