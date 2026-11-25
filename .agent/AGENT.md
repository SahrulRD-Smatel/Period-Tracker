# AGENT.md — Peta aplikasi "Siklusku" (baca file ini PERTAMA)

Dokumen ini adalah sumber kebenaran arsitektur untuk AI model dan developer manusia.
Tujuannya: setiap fitur baru langsung nyambung ke seluruh alur aplikasi (bukan stub/demo terpisah) serta menjaga logika siklus, desain Cyra, dan privasi pengguna.

Urutan baca: `.agent/AGENT.md` (ini) → `.agent/LOGIC.md` → `.agent/FEATURE_CHECKLIST.md` → `.agent/STATUS.md`.
Dokumen lain: `docs/ARSITEKTUR.md` (konsep & privasi), `supabase/schema.sql` (skema Postgres + RLS + Realtime).

## 1. Produk
Aplikasi pelacak siklus haid **Siklusku** (package Dart: `period_tracker`, Android + iOS + Desktop/Web dari satu codebase Flutter):
prediksi haid & ovulasi, cincin siklus Cyra, kalender berwarna per fase, statistik siklus & pola gejala/mood, kunci aplikasi (Biometrik + PIN 4-angka), notifikasi lokal jam 08:00 WIB, serta **sinkronisasi 2 HP nyata** untuk pasangan (snapshot tersaring privasi, checklist perhatian romantis, dan surat cinta dua arah).
Bahasa UI: **Indonesia** · Tema visual: **Cyra Pastel + Coquette (`AppColors`)**.

## 2. Stack
Flutter · Riverpod 2.x (`Notifier`) · `supabase_flutter` (Anonymous Auth + Postgres + RLS + Realtime) · `table_calendar` · `shared_preferences` · `flutter_local_notifications` + `timezone` + `flutter_timezone` · `local_auth` · `phosphor_icons` · `flutter_animate` · `intl` (`id_ID`).

## 3. Arsitektur berlapis (`UI -> application -> domain`; `data -> domain`)
```
lib/
  domain/        LOGIKA MURNI Dart. DILARANG import flutter/riverpod/shared_preferences/supabase.
    cycle_engine.dart    prediksi haid/ovulasi, margin, confidence, status terlambat, fase per hari
    cycle_sync.dart      penghubung catatan harian (aliran haid, tes ovulasi LH/BBT) <-> PeriodLog
    home_summary.dart    ringkasan Beranda (hari ke-N, hitung mundur, status masa subur)
    day_view.dart        tampilan satu tanggal di Kalender
    stats.dart           statistik panjang siklus, keteraturan, outcome & ringkasan gejala/mood terbanyak
    app_settings.dart    setelan pengguna + pemetaan ke CycleSettings
    day_note.dart        catatan harian (aliran, ovulationPositive, gejala, mood, teks)
    love_notes.dart      model surat cinta, trigger fase, & template pesan romantis
    care_guide.dart      checklist aksi perhatian pasangan per fase siklus
    partner_models.dart  ShareFlags, PartnerSnapshot, PartnerState + JSON, buildSnapshot() (filter privasi)
    backup.dart          cadangan v1 (riwayat haid) + helper tanggal isoDate
    full_backup.dart     cadangan v3 (riwayat + catatan + setelan + surat cinta + checklist); baca v1/v2/v3
  data/          penyimpanan lokal & backend cloud
    cycle_repository.dart            riwayat haid (PrefsCycleRepository)
    local_store.dart                 SharedPreferences store: Settings, Notes, LoveNotes, CareChecklist,
                                     PartnerState, ServerConfig (default Period Tracker Supabase), AppPin
    partner_repository.dart          interface PartnerRepository + DemoPartnerRepository (offline lokal)
    supabase_partner_repository.dart SupabaseService + SupabasePartnerRepository (sync 2 HP nyata)
  application/   Riverpod state & koordinasi
    providers.dart       semua provider/notifier + Realtime stream listeners + konfirmasi ovulasi ke engine
    data_actions.dart    cadangan lengkap v3, pemulihan, wipeAllData() menyeluruh
  core/          sistem desain & layanan lintas fitur
    theme.dart           AppColors (SATU-SATUNYA sumber warna), gradien, kHeading, kSmall
    phase_style.dart     pemetaan CyclePhase -> warna/ikon/hint
    note_labels.dart     label gejala, mood, aliran haid, outcome, keteraturan
    widgets.dart         PinkCard, BowHeader, PhaseChip, IconBubble, StepperTile, SwitchRow, ActionRow
    app_scaffold.dart    SafeArea & batas lebar responsif (wajib untuk semua layar)
    app_lock.dart        AppLockService + AppLockOverlay (cold start + resume + PIN 4-angka fallback)
    dialogs.dart         confirmDialog adaptif
    formatters.dart      format tanggal id_ID
  features/      UI saja; baca & ubah state hanya via Riverpod provider
    onboarding/  4 langkah awal
    shell/       AppShell + dock navigasi gelap melayang 5 tab
    home/        HomeScreen Cyra (header, week strip, CycleRing, 4 aksi bulat, _CardRail) + surat cinta
    calendar/    CalendarScreen + bottom sheet detail, atur haid mulai/selesai/reset & tes ovulasi
    log/         LogScreen (aliran <-> auto PeriodLog, tes ovulasi LH/BBT, gejala, mood, catatan)
    stats/       StatsScreen (metrik, diagram batang, outcome, pola gejala/mood, riwayat)
    partner/     PartnerScreen + ServerSetupSheet (Setup 2 HP Supabase) + CareChecklist + WriteLoveNote
    settings/    SettingsScreen (siklus, pengingat + uji notifikasi, AppLock + PIN, cadangan v3, tentang)
  notifications/ scheduler.dart (notifikasi lokal jam 08:00 WIB + fallback inexact alarm + cek platform)
  app.dart       MensApp (cold-start lock, lifecycle sync, auto pushSnapshot & auto reschedule notifikasi)
  main.dart      boot Intl, NotificationScheduler, SharedPreferences, & SupabaseService.connect()
supabase/
  schema.sql     skema Postgres lengkap + RLS + triggers anti-tampering + RPC accept_invite + Realtime
test/            tes unit domain, integrasi provider/widget, safe area, & fitur romantis
```

## 4. Alur data terintegrasi
```
LogScreen / Calendar / Home
  ├─► periodLogsProvider ──┐
  └─► notesProvider ───────┼─► cycle_sync.latestConfirmedOvulation() ─► predictionProvider
settingsProvider ──────────┘                                                │
                                 ┌──────────────────────────────────────────┼───────────────┐
                                 ▼                                          ▼               ▼
                        homeSummaryProvider ──► HomeScreen & AutoPush   CalendarScreen   Notifikasi 08:00
                                 │                  (Supabase 2 HP)
                                 └─► PartnerSnapshot (disaring buildSnapshot() sesuai ShareFlags)
```
Tidak boleh ada fitur baru yang berhenti di memori widget (`State`) kalau seharusnya bertahan antar-tab/restart, dan tidak boleh ada layar yang memanggil `SharedPreferences` atau `Supabase` langsung tanpa melewati repository + provider.

## 5. Aturan WAJIB (invariants)
1. **Tanggal** selalu dinormalisasi dengan `dateOnly()` (UTC, tanpa jam). Jangan bandingkan `DateTime.now()` mentah.
2. **Prediksi dijangkarkan ke hari pertama haid AKTUAL terakhir**, bukan jadwal lama. Lihat `.agent/LOGIC.md`.
3. Panjang siklus = **median** 6 siklus terakhir; ovulasi dihitung **mundur** dari haid berikutnya (atau pakai `confirmedOvulation`).
4. Saat haid **terlambat & belum dicatat**, fase = `delayed`; masa subur & prediksi masa depan disembunyikan.
5. **Logika di `lib/domain/` dilarang import Flutter/Riverpod/Supabase/SharedPreferences**.
6. **Warna**: fase hanya dari `phaseStyle()`, warna lain hanya dari `AppColors`. Tidak ada hex atau `Colors.*` di `lib/features/`.
7. **Semua layar wajib memakai `AppScaffold`**. Hindari `Row` berisi `Text` tanpa `Expanded` / `overflow` agar bebas *RenderFlex overflow* di layar sempit (`390–440 pt`).
8. **Teks UI berbahasa Indonesia**, nada hangat, empatik, bukan diagnosis medis.
9. **Privasi**: gejala, mood, dan catatan teks **tidak pernah** dikirim ke server atau dibagikan ke pasangan; hanya `PartnerSnapshot` tersaring `buildSnapshot()`, `love_notes`, dan `care_progress` yang diizinkan oleh RLS.
10. **Penyimpanan & cadangan**: state baru yang dimiliki pengguna wajib masuk `Repository`, `full_backup.dart` (naikkan versi cadangan dengan tetap kompatibel versi lama), dan `wipeAllData()`.
11. **Kejujuran fitur**: fitur platform-spesifik (mis. notifikasi jadwal di Windows/Web) harus memberi status jujur di UI, jangan menipu seolah aktif.

## 6. Perintah Verifikasi
```bash
flutter pub get
flutter analyze     # wajib: No issues found!
flutter test        # wajib: 100% hijau
```

## 7. Definition of Done
Lihat `.agent/FEATURE_CHECKLIST.md` dan workspace skill `.agents/skills/siklusku-feature/SKILL.md`.
