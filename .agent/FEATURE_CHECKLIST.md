# FEATURE_CHECKLIST.md — Cara menambah fitur tanpa merusak aplikasi

## A. Sebelum menulis kode
- [ ] Baca `AGENT.md` §5 (aturan wajib) dan `LOGIC.md`.
- [ ] Tentukan lapisan: logika baru → `domain/`; penyimpanan → `data/`; state → `application/providers.dart`; tampilan → `features/<nama>/`.
- [ ] Apakah menyentuh data sensitif / pasangan / jaringan? Bila ya, lakukan tinjauan privasi (§D).

## B. Pola yang dipakai
- **Logika baru**: fungsi/kelas murni di `lib/domain/`, tanpa import Flutter. Tulis tes dulu.
- **State baru**: `Provider` / `NotifierProvider` di `providers.dart`; turunan dihitung dari provider yang ada (jangan duplikasi prediksi).
- **Layar baru**: folder `features/<nama>/<nama>_screen.dart`, `ConsumerWidget`, daftarkan di `shell/app_shell.dart`. Gunakan `PinkCard`, `BowHeader`, `AppColors`, `kHeading`, `kSmall`.
- **Fase/warna baru**: tambah di `CyclePhase` → perbarui `phaseStyle()`, legenda kalender, tes.
- **Penyimpanan baru**: implementasi `CycleRepository` baru (mis. Drift); jangan akses `SharedPreferences` dari UI. Ubah format data → naikkan `backupVersion` dan sediakan migrasi.

## C. Daftar periksa selesai (Definition of Done)
- [ ] `flutter analyze` bersih, `flutter test` hijau.
- [ ] Tes unit untuk logika baru; widget test bila menambah layar penting.
- [ ] Tampil benar di layar 402–440 pt lebar, iPhone ber-Dynamic Island, Android gesture nav (pakai `AppScaffold`).
- [ ] Tidak ada warna/hex baru di luar `AppColors`; tidak ada teks Inggris di UI.
- [ ] `.agent/STATUS.md` diperbarui; `LOGIC.md`/`AGENT.md` diperbarui bila perilaku/arsitektur berubah.

## D. Tinjauan privasi (wajib untuk fitur yang menyentuh data haid)
- [ ] Data apa yang keluar dari perangkat? Minimalkan; kirim *snapshot*, bukan riwayat/gejala.
- [ ] Ada persetujuan eksplisit pemilik data dan tombol cabut/hapus?
- [ ] Notifikasi/Live Activity/widget: teks netral, opt-in (layar kunci bisa dilihat orang lain).
- [ ] Tidak ada SDK analytics/iklan; tidak ada data haid di log.
- [ ] Ada jalur ekspor & hapus data (UU PDP).

## E. Rencana fitur berikutnya & tempatnya
| Fitur | Tempat | Catatan |
|---|---|---|
| Notifikasi lokal (✅ Selesai) | `lib/notifications/scheduler.dart` | Jadwal dihitung dari `CyclePrediction` + `AppSettings` (remind*, discreetNotifications). Terintegrasi dengan lifecycle app. |
| Kunci aplikasi (✅ Selesai) | `lib/core/app_lock.dart` + `local_auth` | Saklar `appLock` aktif. `NSFaceIDUsageDescription` (iOS) & `FlutterFragmentActivity` (Android). |
| Pasangan nyata (Supabase) | `data/supabase_partner_repository.dart` (rancangan di `docs/future/`) | Implementasi `PartnerRepository`; ganti `partnerRepositoryProvider`; SQL+RLS di `docs/ARSITEKTUR.md` §5; push FCM/APNs berteks netral. Banner demo hilang otomatis (cek `is DemoPartnerRepository`). |
| Pindah ke Drift | `data/drift_*_repository.dart` | Implementasi `CycleRepository`/`NotesRepository`; migrasi dari prefs lewat `importFullBackup`. |
| Cadangan berkas/Share | `features/settings/` + `share_plus` | Kini lewat salin/tempel teks. |
| Input tes LH/BBT | param `confirmedOvulation` pada `predict()` | Tambah UI + simpan per siklus. |
| Widget Home/Lock Screen | `home_widget` | Opt-in, teks netral. |
| Dua peran sekaligus (saling berbagi) | `PartnerState` | Kini satu peran per perangkat. |

## F. Template prompt untuk AI
> Baca `.agent/AGENT.md`, `.agent/LOGIC.md`, `.agent/FEATURE_CHECKLIST.md`. Tambahkan fitur: <deskripsi>.
> Patuhi aturan §5 AGENT.md. Letakkan logika di `domain/` dengan tes, UI di `features/`, pakai tema `AppColors`.
> Jalankan checklist §C dan perbarui `.agent/STATUS.md`.
