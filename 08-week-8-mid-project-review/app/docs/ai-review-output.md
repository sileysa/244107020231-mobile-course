# Output Awal Review AI

Output berikut adalah hasil review awal pada `posts_providers.dart`. Temuan harus
diverifikasi sebelum diterapkan.

1. **Blocker — lifecycle async:** `_refreshFromApi` dapat melanjutkan setelah provider
   disposed; akses `ref` atau perubahan state sesudah `await` tidak aman. Periksa
   `ref.mounted` sesudah operasi async, sebelum memakai provider atau menulis state.
2. **Saran — refresh manual menghilangkan data lama:** `refresh()` langsung mengubah state
   menjadi `AsyncLoading`, sehingga daftar cache diganti indikator loading sampai request
   selesai. Pertimbangkan mempertahankan data sebelumnya selama refresh.
3. **Saran — test orchestration belum ada:** test sebelumnya menguji model posts, tetapi
   belum menguji perilaku notifier saat request tertunda dan provider dibuang. Tambahkan
   test dengan repository palsu dan `Completer`.
4. **Saran — sederhanakan alur fallback:** cabang fetch remote, fallback cache, dan simpan
   hasil berada dalam satu method panjang. Jika aturan bertambah, ekstrak operasi fallback
   menjadi helper yang bernama sesuai perilakunya.
5. **Saran — evaluasi wiring data pada provider presentation:** provider posts mengikat
   repository interface ke implementasi data dan fungsi pembuka database. Pastikan ini
   memang menjadi composition root yang disepakati; bila tidak, pindahkan wiring ke
   composition root aplikasi.

## Bukti awal

- Poin 1 tampak pada operasi `await` diikuti pemakaian `ref`/state tanpa pemeriksaan
  lifecycle; regresi diuji oleh `app/test/posts_providers_test.dart`.
- Poin 2 tampak dari `state = const AsyncLoading()` di method `refresh`.
- Sebelum perubahan Week 8, tidak ada test untuk provider posts; kini ada dua test lifecycle.
- Poin 5 dibandingkan dengan dokumentasi keputusan Week 7, yang menetapkan provider Riverpod
  sebagai composition root per fitur.

Output ini adalah catatan reviewer AI untuk tugas ini. Keputusan akhir ada pada tabel
[`ai-review-vs-keputusan-final.md`](ai-review-vs-keputusan-final.md).
