# AGENT.md — Peta aplikasi "Siklusku" (baca file ini PERTAMA)

Dokumen ini untuk AI model dan developer manusia. Tujuannya: setiap fitur baru tetap
konsisten dengan arsitektur, logika siklus, tema, dan aturan privasi yang sudah ada.

Urutan baca: `AGENT.md` (ini) → `LOGIC.md` (aturan siklus) → `FEATURE_CHECKLIST.md` (cara menambah fitur) → `STATUS.md` (apa yang sudah/belum ada).
Dokumen lain: `docs/ARSITEKTUR.md` (stack, skema Supabase + RLS, privasi, roadmap).

## 1. Produk
Aplikasi mobile Flutter (Android + iOS, satu codebase) untuk melacak siklus haid:
prediksi haid & ovulasi, kalender berwarna per fase, hitung mundur, dan (rencana) berbagi
data ringkas ke pasangan dengan persetujuan pemilik data. Bahasa UI: **Indonesia**.
Tema default: **putih + pink coquette**.

## 2. Stack
Flutter · Riverpod 2.x (`Notifier`) · table_calendar · shared_preferences (sementara) ·
intl (id_ID). Rencana: Drift (SQLite), Supabase (akun + pasangan), notifikasi lokal + FCM/APNs.

## 3. Arsitektur berlapis (arah dependensi: UI → application → domain; data → domain)
```
lib/
  domain/        LOGIKA MURNI Dart. DILARANG import flutter/riverpod/shared_preferences.
    cycle_engine.dart   model + prediksi + status terlambat + fase per hari + klasifikasi siklus
    home_summary.dart   ringkasan Beranda (hari ke-N, hitung mundur, status subur)
    day_view.dart       apa yang ditampilkan kalender untuk satu tanggal
    stats.dart          statistik riwayat (rata-rata, rentang, keteraturan, tepat waktu/cepat/telat)
    app_settings.dart   setelan pengguna + pemetaan ke CycleSettings
    day_note.dart       catatan harian (aliran, gejala, mood, teks)
    partner_models.dart ShareFlags, PartnerSnapshot, PartnerState, buildSnapshot() (penyaring privasi)
    backup.dart         v1 (riwayat haid) + helper isoDate/periodToJson
    full_backup.dart    v2 (riwayat + catatan + setelan), membaca v1 juga
  data/          penyimpanan & backend
    cycle_repository.dart   riwayat haid (interface + SharedPreferences)
    local_store.dart        setelan & catatan harian (interface + SharedPreferences)
    partner_repository.dart interface PartnerRepository + DemoPartnerRepository (tanpa server)
  application/   Riverpod
    providers.dart      settings, engine, today, periodLogs, prediction, homeSummary, stats, notes, partner
    data_actions.dart   cadangan / pulihkan / hapus semua
  core/          theme.dart (AppColors, kHeading, kSmall), phase_style.dart, note_labels.dart,
                 widgets.dart (PinkCard, BowHeader, PhaseChip, StepperTile, SwitchRow, ...),
                 dialogs.dart, formatters.dart, app_scaffold.dart
  features/      UI saja; baca state lewat provider
    onboarding/ home/ calendar/ log/ stats/ partner/ settings/ shell/
  app.dart       MaterialApp + gerbang onboarding;  main.dart
test/            satu berkas tes per unit domain + widget_test.dart (alur UI)
docs/            ARSITEKTUR.md, future/partner_repository.dart.txt (rancangan Supabase, belum aktif)
```

## 4. Alur data
```
PeriodLog (tersimpan) ──► periodLogsProvider ──► predictionProvider (CycleEngine.predict)
                                                   ├─► homeSummaryProvider ──► HomeScreen
                                                   └─► dayViewFor(...) ──────► CalendarScreen
todayProvider (tanggal hari ini, di-invalidate saat app resume) ikut menjadi input keduanya.
```
Satu-satunya jalan mengubah data: `PeriodLogsNotifier` (addStart / setEnd / remove) → repository.save.

## 5. Aturan WAJIB (invariants)
1. **Tanggal** selalu dinormalisasi dengan `dateOnly()` (UTC, tanpa jam). Jangan bandingkan `DateTime.now()` langsung.
2. **Prediksi dijangkarkan ke hari pertama haid AKTUAL terakhir**, bukan ke jadwal lama. Lihat `LOGIC.md`.
3. Panjang siklus = **median** 6 siklus terakhir; satu siklus telat tidak boleh langsung menggeser rata-rata.
4. Ovulasi dihitung **mundur dari haid berikutnya** (fase luteal), bukan "hari ke-14".
5. Saat haid **terlambat & belum dicatat**: fase hari-hari itu = `delayed`; ovulasi/masa subur & masa depan **tidak ditampilkan** sampai haid dicatat.
6. Logika di `domain/` tidak boleh bergantung pada Flutter. UI tidak boleh menghitung prediksi sendiri.
7. Warna fase **hanya** dari `phaseStyle()`. Warna lain **hanya** dari `AppColors`. Tidak ada hex di berkas fitur.
8. Setiap layar memakai `AppScaffold` (SafeArea untuk Dynamic Island/notch). Jangan hardcode tinggi status bar. Jangan lebar tetap (layar 402–440 pt).
9. Teks UI berbahasa Indonesia, nada hangat, tidak menghakimi. Pesan kesehatan: informatif, bukan diagnosis, ada anjuran ke dokter bila perlu.
10. Hindari API Flutter yang sedang berganti (component themes seperti CardTheme/DialogTheme/TabBarTheme, `withOpacity`, `MaterialStateProperty`). Gunakan padanan modern (`withValues`, `WidgetState`) atau bangun widget sendiri.
11. **Privasi**: data haid = data kesehatan sensitif. Tidak ada analytics/SDK iklan. Tidak ada log berisi data haid. Berbagi ke pasangan hanya atas persetujuan pemilik, hanya *snapshot* ringkas (bukan riwayat/gejala), dan bisa dicabut kapan saja. Notifikasi push berteks netral.
12. Perubahan logika di `domain/` **wajib** disertai tes dan pembaruan `LOGIC.md`.
13. **Apa yang boleh dilihat pasangan** hanya ditentukan oleh `buildSnapshot()` (domain). UI/repository tidak boleh menambah field ke snapshot. Gejala, mood, catatan, dan riwayat mentah **tidak pernah** masuk snapshot.
14. Penyimpanan baru selalu di balik interface repository; UI tidak membaca `SharedPreferences` langsung. Mengubah format data → naikkan versi cadangan (`full_backup.dart`) dan pertahankan pembacaan versi lama.
15. UI lintas platform: pakai widget adaptif (`Switch.adaptive`, `AlertDialog.adaptive` lewat `confirmDialog`), jangan menulis kode khusus platform di `features/`. Dialog dengan `TextField` memakai `showDialog` Material (Cupertino dialog tidak punya ancestor Material).
16. Fitur yang belum benar-benar bekerja harus **jujur di UI** (mis. saklar nonaktif + "Segera hadir", banner "Mode demo"). Jangan menampilkan kontrol yang tampak aktif tapi tidak berfungsi tanpa catatan.

## 6. Perintah
```
flutter pub get
flutter analyze
flutter test              # semua tes harus hijau sebelum selesai
flutter run               # Android / iOS
```

## 7. Definition of Done untuk fitur apa pun
Lihat `FEATURE_CHECKLIST.md`. Ringkas: tes hijau, `flutter analyze` bersih, dokumen `.agent/` yang terdampak
diperbarui, tidak melanggar aturan §5, teks Indonesia, tampil benar di layar sempit & ber-Dynamic Island.
