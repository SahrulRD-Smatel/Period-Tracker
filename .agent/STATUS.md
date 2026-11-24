# STATUS.md — Posisi proyek (perbarui setiap selesai fitur). Versi 0.3.2

## Sudah ada (UI lengkap, Android + iOS dari satu codebase)
- **Desain Kelas Dunia (Dribbble & Figma iOS Tier)** ✅ BARU:
  - **Kedalaman Visual & Permukaan Mewah**: Menggantikan desain flat lama dengan sistem pencahayaan modern (*specular highlight*, *dual-layer drop shadow*, gradien halus mutiara *blush-to-petal*, dan *micro-border* berkilau pada kartu `PinkCard`).
  - **Bilah Navigasi Kaca Mengambang (Floating Frosted-Glass Dock)**: Navigasi bawah iOS dengan `BackdropFilter` blur 18px, permukaan semi-transparan `glassWhite`, elevasi halus, serta indikator pill kapsul lembut yang adaptif.
  - **Cincin Siklus Ber-Halo (Cycle Ring Modern)**: Dilengkapi *circular track layer* berkelanjutan, busur fase dengan ujung membulat halus, penanda Hari Ini berupa manik permata bercahaya (*glowing pulse aura*), dan tipografi berbobot display (*large display numbers & tracked micro-caps*).
  - **Tipografi & Hierarki Visual iOS**: Kontras warna `AppColors.mauve` yang lebih berkelas, *tight tracking* untuk judul besar, dan kartu ringkasan metrik bernuansa *Apple Health & Fitness*.
  - **Diagram & Visualisasi Halus**: Diagram batang siklus modern dengan gradien dan rentang normal berlekuk halus (*rounded capsule*).
- **Mesin siklus** murni Dart + tes: prediksi haid/ovulasi/masa subur, margin & keyakinan, status terlambat, fase per hari, klasifikasi siklus, ovulasi terkonfirmasi.
- **Onboarding** 4 langkah dengan animasi fade/scale/slide per elemen — Phosphor icons modern, transisi halus.
- **Beranda**: cincin siklus berwarna, "Hari ke-N", hitung mundur haid, kartu masa subur, saran saat terlambat, catat haid (hari ini / pilih tanggal / selesai), kartu catatan hari ini — semua kartu masuk dengan animasi staggered yang elegan.
- **Surat Cinta Berpita (Love Notes) 💌**: amplop surat cinta di Beranda dengan animasi lembut, bisa dibuka menjadi modal surat romantis coquette, dilengkapi bar reaksi cinta instan (💖, 🫂, 🥺, 🌸, 🍫) yang langsung tersinkronisasi.
- **Checklist Perhatian Romantis (Care Guide) 🎀**: di tab Pasangan, panduan aksi perhatian nyata yang disesuaikan dengan fase siklus aktif pasangan (haid, PMS, masa subur, ovulasi, telat), lengkap dengan checklist interaktif dan progress bar kepedulian pasangan.
- **Tulis Surat Cinta ✍️**: pasangan dapat menulis surat penyemangat sendiri atau memilih dari template romantis siap pakai untuk mendampingi saat haid/PMS.
- **Kalender**: warna per fase (tercatat vs prediksi), penanda catatan, detail hari (bottom sheet), tandai/hapus haid, catat gejala.
- **Catat harian**: aliran haid, gejala, suasana hati, catatan teks (hanya di perangkat).
- **Statistik**: rata-rata, rentang, lama haid, keteraturan, diagram batang panjang siklus, tepat waktu/cepat/terlambat, riwayat — dengan animasi staggered.
- **Pasangan (MODE DEMO, tanpa server)**: buat/terima kode, atur data dibagikan, pratinjau "tampilan di HP pasangan", tampilan pelihat + saran dukungan & checklist perhatian, cabut/putus.
- **Setelan**: panjang siklus/haid/luteal, preferensi pengingat, cadangan/pulihkan/hapus data, penjelasan prediksi — dengan animasi list staggered.
- **Notifikasi lokal** ✅ LENGKAP: `flutter_local_notifications ^18.0.0` + `timezone ^0.9.4` + `flutter_timezone ^5.1.1`.
  - Pengingat haid akan datang (N hari sebelum).
  - Pengingat tepat di Hari-H haid diperkirakan (jam 08:00 pagi).
  - Pengingat masa subur akan datang.
  - Pengingat tepat di Hari-H puncak ovulasi (jam 08:00 pagi).
  - Teks netral bila `discreetNotifications = true`.
- **Kunci aplikasi**: `local_auth ^2.3.0`. Face ID / sidik jari / PIN. Saklar aktif; autentikasi biometrik dicek sebelum mengaktifkan; `AppLockOverlay` muncul saat aplikasi resume. `FlutterFragmentActivity` di Android + `NSFaceIDUsageDescription` di iOS.
- **Phosphor Icons**: seluruh `Icons.*` Material dirombak memakai `PhosphorIconsFill.*` / `PhosphorIconsRegular.*` dari library `phosphor_icons ^3.0.1`.
- **Animasi `flutter_animate ^4.5.2`**: semua layar memakai fade/slide/scale yang halus, modern, dan ramah pengguna (bukan kaku).
- Tema putih dominan + pink coquette (`AppColors.blush`, `AppColors.petal`, `AppColors.rose`); `AppScaffold` (SafeArea, Dynamic Island); widget adaptif iOS/Android.
- **Tes**: 49 dari 49 tes lulus 100% (unit, domain, area aman, widget smoke test, & widget fitur romantis). `flutter analyze` 0 issues (bersih).

## Belum ada / rencana berikutnya
1. **Pasangan nyata**: kini DemoPartnerRepository (di memori, hilang saat app ditutup, tidak ada sinkronisasi antar HP). Perlu Supabase + push FCM/APNs.
2. Penyimpanan masih SharedPreferences (cukup untuk MVP); rencana Drift.
3. Cadangan via salin/tempel teks; belum berbagi berkas via `share_plus`.
4. Satu peran per perangkat (pemilik ATAU pelihat).
5. Input tes LH/BBT, widget Home/Lock Screen, ekspor PDF untuk dokter.

## Validasi Kualitas Terkini
- `flutter analyze`: **No issues found! (0 warnings, 0 errors)**
- `flutter test`: **49/49 lulus (100%)**
- Arsitektur: Domain murni Dart tanpa import Flutter/UI.
- Palet warna: 100% tersentralisasi di `AppColors` tanpa hardcode warna di fitur.
- Audit & Bug Fixes:
  - Sinkronisasi notifikasi real-time & waktu lokal 08:00 WIB terproteksi error handling di lingkungan test.
  - Data wipe komprehensif (membersihkan period logs, notes, love notes, partner status, dan membatalkan semua notifikasi).
  - Penyelarasan widget test & UI teruji menyeluruh.
- Standar visual: Modern iOS / Dribbble / Figma Mobile Design


## Redesain gaya Cyra (v0.4.0, belum dijalankan di perangkat)
- Token `AppColors` diganti ke palet Cyra (nama token tetap): pink-koral, pastel biru/lilac/madu, teks hampir hitam; tambah `track` & `dock`.
- `AppScaffold`: latar gradien pink -> putih. `PinkCard`: radius 30, tanpa border.
- `CycleRing`: jalur abu + busur gradien + knob putih (gaya Cyra). Beranda: header sapaan, week strip (ketuk = catatan hari itu), teks tengah ring (Ovulasi dalam / Haid dalam / Haid terlambat), aksi bulat.
- Navigasi: dock hitam melayang, 5 tombol bulat (tooltip = nama tab). Tes disesuaikan (`find.byTooltip`).
- Belum diubah: struktur Kalender, Statistik, Pasangan, Setelan, Onboarding (hanya mewarisi token baru).
- (lanjutan) Beranda: kartu vertikal diganti rail pastel yang bisa digeser (surat cinta, suasana hati/catatan, fase, masa subur, haid berikutnya); saran keterlambatan tetap kartu penuh di atas rail.
- Kalender: sel tanggal persegi membulat, hari terpilih gradien pink, tombol bulan putih membulat. Statistik: tile ringkasan pastel, diagram dengan pita abu. `BowHeader` kini header gaya Cyra (tanpa pita).
