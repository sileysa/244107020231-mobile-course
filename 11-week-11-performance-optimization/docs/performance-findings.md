# Temuan Profiling Performa

Temuan dan angka pengukuran selengkapnya ada di
[`performance-report.md`](performance-report.md). Ringkasannya:

- Lingkungan validasi saat ini mendeteksi OPPO CPH2387, Android 14 (API 34),
  arm64; Flutter 3.47.5 stable, Dart 3.13.4, dan DevTools 2.60.0. Versi ini
  belum tentu sama dengan sesi pengukuran terdahulu.
- Pada data biasa, catatan awal menyebut aplikasi berjalan sekitar 58–59 FPS.
- Dengan 500 catatan uji, jank terasa ketika mengetik di pencarian. Rekaman
  yang tersedia menunjukkan fase UI dan raster berbeda-beda; hasil emulator
  x64 dengan raster sekitar 17 ms dikecualikan dari baseline perangkat.
- `NotesPage` versi awal memanggil `setState` pada setiap perubahan pencarian,
  sehingga seluruh halaman ikut dibangun ulang.
- Catatan sudah memakai `ListView.builder`; item dibangun secara lazy, jadi
  daftar panjang bukan berarti semua tile dibangun sekaligus.
- Biaya `Chip` per item dan penyebab lonjakan fase Build belum dibuktikan
  sebagai bottleneck terukur.
- Perbandingan before/after belum memakai skenario yang sama secara konsisten;
  angka yang tercatat bersifat indikatif dan belum membuktikan dampak setiap
  optimasi. Dua tangkapan kode akhir menunjukkan 26 jank / 56 FPS dan 12 jank /
  57 FPS; buktinya ada di `../screenshots/after-profile.png` dan
  `../screenshots/after-profile-run-2.png`.

Screenshot grafik Memory tersedia di `../screenshots/memory-profile.png`, tetapi
belum memperlihatkan diff dua heap snapshot atau angka sebelum/sesudah. Belum
ada dasar untuk menyimpulkan ada/tidaknya memory leak. Pengulangan A/B
terkontrol juga belum tersedia; jangan menginterpretasikan angka before/after
sebagai uji A/B sampai pengukuran diulang pada perangkat dan skenario yang sama.
