# AGENTS.md
Aplikasi Flutter "Siklusku" (pelacak siklus haid). **Baca `.agent/AGENT.md` terlebih dahulu**, lalu
`.agent/LOGIC.md` dan `.agent/FEATURE_CHECKLIST.md`. Status terkini ada di `.agent/STATUS.md`.
Ringkas: logika murni di `lib/domain` (jangan import Flutter), warna hanya dari `AppColors`,
UI berbahasa Indonesia, data haid sensitif (privasi dulu), jalankan `flutter analyze` + `flutter test`.
(Bila memakai alat yang membaca `CLAUDE.md` / `GEMINI.md`, salin isi berkas ini ke sana.)
