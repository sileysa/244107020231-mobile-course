# Laporan Optimasi Performa – Minggu 11

**Nama:** Sileysa Faedatul Nuraini  
**NIM:** 244107020231  
**Mata kuliah:** Pemrograman Mobile – Politeknik Negeri Malang  
**Project:** Salinan project Minggu 10 dengan fitur Notes dan Posts (Riverpod, go_router, sqflite)


---

## 1. Ringkasan

Aplikasi diprofil di HP Android asli dalam mode `--profile` memakai Flutter DevTools. Dengan data biasa, aplikasi sudah lancar (sekitar 58–59 FPS). Dengan 500 catatan uji, jank paling terasa saat **mengetik di kolom pencarian Notes**.

Tiga optimasi dicoba: (1) pencarian tanpa `setState` di setiap ketikan, (2) penanda "belum tersinkron" memakai `Icon` ringan pengganti `Chip`, (3) debounce pencarian 250 ms. Dua tangkapan rekaman kode akhir menunjukkan masing-masing 26 jank / 56 FPS dan 12 jank / 57 FPS. Perbandingan dengan baseline 53 jank / 51 FPS masih indikatif karena rekaman baseline tidak memakai skrip konsisten yang terdokumentasi dan hasil akhir bervariasi. Dampak tiap optimasi secara terpisah **belum bisa dibuktikan**. Penyebab pasti lonjakan fase *Build* juga belum berhasil diidentifikasi sampai ke widget tertentu.

## 2. Lingkungan dan Metode

| Item | Nilai |
|---|---|
| Perangkat | OPPO CPH2387, Android 14 (API 34), arm64 |
| Mode | `flutter run --profile` (dijalankan ulang pada sesi verifikasi ini) |
| Alat | Flutter DevTools (Performance, Frame Analysis, Enhance Tracing) |
| Renderer | Impeller |
| Flutter/Dart | Flutter 3.47.5 stable, Dart 3.13.4, DevTools 2.60.0 (sesi verifikasi ini; versi saat pengukuran awal tidak dicatat) |
| Data uji | 500 catatan dummy, dimasukkan saat sesi pengukuran. Tombol seed sementara sudah dihapus dari aplikasi. |

**Catatan emulator.** Rekaman pertama dibuat di emulator x64 dan hasilnya buruk (10–12 FPS, 111 jank) dengan waktu raster tinggi (sekitar 17 ms) sementara fase Build hanya 0,1 ms. Ini menunjukkan raster menjadi bottleneck pada sesi tersebut; penyebab perangkat/akselerasi tidak dikonfirmasi. Rekaman itu **tidak dipakai** sebagai baseline. Semua angka di bawah berasal dari HP asli.

**Verifikasi sesi profile terbaru.** Aplikasi berhasil dibangun dan dipasang
serta terhubung ke DevTools di CPH2387. Flutter melaporkan skipped frames saat
startup; karena tidak ada skrip interaksi pencarian yang direkam, frame startup
ini tidak dimasukkan ke metrik after. Sesi ini mengonfirmasi profile build dan
koneksi DevTools, bukan hasil profiling skenario.

**Skrip uji tetap (skenario B).** Kosongkan data uji → di kolom pencarian Notes ketik `catatan`, tekan tombol X, ketik `uji 1`, tekan X → ulangi total 3 putaran → *pause* → catat jumlah jank (badge), FPS rata-rata, dan frame UI terberat. Skrip ini baru dipakai konsisten pada rekaman sesudah optimasi 1.

## 3. Baseline (sebelum optimasi)

| Rekaman | Jank | FPS rata-rata | Catatan |
|---|---|---|---|
| Observasi awal, data biasa | 22 | 58 | Jank sedikit, aplikasi sudah lancar |
| Observasi awal, rekaman panjang | 442 (kumulatif) | 57 | Frame 3593: Build 13,5 ms, Layout 10,6 ms, Paint 3,2 ms (UI jank) |
| Skenario B, kode asli, 500 catatan | 53 | 51 | Contoh frame: UI 18,4 ms, raster 7,7 ms |

`screenshots/before-profile.png` merekam sesi emulator x64 yang tidak digunakan
sebagai baseline. `screenshots/bp.png` adalah tangkapan Performance DevTools di
perangkat arm64; grafik yang terlihat menunjukkan rata-rata 59 FPS pada cuplikan
itu. Karena skenario dan hubungannya dengan tabel rekaman tidak tercatat,
screenshot tersebut menjadi bukti tambahan, bukan pengganti metrik tabel.

Angka kumulatif (442) menghitung seluruh sesi termasuk startup, jadi tidak dibandingkan langsung dengan rekaman pendek.

## 4. Masalah yang Diidentifikasi

1. **`setState` di setiap ketikan pencarian** (`notes_page.dart`). Seluruh `NotesPage` dibangun ulang tiap huruf, padahal hanya daftar yang perlu berubah. Rekaman menunjukkan jank UI ketika mengetik, tetapi tidak mengisolasi penyebabnya pada widget tertentu.
2. **Penanda `Chip` di tile catatan belum tersinkron.** Biaya per tile mungkin lebih tinggi daripada ikon, tetapi `ListView.builder` hanya membangun item di sekitar viewport; semua 500 tile tidak dibangun sekaligus. Perubahan ini merupakan eksperimen, bukan bottleneck yang sudah dibuktikan.
3. **Filter berjalan pada setiap perubahan query.** Debounce membatasi frekuensi filter dan pembaruan daftar saat pengguna mengetik cepat.
4. **Lonjakan fase Build** (sekitar 14–35 ms, berkala) yang penyebab widget-nya belum teridentifikasi. Enhance Tracing memperlihatkan Build sebagai fase terpanjang (frame 343: Build 34,8 ms termasuk overhead tracing, raster 8,5 ms), tetapi Timeline Events tidak berhasil menunjuk widget penyebab.

`search_notes.dart` (filter `toLowerCase().contains`) diperiksa dan **tidak dioptimasi** karena biayanya kecil untuk 500 item. Mengoptimasi bagian yang bukan sumber masalah termasuk optimasi prematur.

## 5. Optimasi yang Diterapkan

### Optimasi 1 – Pencarian tanpa `setState`
- **File:** `lib/features/notes/presentation/pages/notes_page.dart`
- **Perubahan:** field query yang diperbarui dengan `setState` dihapus. Daftar mendengarkan `_query` melalui `ValueListenableBuilder<String>`; kolom pencarian mendengarkan controller sendiri untuk tombol clear.
- **Alasan:** mengetik hanya membangun ulang daftar, bukan AppBar, kartu sinkronisasi, dan kolom pencarian.

### Optimasi 2 – Penanda sinkron yang ringan
- **File:** `lib/features/notes/presentation/widgets/note_tile.dart`
- **Perubahan:** `Chip` diganti `Semantics(label: 'Belum tersinkron', child: Icon(Icons.sync_problem))`.
- **Alasan:** `Chip` membangun banyak widget internal; ikon jauh lebih ringan.
- **Trade-off:** label teks "Belum tersinkron" berubah menjadi ikon (label tetap tersedia untuk pembaca layar).

### Optimasi 3 – Debounce pencarian 250 ms
- **File:** `lib/features/notes/presentation/pages/notes_page.dart`
- **Perubahan:** daftar mendengarkan `ValueNotifier<String>` yang diperbarui lewat `Timer` 250 ms; saat kolom dikosongkan (tombol X) daftar langsung penuh.
- **Alasan:** mengurangi jumlah build daftar saat mengetik cepat.
- **Trade-off:** hasil pencarian muncul sekitar seperempat detik setelah berhenti mengetik.

## 6. Hasil Verifikasi (sesudah optimasi)

| Kondisi kode | Jank | FPS rata-rata |
|---|---|---|
| Optimasi 1 (rekaman pendek) | 24 | 55 |
| Optimasi 1 (skrip tetap) | 28 | 54 |
| Optimasi 1 + 2 (rekaman 1) | 18 | 54 |
| Optimasi 1 + 2 (rekaman 2) | 26 | 56 |
| Optimasi 1 + 2 + 3 (1 rekaman) | 16 | 51 |
| Kode akhir, rekaman tambahan (screenshot terlampir) | 26 | 56 |
| Kode akhir, tangkapan terbaru (screenshot terlampir) | 12 | 57 |

Frame jank sesudah optimasi 1 (frame 243): Build 14,5 ms, Layout 12,7 ms, Paint 4,1 ms, raster 9,5 ms. Dibanding frame jank sebelum optimasi (Build 13,5 ms, Layout 10,6 ms), **biaya satu frame jank tidak berubah**; yang tampak berkurang hanyalah jumlahnya.

Screenshot DevTools untuk rekaman tambahan tersedia di
`screenshots/after-profile.png` (26 jank, 56 FPS). Tangkapan terbaru yang
dikirim dan disimpan di `screenshots/after-profile-run-2.png` menunjukkan
12 jank dan rata-rata 57 FPS. Kedua screenshot tidak menampilkan frame
terpilih atau breakdown UI/raster per frame, sehingga tidak dipakai untuk
mengklaim penyebab jank.

**Pembanding terkontrol (versi asli dengan skrip tetap, 2 kali):** belum dilakukan. Karena itu perbandingan sebelum dan sesudah pada tabel di atas bersifat indikatif, bukan hasil uji A/B yang ketat.

**Pembacaan hasil.** Rekaman awal 53 jank / 51 FPS; dua tangkapan kode akhir menunjukkan 26 / 56 dan 12 / 57. Ini indikasi hasil sesi, bukan bukti sebab-akibat: baseline dan rekaman akhir tidak terulang cukup kali dengan pengaturan serta skrip yang sama. Perbedaan hasil akhir juga menunjukkan variasi yang perlu dikendalikan. Optimasi 2 (Chip → Icon) tidak memberi perbedaan terukur.

## 7. Memory Profiling

Screenshot Memory DevTools tersimpan di `screenshots/memory-profile.png`.
Grafiknya memperlihatkan sampel memori, tetapi tidak menampilkan hasil
perbandingan dua heap snapshot atau angka sebelum/sesudah yang dapat dibaca.
Karena itu belum dapat disimpulkan apakah ada objek yang menumpuk atau terjadi
memory leak. Untuk melengkapi verifikasi, gunakan **Diff Snapshots** untuk
membandingkan snapshot halaman daftar dengan snapshot setelah membuka/menutup
halaman detail lima kali; periksa jumlah instance `NotesPage`, controller, dan
listener setelah GC. Controller pencarian sendiri di-`dispose` bersama timer
dan notifier, tetapi pemeriksaan kode bukan pengganti perbandingan runtime.

## 8. Refleksi

- **Optimasi mana yang paling berdampak?** Optimasi 1 (pencarian tanpa `setState`) paling masuk akal dan didukung data awal (jank UI saat mengetik). Optimasi 2 tidak berdampak terukur; optimasi 3 hanya memberi indikasi kecil.
- **Bagaimana membuktikan bukan efek plasebo?** Dengan profiling sebelum dan sesudah memakai skenario yang persis sama, beberapa kali ulang. Pada pekerjaan ini, variasi antar-rekaman (sekitar ±5 jank) membuktikan bahwa satu rekaman saja tidak cukup untuk menyimpulkan.
- **Trade-off:** debounce menunda hasil pencarian sekitar 250 ms; mengganti `Chip` dengan ikon mengubah tampilan; menambah `ValueListenableBuilder` membuat alur kode sedikit lebih kompleks.
- **Kapan optimasi prematur dihindari?** Fungsi pencarian `SearchNotes` sengaja tidak dioptimasi karena bukan sumber masalah. Pada data biasa aplikasi sudah sekitar 58 FPS, sehingga sebagian optimasi hanya terukur pada data uji yang berat.
- **Pelajaran pengukuran:** emulator tanpa GPU memberi angka raster yang menyesatkan; "Count widget builds" tidak bisa dipakai di mode profile; dan Timeline Events bisa kosong jika frame sudah terlalu lama.

## 9. Keterbatasan

- Penyebab pasti lonjakan fase Build belum ditemukan sampai ke widget tertentu.
- Hitungan rebuild per widget tidak tersedia di mode profile; pengukuran bertumpu pada jumlah jank dan waktu frame.
- Jumlah rekaman per kondisi sedikit (1–2), tidak ada analisis statistik.
- Perbandingan heap snapshot dan uji A/B terkontrol terhadap versi asli belum
  dilakukan.
- Screenshot grafik Memory sudah tersedia, tetapi belum ada bukti perbandingan
  snapshot sebelum/sesudah lima siklus navigasi.
- Data uji (500 catatan dummy) membuat semua catatan berstatus belum tersinkron, sehingga beban tile mungkin lebih berat daripada pemakaian nyata.

## 10. Penggunaan AI

Analisis dan penyusunan kode optimasi dibantu asisten AI. Seluruh pengukuran dilakukan sendiri di perangkat, dan hasilnya dilaporkan apa adanya, termasuk optimasi yang tidak menunjukkan dampak.

## Lampiran

- `screenshots/before-profile.png`: rekaman emulator x64 yang dikecualikan.
- `screenshots/bp.png`: rekaman DevTools perangkat arm64 tanpa label skenario.
- `screenshots/after-profile.png`: rekaman kode akhir, 26 jank dan 56 FPS.
- `screenshots/after-profile-run-2.png`: tangkapan terbaru, 12 jank dan 57 FPS.
- `screenshots/memory-profile.png`: grafik Memory DevTools; tidak memuat
  perbandingan heap snapshot sebelum/sesudah.
- `screenshots/observation-real-data.png`: tampilan aplikasi pada data nyata.
- Skenario A/B terkontrol dan tangkapan Memory belum tersedia. Tangkapan
  akhir yang ada belum cukup untuk perbandingan statistik.
- Profile build terbaru berhasil dijalankan; startup dengan skipped frames
  tidak dimasukkan ke metrik skenario pencarian.
- Perangkat dan versi Flutter/Dart di atas diverifikasi pada lingkungan
  validasi saat ini, bukan metadata yang tersimpan dari rekaman profiling lama.
- `flutter analyze`: No issues found.
- `flutter test`: 55 tes lulus.