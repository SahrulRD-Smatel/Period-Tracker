---
name: siklusku-feature
description: >-
  Use whenever adding, modifying, or fixing any feature in Siklusku / Period Tracker
  (Flutter + Riverpod + Cyra UI + SharedPreferences/Supabase). Prevents disconnected demo stubs,
  broken cross-feature wiring, domain/Flutter coupling, and layout overflows.
---

# Runbook Menambah Fitur di Siklusku (`period_tracker`)

Gunakan skill ini **sebelum menulis kode fitur apa pun** supaya tidak ada fitur yang "ngawang", terputus antar-layar, atau berhenti menjadi demo statis.

## 1. Sumber Kebenaran yang Wajib Dibaca Dulu
1. [`.agent/AGENT.md`](../../../.agent/AGENT.md) — peta arsitektur & 11 aturan wajib.
2. [`.agent/LOGIC.md`](../../../.agent/LOGIC.md) — rumus siklus, ovulasi mundur, fase terlambat, dan sinkronisasi log.
3. [`.agent/STATUS.md`](../../../.agent/STATUS.md) — posisi fitur terkini.
4. [`.agent/FEATURE_CHECKLIST.md`](../../../.agent/FEATURE_CHECKLIST.md) — daftar periksa privasi & Definition of Done.

## 2. Aturan Keterhubungan Fitur (Anti-Ngawang)

Saat merancang fitur baru, wajib jawab dan sambungkan **kelima jalur ini** sejak awal:

1. **Domain Murni (`lib/domain/`)**:
   - Semua rumus, filter, transformasi data, dan aturan validasi WAJIB berada di `lib/domain/*.dart` tanpa import `flutter`, `riverpod`, `shared_preferences`, atau `supabase_flutter`.
   - Normalisasi seluruh tanggal dengan `dateOnly()` (UTC tanpa jam).
   - Jika fitur berhubungan dengan pencatatan harian atau siklus (misal gejala baru, tes LH/BBT, obat, suhu basal), periksa dampaknya ke `cycle_sync.dart`, `predictionProvider`, `homeSummaryProvider`, `dayViewFor()`, dan `stats.dart`.

2. **Persistensi & Cadangan (`lib/data/` + `lib/domain/full_backup.dart`)**:
   - DILARANG menyimpan state jangka panjang hanya di `StatefulWidget` (`State`) atau RAM saja!
   - Buat/perbarui interface Repository di `lib/data/` beserta implementasi `SharedPreferences` (`local_store.dart`).
   - Jika menambah data milik pengguna, WAJIB masukkan ke `exportFullBackup` / `importFullBackup` (`full_backup.dart`, naikkan versi bila format berubah tetapi tetap baca v1/v2/v3), `data_actions.dart` (`restoreBackup`), dan bersihkan di `wipeAllData()`.

3. **Riverpod State & Sinkronisasi Lintas-Tab (`lib/application/providers.dart`)**:
   - UI membaca & memodifikasi state hanya melalui `NotifierProvider` / `Provider` di `providers.dart`.
   - Pastikan tab **Beranda**, **Kalender**, **Statistik**, **Pasangan**, dan **Notifikasi** ikut bereaksi otomatis ketika state utama berubah (gunakan `ref.watch` pada turunan provider atau `ref.listen` di `lib/app.dart`).

4. **Privasi Pasangan & Cloud Sync (`lib/domain/partner_models.dart`)**:
   - Catatan pribadi (gejala, mood, aliran detail, diary teks) **HARAM** keluar dari perangkat atau masuk ke `PartnerSnapshot` / `cycle_snapshots`.
   - Jika fitur baru memang untuk dibagikan ke pasangan, lewatkan penyaring `buildSnapshot()` dan baca juga skill [`siklusku-supabase-sync`](../siklusku-supabase-sync/SKILL.md).

5. **Desain Cyra & Keamanan Layout (`lib/core/` + `lib/features/`)**:
   - Semua warna wajib berasal dari `AppColors` (`lib/core/theme.dart`) atau `phaseStyle()`. Dilarang menulis hex `Color(0x...)` atau `Colors.*` di berkas fitur.
   - Semua layar wajib dibungkus `AppScaffold` (Dynamic Island + Gesture Nav SafeArea).
   - Setiap `Row` yang berisi teks dinamis wajib membungkus `Text` dengan `Expanded` + `maxLines` / `overflow: TextOverflow.ellipsis`, supaya lulus tanpa `RenderFlex overflow` pada layar `390–440 pt`.
   - Semua teks UI berbahasa Indonesia yang hangat & non-diagnostik.

## 3. Verifikasi Wajib Sebelum Selesai

Jangan nyatakan fitur selesai sebelum seluruh langkah ini dijalankan dan lulus:

1. Tulis/perbarui tes unit domain & widget test di `test/` (ingat nama package adalah `package:period_tracker/...`).
2. Pastikan `lib/domain/` bebas import Flutter/UI:
   ```powershell
   Select-String -Path "lib/domain/*.dart" -Pattern "package:flutter|dart:ui"
   ```
3. Pastikan `lib/features/` bebas hardcode warna di luar `AppColors`:
   ```powershell
   Select-String -Path "lib/features/**/*.dart" -Pattern "(?<!App)Colors\.[a-zA-Z]|(?<!\w)Color\(0x"
   ```
4. Jalankan analisis statis & seluruh tes:
   ```powershell
   flutter analyze
   flutter test
   ```
5. Perbarui `.agent/STATUS.md` (dan `.agent/LOGIC.md` jika logika domain berubah).
