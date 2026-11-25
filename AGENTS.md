# AGENTS.md
Aplikasi Flutter **Siklusku / Period Tracker** (`name: period_tracker`).
**Baca `.agent/AGENT.md` terlebih dahulu**, lalu `.agent/LOGIC.md`, `.agent/FEATURE_CHECKLIST.md`, dan `.agent/STATUS.md`.
Saat menambah atau mengubah fitur, aktifkan workspace skill di `.agents/skills/siklusku-feature/SKILL.md` (dan `.agents/skills/siklusku-supabase-sync/SKILL.md` jika menyentuh sinkronisasi pasangan/Supabase).
Ringkas: logika murni di `lib/domain/` (tanpa import Flutter), warna hanya dari `AppColors`, semua fitur harus terhubung end-to-end (bukan stub/demo terputus), UI berbahasa Indonesia, privasi data haid dijaga ketat, wajib jalankan `flutter analyze` + `flutter test` sebelum selesai.
