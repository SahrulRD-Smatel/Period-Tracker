# LOGIC.md — Spesifikasi logika siklus (sumber kebenaran: `lib/domain/cycle_engine.dart`)

## 1. Konsep & istilah
- **Hari pertama haid (start)**: hari pertama perdarahan. Tanggal inilah jangkar semua perhitungan.
- **Siklus**: dari start sampai sehari sebelum start berikutnya. **Hari siklus ke-N** = `tanggal − start + 1`.
- **Fase luteal**: ovulasi → haid berikutnya (default 14 hari, `CycleSettings.lutealLength`).
- **Masa subur**: `ovulasi − 5` … `ovulasi + 1` (sperma bertahan ±5 hari, sel telur ±12–24 jam).
- Siklus normal dewasa 21–35 hari; **28 hanya default**, bukan aturan. Lama haid ±2–7 hari (default 5).

## 2. Rumus
```
lengths          = selisih hari antar start berurutan, hanya yang 15..60 hari
cycleLength      = median(6 lengths terakhir)           ; <3 data → dicampur default 28 (rata-rata dengan default)
nextPeriod       = lastStart + cycleLength
ovulation        = nextPeriod − lutealLength
fertileWindow    = [ovulation − 5, ovulation + 1]
margin           = <3 data: 3 hari | selainnya: min(7, max(2, ceil(stdDev)))
periodRange      = nextPeriod ± margin
confidence       = high (≥6 siklus & sd ≤ 2) | medium (≥3 & sd ≤ 4) | low
```
Jika ada `confirmedOvulation` (tes LH/BBT) pada siklus berjalan:
`ovulation = tanggal itu`, `nextPeriod = ovulation + lutealLength`, `margin = 2`, `ovulationConfirmed = true`.

Prediksi menghasilkan `windows`: siklus berjalan + siklus-siklus berikutnya (±3 bulan) untuk kalender.

## 3. Mengapa begitu (keputusan desain)
| Keputusan | Alasan |
|---|---|
| Jangkar ke start aktual | Haid telat 1 minggu → jadwal berikutnya otomatis bergeser. Tidak ada rumus "+7 hari" yang kaku. |
| Median, bukan rata-rata | Satu siklus 35 di antara 28-an tidak membuat prediksi melompat ke 30. |
| Abaikan selisih <15 / >60 hari | <15 = bercak/input ganda; >60 = ada haid yang tidak tercatat. |
| Ovulasi mundur dari haid berikutnya | Fase luteal relatif stabil; fase folikular yang bervariasi. Siklus 21 hari → ovulasi ±hari ke-8. |
| Margin dari simpangan baku | Menunjukkan ketidakpastian secara jujur; hasil berupa rentang, bukan tanggal pasti. |
| Fase `delayed` saat terlambat | Prediksi lama sudah tidak valid; jangan menampilkan ovulasi/haid masa depan yang menyesatkan. |
| Ambang 7 hari & 90 hari | 7 hari: anjuran tes kehamilan/cek penyebab. 90 hari: anjuran periksa dokter. |

## 4. Status keterlambatan (`assessLateness`, urutan evaluasi penting)
1. `seeDoctor`   : hari ini − lastStart ≥ 90
2. `veryLate`    : hari ini − nextPeriod ≥ 7
3. `late`        : hari ini > nextPeriod + margin
4. `withinMargin`: hari ini > nextPeriod
5. `none`        : selainnya

## 5. Fase per hari (`CycleWindow.phaseOf`, `CycleEngine.infoOn`)
Prioritas dalam satu siklus: `menstrual` → `ovulation` → `fertile` → `follicular` (sebelum masa subur) → `luteal`.
Pada siklus pendek masa subur bisa tumpang tindih dengan haid: fase = `menstrual`, tetapi `isFertile = true`.
Jika `hari ini > nextPeriod` (terlambat): tanggal ≥ nextPeriod s/d hari ini = `delayed`; setelah hari ini = `null`.

## 6. Klasifikasi siklus selesai (`classifyCycle`)
`actual − expected < −margin` → `early`; `> +margin` → `late`; selainnya `onTime` (margin default 2).

## 7. Contoh baku (juga ada di tes)
| Skenario | Hasil |
|---|---|
| 1 log: 1 Jan | cycleLength 28; haid 29 Jan; ovulasi 15 Jan; subur 10–16 Jan; confidence low |
| Start 1 Jan, 29 Jan, 26 Feb, 26 Mar | cycleLength 28; haid berikutnya 23 Apr |
| …lalu haid aktual 30 Apr (telat 1 minggu) | cycleLength tetap 28; haid berikutnya **28 Mei** (bukan 21 Mei) |
| LH positif 20 Jan, start 1 Jan | ovulasi 20 Jan; haid berikutnya 3 Feb |
| 1 log 1 Jan; hari ini 3 Feb | `late`, hari ke-34, fase `delayed`, masa subur disembunyikan |

## 8. Batasan & catatan medis
Metode kalender = **estimasi**, bukan kontrasepsi/diagnosis. Akurasi turun bila siklus tidak teratur.
Keterlambatan bisa karena stres, berat badan, PCOS, tiroid, KB hormonal, menyusui, atau kehamilan.

## 9. Bila mengubah logika
Ubah `cycle_engine.dart` → tambah/ubah tes di `test/cycle_engine_test.dart` → perbarui dokumen ini
→ cek dampak ke `home_summary.dart`, `day_view.dart`, `phase_style.dart`, dan `docs/ARSITEKTUR.md`.

## 10. Statistik (`domain/stats.dart`)
- Hanya siklus 15..60 hari yang dihitung (sama dengan engine). Urut terlama → terbaru.
- "Tepat waktu / lebih cepat / terlambat": `classifyCycle` terhadap **median seluruh siklus**, margin 2 hari; hanya bila ada ≥ 3 siklus (kurang dari itu `outcome = null`).
- Keteraturan (butuh ≥ 3 siklus): rentang (maks − min) ≤ 7 hari = teratur; ≤ 14 = cukup bervariasi; selebihnya tidak teratur.
- Lama haid rata-rata hanya dari log yang punya tanggal selesai (1..10 hari).
- Ringkasan catatan (`topSymptoms`, `topMoods`, `totalNotes`): mengagregasi gejala dan mood terbanyak dari `DayNote` walau siklus baru tercatat 1 kali.

## 10b. Sinkronisasi Log ↔ Siklus (`domain/cycle_sync.dart`)
- `latestConfirmedOvulation(logs, notes)` membaca `DayNote.ovulationPositive` terbaru pada siklus berjalan untuk disalurkan ke `CycleEngine.predict(confirmedOvulation: ...)`.
- `shouldAutoStartPeriod`, `logContainingDate`, dan `activeOpenPeriod` menjaga agar pencatatan aliran haid di `LogScreen` serta tanda selesai haid di `CalendarScreen`/`HomeScreen` konsisten tanpa menciptakan siklus ganda <15 hari.

## 11. Setelan → engine
`AppSettings.toCycleSettings()` menyuplai default (panjang siklus 28, lama haid 5, luteal 14) ke `CycleEngine`.
Default hanya berpengaruh saat data < 3 siklus; setelahnya riwayat pengguna yang menentukan. Rentang valid:
siklus 21–45, haid 2–10, luteal 10–16 (nilai lain dijepit saat dibaca).

## 12. Berbagi ke pasangan (`domain/partner_models.dart`)
`buildSnapshot(HomeSummary, ShareFlags, now)` menyaring data: flag `phase` → fase + hari ke-N; `fertileWindow` → awal/akhir masa subur + ovulasi;
`nextPeriod` → tanggal perkiraan haid + status keterlambatan. Flag mati ⇒ field `null`. Saat haid terlambat, masa subur memang `null`
(lihat aturan fase `delayed`). Satu perangkat = satu peran (pemilik atau pelihat) pada MVP.

## 13. Cadangan
v1: `{version:1, periods}`. v2: `{version:2, periods, notes, settings}`.
v3: `{version:3, periods, notes, settings, loveNotes, careCheckedIds}`. Impor v1/v2 tetap kompatibel.
Setelah pemulihan `onboardingDone = true`.
