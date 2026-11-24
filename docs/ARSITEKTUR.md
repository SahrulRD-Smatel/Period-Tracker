> Catatan: kontrak `PartnerRepository` + `DemoPartnerRepository` ada di `lib/data/partner_repository.dart`. Implementasi Supabase (belum aktif karena butuh `supabase_flutter`) ada di `docs/future/partner_repository.dart.txt`; lihat langkah aktivasinya di berkas itu.
> Panduan untuk AI/developer ada di `.agent/` dan `AGENTS.md`.

# Aplikasi Pelacak Siklus Haid (Flutter) — Logika, Arsitektur, Fitur Pasangan

## 1. Koreksi pemahaman siklus (penting sebelum coding)

| Yang kamu tulis | Yang lebih tepat |
|---|---|
| Siklus 28 hari | 28 hanyalah **rata-rata**. Rentang normal dewasa **21–35 hari**, remaja bisa sampai 45. Jadi 28 hanya nilai awal (default), bukan aturan. |
| "21" | Batas **bawah** siklus normal (21 hari), bukan "haid pertama". Lama haid sendiri umumnya 2–7 hari. |
| Telat 1 minggu → bulan depan maju 1 minggu | Benar **jika dijangkarkan ke tanggal haid aktual**: hitung dari hari pertama haid yang *benar-benar terjadi*. Tapi jangan dijadikan rumus tetap, kadang siklus berikutnya kembali normal. Biarkan data riwayat yang belajar. |
| Ovulasi | Bukan "hari ke-14". Ovulasi terjadi sekitar **14 hari SEBELUM haid berikutnya** (fase luteal relatif stabil 12–16 hari). Siklus 21 hari → ovulasi ± hari ke-8; siklus 35 hari → ± hari ke-22. |
| Haid telat | Penyebab umum: stres, berat badan, tidur, PCOS, tiroid, KB hormonal, menyusui, **kehamilan**. Karena itu aplikasi tidak boleh sekadar menggeser tanggal, tapi juga memberi saran (tes kehamilan, konsultasi). |

Perkiraan dari kalender adalah **estimasi**, bukan alat kontrasepsi dan bukan diagnosis. Cantumkan disclaimer ini di aplikasi.

## 2. Rumus inti (sudah diimplementasi di `lib/domain/cycle_engine.dart`)

```
panjang_siklus   = median 6 siklus terakhir (default 28 bila data < 3 siklus)
haid_berikutnya  = hari_pertama_haid_TERAKHIR + panjang_siklus
ovulasi          = haid_berikutnya − 14
jendela_subur    = ovulasi − 5 … ovulasi + 1
margin           = max(2, ceil(simpangan_baku)), maks 7 hari  (data < 3 siklus: 3 hari)
rentang_haid     = haid_berikutnya ± margin
```

Alur saat pengguna mencatat haid baru:
1. Simpan `PeriodLog(start, end)`.
2. Hitung panjang siklus yang baru selesai → `classifyCycle()` → **lebih cepat / tepat waktu / terlambat** (untuk statistik).
3. Jalankan `predict()` ulang → semua tanggal bergeser mengikuti tanggal aktual.
4. Jadwalkan ulang notifikasi, lalu `pushSnapshot()` ke pasangan (bila tersambung).

Alur saat haid terlambat (belum dicatat) → `assessLateness()`:

| Status | Kondisi | Tindakan UI |
|---|---|---|
| `none` | belum lewat tanggal prediksi | normal |
| `withinMargin` | lewat prediksi, masih dalam margin | "Masih dalam rentang wajar" |
| `late` | lewat margin | tanya: ada stres/perubahan? ingatkan tes kehamilan bila relevan |
| `veryLate` | ≥ 7 hari dari prediksi | sarankan tes kehamilan & cek penyebab |
| `seeDoctor` | ≥ 90 hari sejak haid terakhir | sarankan periksa ke dokter |

Saat terlambat, kalender menandai `delayed` dan **tidak menampilkan ovulasi/haid masa depan** sampai haid benar-benar dicatat (karena prediksi lama sudah tidak valid).

Meningkatkan akurasi (opsional, fase 2): input tes LH, suhu basal tubuh (BBT), lendir serviks → `confirmedOvulation` pada `predict()`.

## 3. Tech stack

```bash
flutter pub add flutter_riverpod go_router intl
flutter pub add drift sqlite3_flutter_libs path_provider path   # database lokal (offline-first)
flutter pub add dev:drift_dev dev:build_runner
flutter pub add table_calendar fl_chart                         # kalender & grafik riwayat
flutter pub add flutter_local_notifications timezone flutter_timezone
flutter pub add local_auth flutter_secure_storage               # kunci biometrik/PIN
flutter pub add supabase_flutter share_plus                     # akun, sinkronisasi, undangan pasangan
```

| Kebutuhan | Pilihan | Alasan |
|---|---|---|
| State management | Riverpod | Mudah dites, cocok untuk data turunan (prediksi) |
| Database lokal | Drift (SQLite) | Offline-first; data sensitif tetap di perangkat |
| Backend | Supabase (Postgres + Auth + Realtime) | Row Level Security cocok untuk izin pasangan |
| Notifikasi | flutter_local_notifications | Jadwal dihitung di perangkat → tidak perlu kirim data ke server |
| Keamanan | local_auth + sembunyikan preview di app switcher | Privasi pengguna |

## 4. Struktur folder

```
lib/
  domain/          cycle_engine.dart            (logika murni, sudah ada)
  data/            app_database.dart (Drift) · cycle_repository.dart · partner_repository.dart
  application/     providers.dart (Riverpod: logs → prediction → dayInfo)
  features/
    home/          kartu "hari ke-N", fase, hitung mundur haid & masa subur
    calendar/      table_calendar, warna per fase
    log/           catat haid, gejala, mood
    insights/      grafik panjang siklus, % tepat waktu/cepat/telat
    partner/       undang, terima, atur data yang dibagikan, cabut
    settings/      default panjang siklus/haid, kunci aplikasi, hapus data
  notifications/   scheduler (haid, subur, ovulasi, terlambat)
```

## 5. Fitur sambung ke pasangan

Alur:
1. **Pemilik data** (istri/pacar) buka *Bagikan ke pasangan* → `createInvite()` → kode 8 karakter (24 jam, sekali pakai) dibagikan lewat `share_plus`.
2. **Pasangan** memasukkan kode → `acceptInvite()`.
3. Pemilik memilih apa yang dibagikan (`ShareFlags`): fase hari ini, jendela subur/ovulasi, perkiraan haid.
4. Aplikasi pemilik memanggil `pushSnapshot()` setiap data berubah. Saat aplikasi pasangan terbuka, ia menerima lewat `watchPartnerSnapshot()` dan **menjadwalkan notifikasi lokal sendiri** dari tanggal di snapshot (mis. "Masa subur mulai besok", "Perkiraan haid 2 hari lagi"). Saat aplikasinya tertutup, jadwal lokal itu bisa basi, jadi perubahan data harus memicu **push notification** (lihat bagian 8).
5. Pemilik bisa **mencabut** akses kapan saja (`revoke()`); RLS langsung memblokir pembacaan.

Yang **tidak** dibagikan secara default: catatan gejala, mood, riwayat mentah.

### Skema Supabase + Row Level Security

```sql
create table partner_links (
  id uuid primary key default gen_random_uuid(),
  owner_id   uuid not null references auth.users(id) on delete cascade,
  partner_id uuid not null references auth.users(id) on delete cascade,
  status text not null default 'active' check (status in ('active','revoked')),
  created_at timestamptz default now(),
  unique (owner_id, partner_id)
);

create table invites (
  code text primary key,
  owner_id uuid not null references auth.users(id) on delete cascade,
  expires_at timestamptz not null
);

create table cycle_snapshots (
  owner_id uuid primary key references auth.users(id) on delete cascade,
  phase text, cycle_day int, lateness text,
  next_period date, fertile_start date, fertile_end date, ovulation date,
  updated_at timestamptz default now()
);

alter table partner_links   enable row level security;
alter table invites         enable row level security;
alter table cycle_snapshots enable row level security;

-- Pemilik mengelola datanya sendiri
create policy snap_owner  on cycle_snapshots for all
  using (owner_id = auth.uid()) with check (owner_id = auth.uid());
create policy links_owner on partner_links for all using (owner_id = auth.uid());
create policy invites_own on invites       for all using (owner_id = auth.uid());

-- Pasangan hanya boleh MEMBACA bila link aktif
create policy snap_partner on cycle_snapshots for select using (
  exists (select 1 from partner_links l
          where l.owner_id = cycle_snapshots.owner_id
            and l.partner_id = auth.uid() and l.status = 'active'));
create policy links_partner_read on partner_links for select using (partner_id = auth.uid());

-- Terima undangan: atomik, sekali pakai, cek kedaluwarsa
create or replace function accept_invite(p_code text) returns void
language plpgsql security definer set search_path = public as $$
declare v_owner uuid;
begin
  delete from invites where code = p_code and expires_at > now() returning owner_id into v_owner;
  if v_owner is null then raise exception 'invalid_or_expired'; end if;
  if v_owner = auth.uid() then raise exception 'self_link'; end if;
  insert into partner_links(owner_id, partner_id) values (v_owner, auth.uid())
  on conflict (owner_id, partner_id) do update set status = 'active';
end $$;
```

Catatan: batasi percobaan kode undangan (rate limit di Edge Function atau Supabase) agar tidak bisa ditebak.

## 6. Privasi & kepatuhan

- Data kesehatan reproduksi termasuk **data pribadi yang bersifat spesifik** menurut UU PDP (UU No. 27/2022): butuh persetujuan eksplisit, tujuan jelas, hak hapus data. Sediakan *Hapus akun & semua data* dan *Ekspor data*.
- Offline-first: semua catatan detail tetap di Drift (bisa dienkripsi dengan SQLCipher); server hanya menyimpan snapshot.
- Kunci aplikasi (biometrik/PIN), ikon & nama netral opsional, sembunyikan konten di task switcher.
- Jangan pakai SDK iklan/analytics yang membaca data haid.
- Fitur pasangan harus berbasis **persetujuan pemilik data** dan mudah dicabut. Jangan sampai bisa dipakai untuk memantau tanpa sepengetahuan pemilik.

## 7. Roadmap MVP

1. **Minggu 1–2:** `cycle_engine` + tes (sudah ada), Drift, layar catat haid, kalender berwarna.
2. **Minggu 3:** Home (hari ke-N, hitung mundur), notifikasi lokal, status terlambat.
3. **Minggu 4:** Insight (grafik, % tepat waktu/cepat/telat), kunci aplikasi.
4. **Minggu 5–6:** Auth Supabase, sinkronisasi cadangan, fitur pasangan + RLS.
5. **Fase 2:** tes LH/BBT, gejala & mood, ekspor PDF untuk dokter, mode hamil.

## 8. Dukungan Android + iOS (satu codebase Flutter)

Kode di `lib/domain` dan `lib/data` murni Dart + `supabase_flutter`, jadi jalan di Android dan iOS tanpa perubahan. Yang berbeda hanya konfigurasi platform:

| Hal | Android | iOS |
|---|---|---|
| Versi minimum | `minSdk` sesuai default Flutter | Deployment target **iOS 15.0** |
| Notifikasi | Android 13+: izin `POST_NOTIFICATIONS`; notifikasi tepat waktu butuh izin exact alarm | Izin diminta saat runtime; maksimal **64** notifikasi lokal terjadwal |
| Biometrik (`local_auth`) | `MainActivity` extends `FlutterFragmentActivity`, izin `USE_BIOMETRIC` | `NSFaceIDUsageDescription` di `Info.plist` |
| Push (pembaruan pasangan) | FCM | FCM → **APNs** (butuh APNs key dari akun Apple Developer) |
| Database, Supabase, share | tanpa konfigurasi khusus | tanpa konfigurasi khusus |

### Push saat data berubah
1. Tabel `device_tokens (user_id, token, platform)`; tiap perangkat mendaftarkan token FCM-nya.
2. Database webhook / Edge Function Supabase terpicu saat `cycle_snapshots` berubah → kirim push ke `partner_id` yang link-nya aktif.
3. Teks push **netral** ("Ada pembaruan"), jangan tulis fase/tanggal di layar kunci. Isi sebenarnya dibaca setelah aplikasi dibuka, lalu jadwal lokal dibuat ulang.

### Build & rilis
- Android bisa dibangun di Windows/Linux/Mac; untuk uji coba cukup install APK langsung.
- iOS **harus** dibangun dengan Xcode (macOS). Tanpa Mac, pakai CI berbasis macOS (mis. Codemagic atau GitHub Actions).
- Distribusi ke iPhone lewat TestFlight/App Store butuh Apple Developer Program (berbayar tahunan). Syarat SDK Apple berubah tiap tahun, cek halaman "upcoming requirements" Apple sebelum rilis.

## 9. Dynamic Island & bentuk layar iPhone

Ada dua hal berbeda yang sering disebut "support Dynamic Island":

**A. Tata letak aman (wajib, sudah ditangani).**
Dynamic Island hanyalah area layar yang tidak boleh ditimpa konten. Flutter memberi tahu ukurannya lewat `MediaQuery` / `SafeArea`, jadi cukup:
- Semua layar memakai `AppScaffold` (`lib/core/app_scaffold.dart`), bukan `Scaffold` langsung.
- Jangan hardcode tinggi status bar. Tinggi area atas berbeda antar iPhone (notch vs Dynamic Island, ukuran layar berbeda).
- Bottom sheet: `showModalBottomSheet(useSafeArea: true, ...)`. Form dengan keyboard: pakai `MediaQuery.viewInsetsOf(context)`.
- Mode landscape: `SafeArea` juga menjaga sisi kiri/kanan.
- Uji: `test/app_scaffold_test.dart` mensimulasikan inset atas/bawah iPhone. Sebelum rilis, tetap cek di simulator/perangkat iPhone ber-Dynamic Island (mis. 15 Pro / 16 Pro).

Model dengan Dynamic Island: iPhone 14 Pro/Pro Max, seluruh iPhone 15, 16, dan 17 (kecuali 16e). iPhone 14/14 Plus dan 16e masih pakai notch. Dengan `SafeArea`, keduanya tertangani tanpa kode khusus.

**B. Tampil di dalam Dynamic Island lewat Live Activities (opsional, fase 2).**
- Butuh kode native Swift (ActivityKit + WidgetKit sebagai Widget Extension), tidak cukup kode Dart. Di Flutter biasanya dijembatani plugin seperti `live_activities` (cek status pemeliharaannya sebelum dipakai).
- Live Activity dirancang untuk kejadian berdurasi pendek (Apple menyarankan tidak lebih dari 8 jam). Data siklus berlangsung berhari-hari, jadi kurang cocok.
- iPhone tanpa Dynamic Island hanya menampilkannya di Lock Screen.
- Isi Dynamic Island/Lock Screen bisa terlihat orang di sekitar. Untuk data sensitif seperti siklus haid, jika dibuat harus **opt-in** dan berteks netral.
- Alternatif yang lebih cocok: **widget Home Screen / Lock Screen** (paket `home_widget`) untuk menampilkan "hari ke-N" atau hitung mundur, juga opt-in dan netral.

## 10. Pindah iPhone (14 Pro Max → 18 Pro)

**Kompatibilitas layar.** Keduanya punya Dynamic Island, jadi `AppScaffold`/`SafeArea` tetap berlaku. Yang perlu diperhatikan:
- Ukuran Dynamic Island di 18 Pro lebih kecil dan laporan tentang lebar pastinya berbeda-beda. Jangan bergantung pada angka apa pun; baca selalu dari `MediaQuery`.
- Layar 18 Pro (6,3") lebih kecil dari 14 Pro Max (6,7"): lebar logis turun dari ±430 ke ±402. Gunakan layout responsif (`Expanded`, `Flexible`, `Wrap`), jangan lebar tetap. `test/app_scaffold_test.dart` menguji profil kedua perangkat.
- 18 Pro membawa iOS 27. Uji dan bangun dengan Xcode terbaru.

**Pindah data (risiko terbesar).** Riwayat haid di database lokal tidak otomatis ikut bila HP baru disetel sebagai "perangkat baru". Pastikan ada jalur pemulihan:
1. **Ekspor/Impor JSON** (`lib/domain/backup.dart`): tombol "Cadangkan" di Pengaturan, simpan ke Files/iCloud Drive/AirDrop; "Pulihkan" di HP baru.
2. (Fase 2) **Cadangan terenkripsi di akun** (tabel `cycle_backups`, RLS hanya pemilik), dienkripsi di perangkat sebelum diunggah.
3. Bila database dienkripsi (SQLCipher), kunci di Keychain belum tentu ikut ke HP baru. Jangan hanya mengandalkan itu; tetap sediakan ekspor.

**Akun & pasangan.** Tautan pasangan terikat ke **akun**, bukan perangkat, jadi tidak perlu mengundang ulang. Yang perlu diperbarui hanya token push: simpan dengan `upsert` setiap aplikasi dibuka, dan hapus token lama saat logout agar HP lama tidak masih menerima push.

**Opsional (Live Activities nanti).** 18 Pro bisa menampilkan sampai tiga Live Activities sekaligus, sedangkan model sebelumnya dua. Tidak memengaruhi MVP.
