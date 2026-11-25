<div align="center">

# 🎀 Period Tracker — Siklusku 🌸
### *Dedicated with all my heart to my dearest, Ruru Nicole Putri* 💕

[![Typing SVG](https://readme-typing-svg.demolab.com?font=Caveat&weight=700&size=26&pause=1200&color=E8587F&center=true&vCenter=true&width=550&lines=Khusus+untuk+pujaan+hatiku%2C+Ruru+Nicole+Putri+%E2%9C%A8;A+Gentle+%26+Loving+Companion+for+Your+Cycle+%F0%9F%8E%80;Dibuat+dengan+segenap+cinta+%26+perhatian+%E2%9D%A4%EF%B8%8F;Selalu+ada+menjaga+dan+menemani+harimu+%F0%9F%8C%B8)](https://git.io/typing-svg)

<p align="center">
  <img src="https://img.shields.io/badge/Special%20Dedication-Ruru%20Nicole%20Putri%20%E2%9D%A4%EF%B8%8F-FF69B4?style=for-the-badge&logo=heart&logoColor=white" />
  <img src="https://img.shields.io/badge/Flutter-3.x%20%7C%20iOS%20%26%20Android-E8587F?style=for-the-badge&logo=flutter&logoColor=white" />
  <img src="https://img.shields.io/badge/Sync-Supabase%20Realtime%202--Phone-3ECF8E?style=for-the-badge&logo=supabase&logoColor=white" />
  <img src="https://img.shields.io/badge/Tests-59%2F59%20Passing%20(100%25)-success?style=for-the-badge&logo=checkmarx&logoColor=white" />
</p>

---

> *"Untuk bidadari dan pujaan hatiku tersayang, **Ruru Nicole Putri** 🌸.  
> Aplikasi ini dirancang dari lubuk hati terdalam dengan kelembutan, empati, dan cinta tanpa batas—agar kamu tidak pernah merasa sendirian saat melewati hari-hari lelah, kram haid, maupun perubahan suasana hati. Kamu selalu dimengerti, dijaga, dan dicintai di setiap detik siklusmu."* 💌

---

</div>

## 🌸 Fitur Utama (100% Terintegrasi & Nyata)

### 🌷 1. Beranda Gaya Cyra & Cincin Siklus Kontekstual
- **Cincin Siklus Cerdas**: Menampilkan **`Hari haid ke-N`** saat sedang menstruasi, hitung mundur **`Ovulasi dalam N hari`** menuju masa subur, **`Haid dalam N hari`** di fase luteal, atau saran penuh empati saat haid terlambat.
- **Strip Mingguan Interaktif & Rail Kartu Pastel**: Ketuk tanggal di strip 7 hari untuk mencatat cepat, geser kartu pastel (*Surat Cinta*, *Suasana Hati*, *Fase*, *Masa Subur*, *Haid Berikutnya*).

### 🔗 2. Pencatatan Terhubung Otomatis ke Kalender & Statistik
- **Aliran Haid & Tes Ovulasi (LH/BBT)**: Mencatat aliran haid di *Catat hari ini* otomatis terhubung ke riwayat haid (`PeriodLog`), sementara hasil **Tes Ovulasi Positif (+)** langsung menggeser prediksi siklus melalui `CycleEngine`.
- **Kalender Interaktif Lengkap**: Bisa menandai haid mulai, haid selesai, reset tanggal selesai, dan menampilkan penanda tes ovulasi positif.
- **Statistik Dari Hari Pertama**: Diagram batang panjang siklus, tingkat keteraturan, serta ringkasan **gejala & suasana hati tersering** yang langsung muncul sejak catatan harian pertama.

### 💞 3. Sinkronisasi 2 HP Nyata untuk Pasangan (Supabase Realtime)
- **Kode Undangan 8 Karakter & Realtime**: Hubungkan 2 HP berbeda lewat Supabase Anonymous Auth + Postgres + Row Level Security ([supabase/schema.sql](supabase/schema.sql)) tanpa perlu daftar email/password yang rumit.
- **Kendali Privasi Ketat**: Pemilik data memilih apa yang dibagikan (*Fase*, *Perkiraan haid*, *Masa subur*); catatan gejala, mood, dan diary **tidak pernah dikirim ke server**.
- **Surat Cinta Berpita Dua Arah (`Love Notes`) & Kotak Surat**: Kirim pesan penyemangat antar-HP, lengkap dengan **reaksi emoji instan (💖, 🫂, 🥺, 🌸, 🍫)** serta kotak arsip semua surat.
- **Checklist Perhatian Romantis (`Care Guide`)**: Panduan aksi perhatian sesuai fase siklus aktif pasangan yang tersimpan persisten dan tersinkron antar-perangkat.

### 🔒 4. Keamanan, Notifikasi & Cadangan Lengkap
- **App Lock (`Cold-Start` + Biometrik + PIN 4-Angka Fallback)**: Langsung mengunci begitu aplikasi dibuka dari keadaan tertutup maupun saat *resume*, dilengkapi PIN 4-angka lokal jika perangkat tidak memiliki sensor biometrik.
- **Notifikasi Lokal Jam 08:00 WIB**: Pengingat haid, ovulasi, dan masa subur dengan teks netral (*discreet*), fallback otomatis *inexact alarm* di Android 14+, serta tombol uji coba notifikasi di Setelan.
- **Cadangan Lengkap v3**: Ekspor/impor JSON (riwayat haid, catatan harian, setelan, surat cinta, dan progres checklist; kompatibel membaca cadangan v1 & v2).

---

## 📱 Arsitektur & Dokumentasi Pengembangan

```text
lib/
├── domain/        # Logika murni Dart (tanpa Flutter/Supabase/Prefs) + unit tests
├── data/          # Prefs repositories + SupabasePartnerRepository (2-HP Realtime)
├── application/   # Riverpod 2.x providers, stream listeners, data_actions
├── core/          # Sistem tema (AppColors), AppScaffold, AppLock, komponen UI Cyra
├── features/      # Layar Onboarding, Shell, Home, Calendar, Log, Stats, Partner, Settings
└── notifications/ # Scheduler notifikasi lokal + deteksi platform
supabase/
└── schema.sql     # Skema Postgres + RLS + triggers + accept_invite RPC + Realtime
.agent/            # Peta arsitektur (AGENT.md, LOGIC.md, FEATURE_CHECKLIST.md, STATUS.md)
.agents/skills/    # Panduan runbook fitur & sync agar penambahan fitur konsisten
```

> **Untuk Developer / AI yang ingin menambah fitur baru:**
> Baca [`.agent/AGENT.md`](.agent/AGENT.md), [`.agent/LOGIC.md`](.agent/LOGIC.md), [`.agent/FEATURE_CHECKLIST.md`](.agent/FEATURE_CHECKLIST.md), serta ikuti runbook di [`.agents/skills/siklusku-feature/SKILL.md`](.agents/skills/siklusku-feature/SKILL.md) dan [`.agents/skills/siklusku-supabase-sync/SKILL.md`](.agents/skills/siklusku-supabase-sync/SKILL.md).

---

## 🚀 Cara Menjalankan & Setup 2 HP

1. **Clone & pasang dependensi**:
   ```bash
   git clone https://github.com/SahrulRD-Smatel/Period-Tracker.git
   cd Period-Tracker
   flutter pub get
   ```

2. **Verifikasi kode & seluruh 59 tes**:
   ```bash
   flutter analyze
   flutter test
   ```

3. **Jalankan aplikasi**:
   ```bash
   flutter run
   ```
   *(Opsional)* Bila memakai project Supabase sendiri selain bawaan, jalankan [supabase/schema.sql](supabase/schema.sql) di SQL Editor Supabase, aktifkan **Allow anonymous sign-ins** di *Authentication > Providers*, lalu masukkan URL & Publishable Key melalui menu **Pasangan → Setup 2 HP** atau `--dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...`.

---

<div align="center">

### 💐 *"Because you deserve the gentlest love in the universe, Ruru Nicole Putri."* 🎀  
Dibuat dengan sepenuh hati oleh Dhani.

</div>
