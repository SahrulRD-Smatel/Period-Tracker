# STATUS.md — Posisi proyek (perbarui setiap selesai fitur). Versi 0.2.0

## Sudah ada (UI lengkap, Android + iOS dari satu codebase)
- **Mesin siklus** murni Dart + tes: prediksi haid/ovulasi/masa subur, margin & keyakinan, status terlambat, fase per hari, klasifikasi siklus, ovulasi terkonfirmasi.
- **Onboarding** 4 langkah (sambutan, panjang siklus & lama haid, haid terakhir, ringkasan).
- **Beranda**: cincin siklus berwarna, "Hari ke-N", hitung mundur haid, kartu masa subur, saran saat terlambat, catat haid (hari ini / pilih tanggal / selesai), kartu catatan hari ini.
- **Kalender**: warna per fase (tercatat vs prediksi), penanda catatan, detail hari (bottom sheet), tandai/hapus haid, catat gejala.
- **Catat harian**: aliran haid, gejala, suasana hati, catatan teks (hanya di perangkat).
- **Statistik**: rata-rata, rentang, lama haid, keteraturan, diagram batang panjang siklus, tepat waktu/cepat/terlambat, riwayat.
- **Pasangan (MODE DEMO, tanpa server)**: buat/terima kode, atur data dibagikan, pratinjau "tampilan di HP pasangan", tampilan pelihat + saran dukungan, cabut/putus.
- **Setelan**: panjang siklus/haid/luteal (memengaruhi engine), preferensi pengingat (tersimpan), cadangan (salin) / pulihkan (tempel) / hapus semua data, penjelasan cara kerja prediksi.
- Tema putih + pink coquette; `AppScaffold` (SafeArea, Dynamic Island); widget adaptif iOS/Android.
- Tes: engine, backup v1/v2, home summary, day view, stats, partner models + demo repo, settings/notes, layar lintas perangkat, widget flow.

## Belum ada / belum berfungsi (UI-nya jujur menandai ini)
1. **Notifikasi**: pilihan pengingat tersimpan tetapi belum ada pengiriman.
2. **Kunci aplikasi**: saklar sengaja nonaktif ("Segera hadir").
3. **Pasangan nyata**: kini DemoPartnerRepository (di memori, hilang saat app ditutup, tidak ada sinkronisasi antar HP). Perlu Supabase + push.
4. Penyimpanan masih SharedPreferences (cukup untuk MVP); rencana Drift.
5. Cadangan via salin/tempel teks; belum berbagi berkas.
6. Satu peran per perangkat (pemilik ATAU pelihat).
7. Input tes LH/BBT, widget Home/Lock Screen, ekspor PDF untuk dokter.

## Batasan yang diketahui
- "Hari ini" dihitung ulang saat app kembali ke foreground, bukan tepat tengah malam saat app terbuka.
- Tidak ada konfirmasi bila haid baru dicatat <15 hari dari haid sebelumnya (selisih itu diabaikan dari rata-rata).
- Proyek Flutter telah di-scaffold (`flutter create`), dependensi terpasang, `flutter analyze` bersih (0 issues), dan seluruh tes (41/41) hijau. Siap dijalankan di Android/iOS/Windows.
