# STATUS.md — Posisi proyek (perbarui setiap selesai fitur). Versi 0.4.0

## Sudah ada (UI Cyra terpadu + Keterhubungan Lokal Penuh + Sync 2 HP Supabase)
- **Beranda Gaya Cyra Terpadu (`home_screen.dart` + `cycle_ring.dart`)**:
  - Sapaan personal + strip mingguan 7 hari (ketuk tanggal untuk catat hari itu).
  - Cincin siklus ber-halo dengan tengah cincin yang kontekstual (`Hari haid ke-N` saat menstruasi, `Ovulasi dalam` sebelum ovulasi, `Haid dalam` di fase luteal, `Haid terlambat` saat lewat jadwal).
  - 4 tombol aksi bulat (`Haid mulai`, `Pilih tanggal`, `Haid selesai`, `Tambah gejala`) tanpa overflow + rail kartu geser pastel (`Surat Cinta`, `Bagaimana perasaanmu?`, `Fase`, `Masa subur`, `Haid berikutnya`).
- **Keterhubungan Penuh Antar Fitur Lokal**:
  - **Aliran Haid & Tes Ovulasi ↔ Siklus/Kalender**: Mencatat aliran haid di `LogScreen` menawarkan/menandai otomatis hari pertama atau selesai haid ke `periodLogsProvider`; hasil tes ovulasi positif (+) terhubung ke `CycleEngine.predict(confirmedOvulation: ...)`.
  - **Kalender**: Bisa menandai/mereset tanggal *Haid selesai* dan menampilkan indikator tes ovulasi positif.
  - **Statistik**: Menampilkan ringkasan gejala & suasana hati tersering dari `DayNote` langsung sejak catatan pertama, serta diagram siklus & keteraturan.
  - **Checklist Perhatian & Status Pasangan Persisten**: Tersimpan permanen di `SharedPreferences` (`care_checked_v1`, `partner_state_v1`) — tidak hilang saat pindah tab atau restart.
  - **Keamanan `AppLock`**: Mengunci langsung sejak *cold start* bila aktif + PIN 4-digit fallback lokal bagi perangkat tanpa biometrik.
  - **Notifikasi Lokal Jujur & Tahan Error**: Fallback otomatis `inexactAllowWhileIdle` di Android 14+, tombol uji notifikasi di Setelan, serta deteksi dukungan platform Android/iOS vs Desktop/Web.
  - **Cadangan v3**: Menyertakan surat cinta & progres checklist perhatian, tetap kompatibel membaca cadangan v1 & v2.
- **Sinkronisasi 2 HP Nyata (Supabase)**:
  - Paket `supabase_flutter` aktif bersama `supabase/schema.sql` (tabel `invites`, `partner_links`, `cycle_snapshots`, `love_notes`, `care_progress` dengan RLS & Realtime + RPC atomik `accept_invite`).
  - Pengaturan langsung di tab *Pasangan* (*Setup 2 HP*) atau via `--dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...`, lengkap dengan penyalin script SQL 1-klik.
  - Mode Lokal/Demo tetap berjalan offline bila server belum dikonfigurasi.
- **Nama package Dart**: `period_tracker` di `pubspec.yaml`.

## Rencana pengembangan lanjutan (opsional)
1. Push notification jarak jauh (FCM/APNs Edge Function) saat aplikasi pasangan sedang tertutup total.
2. Migrasi penyimpanan lokal ke Drift (SQLite terenkripsi) & ekspor berkas via `share_plus` / PDF dokter.
3. Widget Home Screen / Lock Screen netral (`home_widget`).
